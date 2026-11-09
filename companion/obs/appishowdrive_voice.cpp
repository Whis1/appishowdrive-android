// SPDX-License-Identifier: GPL-2.0-or-later
#include <obs-module.h>
#include <memory>
#include <mutex>
#include "voice_processor.hpp"

OBS_DECLARE_MODULE()
MODULE_EXPORT const char *obs_module_name() { return "APPISHOWDRIVE Voice"; }
MODULE_EXPORT const char *obs_module_description() { return "Riduzione adattiva del rumore sulla sola sorgente microfono scelta."; }
MODULE_EXPORT const char *obs_module_author() { return "APPISHOWDRIVE community"; }

struct Filter {
    std::mutex mutex;
    std::unique_ptr<VoiceProcessor> processor;
    unsigned rate=0, channels=0;
    float sensitivity=.55f, gain=3.f;
};
static const char *name(void *) { return "APPISHOWDRIVE · Voce e ambiente"; }
static void defaults(obs_data_t *settings) {
    obs_data_set_default_double(settings,"sensitivity",.55);
    obs_data_set_default_double(settings,"voice_gain",3.0);
}
static void update(void *data, obs_data_t *settings) {
    auto *f=static_cast<Filter *>(data); std::lock_guard<std::mutex> lock(f->mutex);
    f->sensitivity=std::clamp(static_cast<float>(obs_data_get_double(settings,"sensitivity")),.1f,.95f);
    f->gain=std::clamp(static_cast<float>(obs_data_get_double(settings,"voice_gain")),0.f,9.f);
}
static void *create(obs_data_t *settings, obs_source_t *) {
    auto *f=new Filter; update(f,settings); return f;
}
static void destroy(void *data) { delete static_cast<Filter *>(data); }
static obs_properties_t *properties(void *) {
    auto *p=obs_properties_create();
    obs_properties_add_text(p,"info","Applicare SOLO alla sorgente microfono del telefono. YouTube, Sound Alerts e TTS devono restare su sorgenti separate. Il filtro rileva la voce, non riconosce l’identità del parlante.",OBS_TEXT_INFO);
    obs_properties_add_float_slider(p,"sensitivity","Soglia di riconoscimento voce",.1,.95,.05);
    obs_properties_add_float_slider(p,"voice_gain","Rinforzo della voce (dB)",0,9,.5);
    return p;
}
static obs_audio_data *audio(void *data, obs_audio_data *audio) {
    auto *f=static_cast<Filter *>(data); std::lock_guard<std::mutex> lock(f->mutex);
    const auto *output=obs_get_audio();
    if (!output) return audio;
    const unsigned rate=audio_output_get_sample_rate(output), channels=static_cast<unsigned>(audio_output_get_channels(output));
    if(channels < 1 || channels > 2 || !rate || rate%100) return audio;
    if (!f->processor || rate!=f->rate || channels!=f->channels) {
        try { f->processor=std::make_unique<VoiceProcessor>(rate,channels); f->rate=rate; f->channels=channels; }
        catch(...) { f->processor.reset(); return audio; }
    }
    float *planes[2]{};
    for(unsigned c=0;c<channels;c++) { planes[c]=reinterpret_cast<float *>(audio->data[c]); if(!planes[c]) return audio; }
    f->processor->sensitivity=f->sensitivity; f->processor->gainDb=f->gain;
    f->processor->process(planes,audio->frames);
    const uint64_t latency=1000000000ULL*f->processor->latencyFrames()/rate;
    if(audio->timestamp >= latency) audio->timestamp-=latency;
    return audio;
}
bool obs_module_load() {
    obs_source_info info{};
    info.id="appishowdrive_voice_v1"; info.type=OBS_SOURCE_TYPE_FILTER;
    info.output_flags=OBS_SOURCE_AUDIO; info.get_name=name; info.create=create;
    info.destroy=destroy; info.get_defaults=defaults; info.update=update;
    info.get_properties=properties; info.filter_audio=audio;
    obs_register_source(&info);
    return true;
}
