package com.rtirl.chat
import org.junit.Assert.*
import org.junit.Test
class SpeechChunksTest {
    @Test fun keepsWordsAndBoundsNativeInference() {
        val text=("Buon viaggio a tutti, la chat funziona. ").repeat(40).trim()
        val chunks=SpeechChunks.split(text)
        assertTrue(chunks.all { it.length in 1..110 })
        assertEquals(text,chunks.joinToString(" "))
    }
    @Test fun doesNotCutAnEmojiSurrogatePairInLongUnspacedInput() {
        val text="a"+"😀".repeat(200)
        val chunks=SpeechChunks.split(text)
        assertEquals(text,chunks.joinToString(""))
        assertTrue(chunks.all { !Character.isLowSurrogate(it.first()) && !Character.isHighSurrogate(it.last()) })
    }
}
