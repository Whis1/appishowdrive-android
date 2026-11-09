package com.muxable.ondevicetts

internal object SpeechProgress {
    fun legacyLength(api: Int, fileSynthesis: Boolean, text: String?): Int? =
        if (api < 26 && !fileSynthesis) text?.length else null
    fun bounds(text: String?, start: Int, end: Int): Pair<Int, Int>? {
        if (text == null) return null
        val a = start.coerceIn(0, text.length)
        return a to end.coerceIn(a, text.length)
    }
}
