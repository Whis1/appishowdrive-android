# MediaPipe TTS 1.2.2 constructs these Kotlin value objects from JNI. R8 cannot
# see those constructor calls. Preserve the small TTS API package and its JNI
# entry points in the actual release APK, including AudioResult/VoiceInfo.
-keep class com.google.mediapipe.tasks.audio.texttospeech.** { *; }
