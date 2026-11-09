package com.rtirl.chat

import android.app.ActivityManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.*
import com.google.mediapipe.tasks.audio.texttospeech.TextToSpeech
import com.google.mediapipe.tasks.audio.texttospeech.TextToSpeechOptions
import com.google.mediapipe.tasks.audio.texttospeech.SynthesisOptions
import com.google.mediapipe.tasks.core.BaseOptions
import java.io.File
import java.io.RandomAccessFile
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

/** A native model failure stays in this private worker process, away from Flutter/video. */
class EmbeddedSpeechService : Service() {
    private val worker = Executors.newSingleThreadExecutor()
    private val generation = AtomicInteger(0)
    @Volatile private var engine: TextToSpeech? = null
    private val main = Handler(Looper.getMainLooper())
    private val messenger = Messenger(Handler(Looper.getMainLooper()) { message ->
        when (message.what) {
            1 -> {
                val reply = message.replyTo
                val data = Bundle(message.data)
                val token = generation.incrementAndGet()
                runCatching { engine?.cancel() }
                worker.execute { synthesize(data, reply, token) }
            }
            2 -> { generation.incrementAndGet(); runCatching { engine?.cancel() } }
            3 -> {
                generation.incrementAndGet(); runCatching { engine?.cancel() }
                worker.execute { runCatching { engine?.close() }; engine = null }
            }
        }
        true
    })
    override fun onBind(intent: Intent) = messenger.binder

    private fun synthesize(data: Bundle, reply: Messenger?, token: Int) {
        val id = data.getInt("id")
        var output: File? = null
        try {
            if (generation.get() != token) throw InterruptedException()
            val memory = ActivityManager.MemoryInfo()
            val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            manager.getMemoryInfo(memory)
            check(!manager.isLowRamDevice && memory.availMem > maxOf(1100L * 1024 * 1024, memory.threshold + 850L * 1024 * 1024)) { "Memoria insufficiente: uso della voce Android." }
            check(Build.VERSION.SDK_INT >= 26) { "Queste voci richiedono Android 8 o successivo." }
            if (engine == null) {
                val directory = File(filesDir, "embedded-speech").apply { mkdirs() }
                val model = File(directory, "kokoro-it-profiles-v1.litertlm")
                val length = 294783298L
                if (!model.isFile || model.length() != length) {
                    val partial = File(directory, "kokoro.partial")
                    assets.open("speech/kokoro.litertlm").use { input -> partial.outputStream().use { input.copyTo(it) } }
                    check(partial.length() == length && partial.renameTo(model)) { "Modello vocale non disponibile." }
                }
                engine = TextToSpeech.create(TextToSpeechOptions(
                    baseOptions = BaseOptions.builder().setModelAssetPath(model.absolutePath).build(),
                    defaultLocale = "it", cacheDirectory = directory.absolutePath,
                ))
            }
            val voice = data.getString("voice") ?: "if_sara"
            check(voice in EmbeddedSpeechClient.voices.values) { "Voce sconosciuta." }
            val text = data.getString("text") ?: ""
            check(text.isNotBlank() && text.length <= 2000) { "Testo vocale non valido." }
            output = File(cacheDir, "speech-$id.wav")
            RandomAccessFile(output, "rw").use { file ->
                file.setLength(0); file.write(ByteArray(44))
                for (chunk in SpeechChunks.split(text)) {
                    if (generation.get() != token) throw InterruptedException()
                    val audio = engine!!.synthesize(chunk, SynthesisOptions(voiceId = voice, locale = "it"))
                    check(audio.sampleRateHz == 24000 && audio.samples.isNotEmpty())
                    val pcm = ByteArray(audio.samples.size * 2)
                    for ((index, sample) in audio.samples.withIndex()) {
                        check(sample.isFinite())
                        val value = (sample.coerceIn(-1f, 1f) * 32767).toInt()
                        pcm[index * 2] = (value and 255).toByte()
                        pcm[index * 2 + 1] = ((value shr 8) and 255).toByte()
                    }
                    file.write(pcm)
                }
                val size = file.length().toInt() - 44
                file.seek(0)
                fun le(value: Int, bytes: Int) { repeat(bytes) { file.write((value shr (it * 8)) and 255) } }
                file.writeBytes("RIFF"); le(size + 36, 4); file.writeBytes("WAVEfmt ")
                le(16, 4); le(1, 2); le(1, 2); le(24000, 4); le(48000, 4); le(2, 2); le(16, 2)
                file.writeBytes("data"); le(size, 4)
            }
            if (generation.get() != token) throw InterruptedException()
            val path = output.absolutePath
            main.post { runCatching { reply?.send(Message.obtain(null, 1).apply { this.data = Bundle().apply { putInt("id", id); putString("path", path) } }) } }
        } catch (error: Throwable) {
            output?.delete()
            val description = if (error is InterruptedException) "Lettura annullata." else (error.message ?: "Motore vocale non disponibile.")
            main.post { runCatching { reply?.send(Message.obtain(null, 1).apply { this.data = Bundle().apply { putInt("id", id); putString("error", description.take(240)) } }) } }
        }
    }
    override fun onDestroy() {
        generation.incrementAndGet(); runCatching { engine?.cancel() }
        worker.execute { runCatching { engine?.close() }; engine = null }
        worker.shutdown()
        super.onDestroy()
    }
}

object SpeechChunks {
    fun split(text: String): List<String> {
        val result = mutableListOf<String>()
        var remaining = text.trim()
        while (remaining.isNotEmpty()) {
            var end = minOf(110, remaining.length)
            if (end < remaining.length) {
                val space = remaining.lastIndexOf(' ', end)
                if (space > 35) end = space
            }
            if (end < remaining.length && end > 0 && Character.isHighSurrogate(remaining[end-1]) && Character.isLowSurrogate(remaining[end])) end--
            result.add(remaining.substring(0, end)); remaining = remaining.substring(end).trimStart()
        }
        return result
    }
}
