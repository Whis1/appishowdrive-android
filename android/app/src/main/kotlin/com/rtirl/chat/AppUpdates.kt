package com.rtirl.chat

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Downloaded APKs must match this installed app's signing identity, not just
 * the digest supplied by the release server. Neither a new package nor a
 * downgrade can be installed through this channel. */
class AppUpdates(private val activity: Activity, private val channel: MethodChannel) {
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val busy = AtomicBoolean(false)
    private val closed = AtomicBoolean(false)
    private val directory get() = File(activity.filesDir, "updates").apply { mkdirs() }
    private val apk get() = File(directory, "APPISHOWDRIVE.apk")
    private val prefix = "https://github.com/Whis1/appishowdrive-android/releases/download/"

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "installed" -> result.success(mapOf("build" to version(installed()), "package" to activity.packageName, "mediaActive" to (AudioService.activeSourceCount > 0 || TtsService.isRunning)))
                "download" -> {
                    val url = call.argument<String>("url") ?: ""
                    val sha = call.argument<String>("sha256") ?: ""
                    val bytes = call.argument<Number>("bytes")?.toLong() ?: 0
                    val build = call.argument<Number>("build")?.toLong() ?: 0
                    if (!url.startsWith(prefix) || !Regex("[a-f0-9]{64}").matches(sha) || bytes !in 1..MAX_BYTES || build <= version(installed())) {
                        result.error("invalid_release", "Aggiornamento non valido.", null)
                    } else if (!busy.compareAndSet(false, true)) {
                        result.error("busy", "Un download è già in corso.", null)
                    } else executor.execute { download(url, sha, bytes, build, result) }
                }
                "install" -> try {
                    verify(apk, null)
                    if (Build.VERSION.SDK_INT >= 26 && !activity.packageManager.canRequestPackageInstalls()) {
                        activity.startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${activity.packageName}")))
                        result.success("permission")
                    } else {
                        val uri = FileProvider.getUriForFile(activity, activity.packageName + ".updates", apk)
                        activity.startActivity(Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        })
                        result.success("installer")
                    }
                } catch (e: Exception) { result.error("install_failed", e.message, null) }
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun installed(): PackageInfo = activity.packageManager.getPackageInfo(activity.packageName, flags())
    private fun flags() = if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES
    @Suppress("DEPRECATION")
    private fun version(info: PackageInfo): Long = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
    @Suppress("DEPRECATION")
    private fun certificates(info: PackageInfo): Set<String> = (if (Build.VERSION.SDK_INT >= 28) info.signingInfo?.apkContentsSigners else info.signatures)
        ?.map { hex(MessageDigest.getInstance("SHA-256").digest(it.toByteArray())) }?.toSet() ?: emptySet()

    private fun verify(file: File, expectedBuild: Long?) {
        val info = activity.packageManager.getPackageArchiveInfo(file.absolutePath, flags()) ?: error("Il file non è un APK valido.")
        val current = installed()
        requireTrustedUpdate(
            UpdateIdentity(activity.packageName, version(current), certificates(current)),
            UpdateIdentity(info.packageName, version(info), certificates(info)),
            expectedBuild,
        )
    }

    private fun connection(url: String): HttpURLConnection {
        var target = URL(url)
        repeat(6) {
            check(target.protocol == "https" && (target.host == "github.com" || target.host.endsWith(".githubusercontent.com"))) { "Origine del download non consentita." }
            val c = (target.openConnection() as HttpURLConnection).apply {
                connectTimeout = 15_000; readTimeout = 30_000; instanceFollowRedirects = false
                setRequestProperty("User-Agent", "APPISHOWDRIVE-Android")
            }
            val status = c.responseCode
            if (status in listOf(301, 302, 303, 307, 308)) {
                val location = c.getHeaderField("Location") ?: error("Reindirizzamento non valido.")
                target = URL(target, location); c.disconnect()
            } else {
                check(status == 200) { "Download non disponibile (HTTP$status)." }
                return c
            }
        }
        error("Troppi reindirizzamenti.")
    }

    private fun download(url: String, expectedSha: String, expectedBytes: Long, expectedBuild: Long, result: MethodChannel.Result) {
        val partial = File(directory, "download.partial")
        var c: HttpURLConnection? = null
        try {
            check(directory.usableSpace > expectedBytes + 20_000_000) { "Spazio insufficiente sul telefono." }
            c = connection(url)
            val digest = MessageDigest.getInstance("SHA-256")
            var count = 0L; var lastProgress = 0L
            c.inputStream.use { input -> partial.outputStream().use { output ->
                val buffer = ByteArray(64 * 1024)
                while (true) {
                    check(!closed.get()) { "Download annullato." }
                    val size = input.read(buffer); if (size < 0) break
                    count += size; check(count <= expectedBytes) { "Dimensione APK inattesa." }
                    digest.update(buffer, 0, size); output.write(buffer, 0, size)
                    val now = System.currentTimeMillis()
                    if (now - lastProgress >= 150) {
                        val progress = count.toDouble() / expectedBytes
                        main.post { if (!closed.get()) channel.invokeMethod("progress", progress) }; lastProgress = now
                    }
                }
            } }
            check(count == expectedBytes && hex(digest.digest()) == expectedSha) { "Il file scaricato non supera il controllo di integrità." }
            verify(partial, expectedBuild)
            if (apk.exists()) check(apk.delete()) { "Impossibile preparare l'aggiornamento." }
            check(partial.renameTo(apk)) { "Impossibile salvare l'aggiornamento." }
            main.post { if (!closed.get()) result.success(true) }
        } catch (e: Exception) {
            partial.delete()
            main.post { if (!closed.get()) result.error("download_failed", e.message, null) }
        } finally { c?.disconnect(); busy.set(false) }
    }

    fun close() { closed.set(true); executor.shutdownNow(); channel.setMethodCallHandler(null) }
    companion object {
        private const val MAX_BYTES = 512L * 1024 * 1024
        private fun hex(bytes: ByteArray) = bytes.joinToString("") { "%02x".format(it.toInt() and 255) }
    }
}
