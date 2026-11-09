package com.muxable.ondevicetts
import kotlin.test.*
import org.junit.jupiter.api.Test
class SpeechSafetyTest {
 @Test fun fileSynthesisOnAndroid7NeverReadsMissingText() {assertNull(SpeechProgress.legacyLength(25,true,null));assertNull(SpeechProgress.legacyLength(25,false,null));assertEquals(4,SpeechProgress.legacyLength(25,false,"ciao"));assertNull(SpeechProgress.legacyLength(26,false,"ciao"))}
 @Test fun staleAndVendorRangesAreBounded() {assertNull(SpeechProgress.bounds(null,1,2));assertEquals(0 to 4,SpeechProgress.bounds("ciao",-10,100));assertEquals(4 to 4,SpeechProgress.bounds("ciao",100,-2))}
}
