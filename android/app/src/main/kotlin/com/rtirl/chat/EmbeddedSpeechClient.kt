package com.rtirl.chat

import android.content.*
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.PlaybackParams
import android.os.*
import io.flutter.plugin.common.MethodChannel
import java.io.File

class EmbeddedSpeechClient(private val context: Context, private val channel: MethodChannel) : ServiceConnection {
    companion object {
        val voices = linkedMapOf("F1" to "if_sara", "F2" to "if_heart", "F3" to "if_emma", "F4" to "if_dora", "F5" to "if_luna", "M1" to "im_nicola", "M2" to "im_adam", "M3" to "im_george", "M4" to "im_alex", "M5" to "im_luca")
    }
    private val main = Handler(Looper.getMainLooper())
    private val wakeLock = (context.getSystemService(Context.POWER_SERVICE) as PowerManager)
        .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "APPISHOWDRIVE:embedded-speech").apply { setReferenceCounted(false) }
    private var service: Messenger? = null
    private var bound = false
    private var sequence = 0
    private var pending: MethodChannel.Result? = null
    private var request: Bundle? = null
    private var player: MediaPlayer? = null
    private var audio: File? = null
    private val timeout = Runnable { runCatching { service?.send(Message.obtain(null, 2)) }; finish("Tempo di elaborazione della voce scaduto."); disconnect() }
    private val reply = Messenger(Handler(Looper.getMainLooper()) { message ->
        val data = message.data
        if (data.getInt("id") != sequence || pending == null) {
            data.getString("path")?.let { safeAudio(it)?.delete() }
        } else {
            val error = data.getString("error")
            if (error != null) finish(error) else play(data.getString("path"))
        }
        true
    })
    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    finish(null)
                    if (Build.VERSION.SDK_INT < 26 || !Process.is64Bit()) { result.error("load_failed", "Le voci integrate richiedono Android 8 a 64 bit. La voce Android resta disponibile.", null); return@setMethodCallHandler }
                    val voice = voices[call.argument<String>("voice")]
                    if (voice == null) { result.error("bad_voice", "Voce sconosciuta.", null); return@setMethodCallHandler }
                    sequence++
                    pending = result
                    wakeLock.acquire(180000)
                    request = Bundle().apply {
                        putInt("id", sequence); putString("voice", voice)
                        putString("text", call.argument<String>("text"))
                        putFloat("rate", (call.argument<Double>("rate") ?: .5).toFloat())
                        putFloat("pitch", (call.argument<Double>("pitch") ?: 1.0).toFloat())
                    }
                    main.postDelayed(timeout, 90000)
                    if (service != null) send() else if (!bound) {
                        bound = context.bindService(Intent(context, EmbeddedSpeechService::class.java), this, Context.BIND_AUTO_CREATE)
                        if (!bound) finish("Motore vocale non disponibile.")
                    }
                }
                "stop" -> { runCatching { service?.send(Message.obtain(null, 2)) }; finish(null); result.success(null) }
                "release" -> { runCatching { service?.send(Message.obtain(null, 3)) }; finish(null); disconnect(); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }
    private fun send() {
        val data = request ?: return
        runCatching { service?.send(Message.obtain(null, 1).apply { this.data = data; replyTo = reply }) }
            .onFailure { finish("Collegamento al motore vocale interrotto."); disconnect() }
    }
    override fun onServiceConnected(name: ComponentName, binder: IBinder) { service = Messenger(binder); send() }
    override fun onServiceDisconnected(name: ComponentName) { service = null; finish("Il motore vocale è stato fermato da Android. Uso della voce Android."); disconnect() }
    override fun onBindingDied(name: ComponentName) = onServiceDisconnected(name)
    override fun onNullBinding(name: ComponentName) = onServiceDisconnected(name)
    private fun disconnect() { if (bound) runCatching { context.unbindService(this) }; bound = false; service = null }
    private fun safeAudio(path: String): File? = File(path).takeIf { it.parentFile?.canonicalPath == context.cacheDir.canonicalPath && it.name.matches(Regex("speech-\\d+\\.wav")) }
    private fun play(path: String?) {
        try {
            val file = path?.let(::safeAudio) ?: error("Audio non disponibile.")
            audio = file
            player = MediaPlayer().apply {
                setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
                // Intentionally never request audio focus or pause any web/video source.
                setDataSource(file.absolutePath)
                setOnPreparedListener { p ->
                    runCatching {
                        main.removeCallbacks(timeout)
                        main.postDelayed(timeout, p.duration.toLong() * 4 + 15000)
                        wakeLock.acquire(p.duration.toLong() * 4 + 15000)
                        p.playbackParams = PlaybackParams().setSpeed(((request?.getFloat("rate") ?: .5f) * 2).coerceIn(.3f, 2f)).setPitch((request?.getFloat("pitch") ?: 1f).coerceIn(.5f, 2f))
                        p.start()
                    }.onFailure { finish("Riproduzione della voce non riuscita.") }
                }
                setOnCompletionListener { finish(null) }
                setOnErrorListener { _, _, _ -> finish("Riproduzione della voce non riuscita."); true }
                prepareAsync()
            }
        } catch (_: Exception) { finish("Audio della voce non disponibile.") }
    }
    private fun finish(error: String?) {
        main.removeCallbacks(timeout)
        runCatching { if (wakeLock.isHeld) wakeLock.release() }
        player?.let { runCatching { it.release() } }; player = null
        audio?.delete(); audio = null
        val result = pending; pending = null; request = null
        if (error == null) result?.success(null) else result?.error("load_failed", error, null)
    }
    fun dispose() { channel.setMethodCallHandler(null); finish(null); disconnect() }
}
