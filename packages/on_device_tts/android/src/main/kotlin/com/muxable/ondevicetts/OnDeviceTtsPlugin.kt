package com.muxable.ondevicetts

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Registers Android's installed system TTS engine only. */
class OnDeviceTtsPlugin : FlutterPlugin {
    private val systemTts = SystemTtsPlugin()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        systemTts.onAttachedToEngine(binding)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        systemTts.onDetachedFromEngine(binding)
    }
}
