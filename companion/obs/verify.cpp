// SPDX-License-Identifier: GPL-2.0-or-later
#include <obs-module.h>
#include <fstream>
#include <iostream>
#include <random>
#include <chrono>
#include "voice_processor.hpp"

int main(int argc,char **argv) {
    if(argc!=4) return 2;
    if(!obs_startup("it-IT",argv[3],nullptr)) return 3;
    obs_audio_info audioInfo{}; audioInfo.samples_per_sec=48000; audioInfo.speakers=SPEAKERS_STEREO;
    if(!obs_reset_audio(&audioInfo)) return 4;
    obs_module_t *module=nullptr;
    const auto opened=obs_open_module(&module,argv[1],argv[3]);
    if(opened!=0 || !obs_init_module(module)) return 5;
    auto *filter=obs_source_create("appishowdrive_voice_v1","QA filtro voce",nullptr,nullptr);
    if(!filter) return 6;
    auto *properties=obs_source_properties(filter);
    if(!properties) return 6;
    obs_properties_destroy(properties);
    obs_source_release(filter);
    obs_shutdown();

    std::ifstream in(argv[2],std::ios::binary|std::ios::ate);
    if(!in) return 7;
    std::vector<float> voice(static_cast<size_t>(in.tellg())/sizeof(float));
    in.seekg(0); in.read(reinterpret_cast<char *>(voice.data()),voice.size()*sizeof(float));
    std::mt19937 random(42); std::normal_distribution<float> noise(0,.018f);
    for(unsigned rate : {44100u,48000u}) for(unsigned channels : {1u,2u}) {
        const size_t lead=rate*2,total=lead+voice.size()*rate/48000+rate*6;
        std::array<std::vector<float>,2> input,original;
        for(unsigned c=0;c<channels;c++) {
            input[c].resize(total);
            for(size_t i=0;i<total;i++) {
                const size_t at=i>=lead ? (i-lead)*48000/rate : voice.size();
                input[c][i]=noise(random)+(at<voice.size() ? voice[at]*.7f : 0);
            }
            original[c]=input[c];
        }
        VoiceProcessor processor(rate,channels);
        float peak=0,maxProbability=0,wetAtEnd=1;
        double speechWet=0; size_t speechFrames=0;
        const auto start=std::chrono::steady_clock::now();
        for(size_t at=0;at<total;) {
            const size_t count=std::min<size_t>(1+(at%1024),total-at);
            float *planes[2]={input[0].data()+at,channels==2 ? input[1].data()+at : nullptr};
            processor.process(planes,count);
            maxProbability=std::max(maxProbability,processor.probability);
            if(at>=lead && at<lead+voice.size()*rate/48000) { speechWet+=processor.wetMix(); speechFrames++; }
            at+=count;
        }
        double error=0;
        for(size_t i=total-rate;i<total;i++) for(unsigned c=0;c<channels;c++) {
            error=std::max(error,static_cast<double>(std::abs(input[c][i]-original[c][i-processor.latencyFrames()])));
        }
        for(unsigned c=0;c<channels;c++) for(float sample:input[c]) {
            if(!std::isfinite(sample)) return 8;
            peak=std::max(peak,std::abs(sample));
        }
        const double seconds=std::chrono::duration<double>(std::chrono::steady_clock::now()-start).count();
        const double ratio=seconds/(static_cast<double>(total)/rate);
        wetAtEnd=processor.wetMix();
        std::cout << "VOICE_QA {\"rate\":" << rate << ",\"channels\":" << channels << ",\"voiceProbabilityMax\":" << maxProbability << ",\"speechWetMean\":" << speechWet/speechFrames << ",\"wetAtEnd\":" << wetAtEnd << ",\"ambientErrorAfterLatency\":" << error << ",\"peak\":" << peak << ",\"cpuRealTimeRatio\":" << ratio << "}\n";
        if(maxProbability < .6 || speechWet/speechFrames < .4 || wetAtEnd!=0 || error>.000001 || peak>1 || ratio>.3) return 9;
    }
    std::cout << "OBS_MODULE_AND_VOICE_QA_PASSED\n";
    return 0;
}
