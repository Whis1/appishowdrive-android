// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once
#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <vector>
#include <mutex>
extern "C" {
#include "rnnoise.h"
}

// RNNoise voice activity controls the wet mix. At rest the original ambience
// returns. Only the explicitly selected mic source is processed by OBS.
class VoiceProcessor {
    std::array<DenoiseState *, 2> states{};
    std::array<std::vector<float>, 2> input, previous, output;
    size_t cursor = 0, block;
    unsigned channels;
    float wet = 0;
    int hold = 0;
public:
    float sensitivity = .55f, gainDb = 3.f;
    float probability = 0;
    VoiceProcessor(unsigned sampleRate, unsigned channelCount)
      : block(sampleRate / 100), channels(channelCount) {
        if (!block || channelCount < 1 || channelCount > 2 || sampleRate % 100) throw "Unsupported audio format";
        for (unsigned c=0;c<channels;c++) {
            states[c] = rnnoise_create();
            if (!states[c]) {
                for (auto state:states) if(state) rnnoise_destroy(state);
                states.fill(nullptr);
                throw "Could not create noise reducer";
            }
            input[c].assign(block, 0); previous[c].assign(block, 0); output[c].assign(block, 0);
        }
        static std::mutex initialize;
        std::lock_guard<std::mutex> lock(initialize);
        std::array<float,480> silence{}, discarded{};
        for(unsigned c=0;c<channels;c++) rnnoise_process_frame(states[c],discarded.data(),silence.data());
    }
    ~VoiceProcessor() { for (auto state : states) if (state) rnnoise_destroy(state); }
    VoiceProcessor(const VoiceProcessor&) = delete;
    VoiceProcessor& operator=(const VoiceProcessor&) = delete;
    void process(float *const *data, size_t samples) {
        for(size_t i=0;i<samples;i++) {
            for(unsigned c=0;c<channels;c++) {
                input[c][cursor] = std::isfinite(data[c][i]) ? data[c][i] : 0;
                data[c][i] = output[c][cursor];
            }
            if (++cursor == block) { frame(); cursor = 0; }
        }
    }
    float wetMix() const { return wet; }
    unsigned latencyFrames() const { return static_cast<unsigned>(block * 2); }
private:
    static float interpolate(const float *values, size_t count, float x) {
        const size_t at=std::min(static_cast<size_t>(x),count-1), next=std::min(at+1,count-1);
        const float fraction=x-static_cast<float>(at);
        return values[at]*(1-fraction)+values[next]*fraction;
    }
    void frame() {
        std::array<std::array<float,480>,2> filtered{};
        probability = 0;
        for(unsigned c=0;c<channels;c++) {
            std::array<float,480> resampled{};
            for(size_t i=0;i<480;i++) resampled[i]=interpolate(input[c].data(),block,static_cast<float>(i)*(block-1)/479.f)*32768.f;
            probability=std::max(probability,rnnoise_process_frame(states[c],filtered[c].data(),resampled.data()));
        }
        if (probability >= sensitivity) hold = 35;
        else if (hold > 0) hold--;
        const float target=hold > 0 ? 1.f : 0.f;
        const float step=target > wet ? .25f : .05f;
        const float nextWet=wet+std::clamp(target-wet,-step,step);
        const float gain=std::pow(10.f,gainDb/20.f);
        for(unsigned c=0;c<channels;c++) for(size_t i=0;i<block;i++) {
            const float mix=wet+(nextWet-wet)*static_cast<float>(i)/static_cast<float>(block);
            float clean=interpolate(filtered[c].data(),480,static_cast<float>(i)*479.f/(block-1))/32768.f*gain;
            // Smooth, bounded headroom instead of hard clipping boosted speech.
            const float a=std::abs(clean);
            if(a > .92f) clean=std::copysign(.92f+.08f*std::tanh((a-.92f)/.08f),clean);
            output[c][i]=previous[c][i]*(1-mix)+clean*mix;
        }
        for(unsigned c=0;c<channels;c++) previous[c]=input[c];
        wet=nextWet;
    }
};
