package com.muxable.ondevicetts

import android.app.ActivityManager
import android.content.ComponentCallbacks2
import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Registers the `on_device_tts/onnx` channels and `on_device_tts/memory`;
 * see `doc/native_contract.md` in the package for the contract.
 */
class OnDeviceTtsPlugin : FlutterPlugin {
    companion object {
        const val MEMORY_CHANNEL = "on_device_tts/memory"
    }

    private val systemTts = SystemTtsPlugin()

    private var methods: MethodChannel? = null
    private var events: EventChannel? = null
    private var memoryEvents: EventChannel? = null
    private var engine: OnnxTtsChannelHandler? = null
    private var context: Context? = null
    private var memory: MemoryEvents? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        systemTts.onAttachedToEngine(binding)
        val power = binding.applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "on_device_tts:speak").apply {
            setReferenceCounted(false)
        }
        val activity = ActivityLock(
            ActivityLock.DEFAULT_TIMEOUT_MS,
            acquire = { wakeLock.acquire(it) },
            release = { if (wakeLock.isHeld) wakeLock.release() },
        )
        val handler = OnnxTtsChannelHandler(activity)
        val context = binding.applicationContext
        val prefs = context.getSharedPreferences("speech_recovery", Context.MODE_PRIVATE)
        val recovery = NeuralRecovery({ prefs.getBoolean("pending", false) }, { prefs.edit().putBoolean("pending", it).commit() })
        methods = MethodChannel(binding.binaryMessenger, OnnxTtsChannelHandler.METHOD_CHANNEL).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "load", "speak", "synthesize" -> result.error("retired_engine", "Supertonic è stato rimosso. Usa le voci integrate o la voce Android.", null)
                    "deviceMemory" -> result.success(deviceMemory(context) + mapOf("neuralRecoveryNeeded" to recovery.blocked))
                    "resetNeuralRecovery" -> { recovery.reset(); result.success(null) }
                    "speechDiagnostics" -> {
                        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        val exit = if (Build.VERSION.SDK_INT >= 30) runCatching { manager.getHistoricalProcessExitReasons(context.packageName, 0, 1).firstOrNull()?.let { "${it.reason}/${it.status}" } }.getOrNull() else null
                        result.success(deviceMemory(context) + mapOf("device" to "${Build.MANUFACTURER} ${Build.MODEL}", "androidApi" to Build.VERSION.SDK_INT, "abis" to Build.SUPPORTED_ABIS.joinToString(), "neuralRecoveryNeeded" to recovery.blocked, "lastProcessExit" to (exit ?: "non disponibile")))
                    }
                    else -> {
                        if (call.method == "load") {
                            val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                            val info = ActivityManager.MemoryInfo(); manager.getMemoryInfo(info)
                            if (recovery.blocked || manager.isLowRamDevice || info.totalMem < 2560L * 1024 * 1024 || info.availMem < maxOf(768L * 1024 * 1024, info.threshold + 650L * 1024 * 1024)) {
                                result.error("load_failed", if(recovery.blocked) "La precedente lettura IA non è terminata. Premi Riprova voci IA per riprovare." else "Memoria disponibile insufficiente per la voce IA. La voce Android resta disponibile.", null)
                                return@setMethodCallHandler
                            }
                        }
                        val guarded = call.method in setOf("load", "speak", "synthesize")
                        if (guarded) recovery.begin()
                        val proxy = object : MethodChannel.Result {
                            override fun success(value: Any?) { if(guarded) recovery.finish(); result.success(value) }
                            override fun error(code: String, message: String?, details: Any?) { if(guarded) recovery.finish(); result.error(code,message,details) }
                            override fun notImplemented() { if(guarded) recovery.finish(); result.notImplemented() }
                        }
                        handler.onMethodCall(call,proxy)
                    }
                }
            }
        }
        events = EventChannel(binding.binaryMessenger, OnnxTtsChannelHandler.EVENT_CHANNEL).also {
            it.setStreamHandler(handler)
        }
        engine = handler

        val memory = MemoryEvents()
        memoryEvents = EventChannel(binding.binaryMessenger, MEMORY_CHANNEL).also {
            it.setStreamHandler(memory)
        }
        context.registerComponentCallbacks(memory)
        this.memory = memory
        this.context = context
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        systemTts.onDetachedFromEngine(binding)
        methods?.setMethodCallHandler(null)
        events?.setStreamHandler(null)
        memoryEvents?.setStreamHandler(null)
        memory?.let { context?.unregisterComponentCallbacks(it) }
        engine?.dispose()
        methods = null
        events = null
        memoryEvents = null
        memory = null
        context = null
        engine = null
    }

    private fun deviceMemory(context: Context): Map<String, Any> {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val info = ActivityManager.MemoryInfo()
        manager.getMemoryInfo(info)
        return mapOf(
            "totalBytes" to info.totalMem,
            "availableBytes" to info.availMem,
            "lowRamDevice" to manager.isLowRamDevice,
        )
    }

    /**
     * Sends `{level}` to Dart for the trim levels that should release the
     * models ([MemoryPressure.shouldRelease]), and for `onLowMemory`.
     */
    private class MemoryEvents : EventChannel.StreamHandler, ComponentCallbacks2 {
        private val main = Handler(Looper.getMainLooper())
        private var sink: EventChannel.EventSink? = null

        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            sink = events
        }

        override fun onCancel(arguments: Any?) {
            sink = null
        }

        override fun onTrimMemory(level: Int) {
            if (MemoryPressure.shouldRelease(level)) send(level)
        }

        @Deprecated("Deprecated in Java")
        override fun onLowMemory() = send(MemoryPressure.LOW_MEMORY)

        override fun onConfigurationChanged(newConfig: Configuration) {}

        private fun send(level: Int) {
            main.post { sink?.success(mapOf("level" to level)) }
        }
    }
}
