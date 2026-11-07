package com.rtirl.chat

import org.junit.Assert.assertThrows
import org.junit.Test

class UpdateIdentityTest {
    private val current = UpdateIdentity("com.ishowdrive.chat", 5, setOf("trusted-certificate"))
    private val next = current.copy(version = 6)
    @Test fun acceptsNewerVersionWithSameIdentity() { requireTrustedUpdate(current, next, 6) }
    @Test fun rejectsDifferentPackageEvenWithSameCertificate() { assertThrows(IllegalArgumentException::class.java) { requireTrustedUpdate(current, next.copy(packageName = "com.rtirl.chat"), 6) } }
    @Test fun rejectsUntrustedCertificate() { assertThrows(IllegalArgumentException::class.java) { requireTrustedUpdate(current, next.copy(certificates = setOf("attacker")), 6) } }
    @Test fun rejectsExtraSigner() { assertThrows(IllegalArgumentException::class.java) { requireTrustedUpdate(current, next.copy(certificates = current.certificates + "attacker"), 6) } }
    @Test fun rejectsUnsignedApk() { assertThrows(IllegalArgumentException::class.java) { requireTrustedUpdate(current, next.copy(certificates = emptySet()), 6) } }
    @Test fun rejectsMissingInstalledTrust() { assertThrows(IllegalArgumentException::class.java) { requireTrustedUpdate(current.copy(certificates = emptySet()), next, 6) } }
    @Test fun rejectsDowngrade() { assertThrows(IllegalArgumentException::class.java) { requireTrustedUpdate(current, next.copy(version = 4), 4) } }
    @Test fun rejectsReinstallOfCurrentVersion() { assertThrows(IllegalArgumentException::class.java) { requireTrustedUpdate(current, current, 5) } }
    @Test fun rejectsManifestVersionMismatch() { assertThrows(IllegalArgumentException::class.java) { requireTrustedUpdate(current, next, 7) } }
    @Test fun rechecksVersionWhenOpeningInstaller() { requireTrustedUpdate(current, next, null) }
}
