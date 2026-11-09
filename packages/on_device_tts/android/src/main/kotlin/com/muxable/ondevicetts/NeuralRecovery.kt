package com.muxable.ondevicetts

/** No speech text is saved. A native/process exit leaves a marker for next launch. */
internal class NeuralRecovery(private val read: () -> Boolean, private val write: (Boolean) -> Unit) {
    var blocked = read()
        private set
    private var active = 0
    fun begin() { active++; write(true) }
    fun finish() { active = (active - 1).coerceAtLeast(0); if (active == 0) write(false) }
    fun reset() { blocked = false; active = 0; write(false) }
}
