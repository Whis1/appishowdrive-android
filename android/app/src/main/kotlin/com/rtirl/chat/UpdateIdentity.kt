package com.rtirl.chat

internal data class UpdateIdentity(val packageName: String, val version: Long, val certificates: Set<String>)

internal fun requireTrustedUpdate(current: UpdateIdentity, candidate: UpdateIdentity, expectedBuild: Long?) {
    require(candidate.packageName == current.packageName) { "L'APK appartiene a un'altra applicazione." }
    require(candidate.version > current.version && (expectedBuild == null || candidate.version == expectedBuild)) { "Versione APK non valida." }
    require(current.certificates.isNotEmpty() && candidate.certificates == current.certificates) { "Firma APK diversa da APPISHOWDRIVE." }
}
