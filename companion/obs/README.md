# APPISHOWDRIVE Voice for OBS

The standalone Windows OBS companion is GPL-2.0-or-later. The Android APK is a separate Apache-2.0 program; it does not load this DLL. RNNoise is BSD-3-Clause.

Use the filter on the dedicated microphone source only. It uses RNNoise voice activity, a 350ms hold and gradual dry/wet transitions. During detected speech the denoised signal receives 3dB gain with bounded headroom. After speech the original ambience returns. It adds a fixed 20ms compensated delay and does not request audio focus, control playback or process unrelated sources. It does not identify the speaker. Music and TTS physically leaking into the microphone cannot be reliably distinguished from other speech; isolate the mic feed and use headphones.

To reproduce the build, check out OBS headers at tag `30.2.3` (commit `144599f`, GPL-2.0-or-later) and RNNoise at commit `cdf196b1e9de2f8ff1003328ebf9a4316477429d` (tag v0.1, BSD-3-Clause). Run `build.ps1 -ObsSdk PATH -Rnnoise PATH -Clang PATH_TO_CLANG_CL` with Visual Studio C++ tools, Windows SDK and an installed OBS Windows 64-bit build. C99 RNNoise requires Clang because it uses variable-length stack arrays. No AVX or GPU is required.

`verify.cpp` loads the real module into libobs and creates/releases the filter. It then processes the supplied QA voice mixed with deterministic noise, in mono/stereo at 44.1/48kHz with irregular callback sizes. It checks voice detection, finite bounded samples, exact ambience restoration after the fixed latency and processing time. Native OBS 33.0.0 load and the four audio configurations passed. The streamer's private phone-to-OBS connection was not available for testing.

The generated installer validates the DLL SHA256 and copies only its own module and license files to ProgramData. It refuses to install while OBS is running and never modifies scene collections, credentials or existing filters. No installer was run on the user's real OBS setup during development.
