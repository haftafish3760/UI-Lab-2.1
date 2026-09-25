package com.maintainiac.ui_lab_2_1

import org.junit.Assert.*
import org.junit.Test

class DevicePerformanceEvidenceTest {
    @Test fun delayedProviderDoesNotBlockOrDuplicateRequests() {
        val evidence = DevicePerformanceEvidence()
        var complete: ((Int) -> Unit)? = null
        var requests = 0
        val request: ((Int) -> Unit) -> Unit = { requests++; complete = it }
        repeat(20) { assertEquals(31, evidence.read(31, request)) }
        assertEquals(1, requests)
        complete!!(35)
        assertEquals(35, evidence.read(31, request))
        assertEquals(1, requests)
    }
    @Test fun failureOrInvalidEvidenceCannotInventHigherClass() {
        val failure = DevicePerformanceEvidence()
        assertEquals(31, failure.read(31) { throw IllegalStateException("unavailable") })
        assertEquals(31, failure.read(31) { fail("must not spin on failure") })
        for (value in listOf(-1, 0, 29, 101, Int.MAX_VALUE)) {
            assertEquals(0, DevicePerformanceEvidence().read(0) { accept -> accept(value) })
        }
    }
}
