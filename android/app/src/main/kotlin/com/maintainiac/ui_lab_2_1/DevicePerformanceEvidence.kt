package com.maintainiac.ui_lab_2_1

import android.content.Context
import android.os.Build
import com.google.android.gms.deviceperformance.DevicePerformance

/** Process-local evidence. Unlike the 5.7 wrapper, no preference file or blocking read. */
internal class DevicePerformanceEvidence {
    @Volatile private var started = false
    @Volatile private var providerClass = 0

    fun read(platformClass: Int, request: ((Int) -> Unit) -> Unit): Int {
        val shouldStart = synchronized(this) {
            if (started) false else { started = true; true }
        }
        if (shouldStart) {
            // Missing Play Services or a failed query keeps the OS fallback.
            // No idle polling/retry loop; a later app session can try again.
            runCatching { request { value ->
                if (value in 30..100) providerClass = value
            } }
        }
        val platform = platformClass.takeIf { it in 30..100 } ?: 0
        return maxOf(platform, providerClass)
    }
}

internal object DevicePerformanceProbe {
    private val evidence = DevicePerformanceEvidence()
    fun read(context: Context): Int = evidence.read(
        if (Build.VERSION.SDK_INT >= 31) Build.VERSION.MEDIA_PERFORMANCE_CLASS else 0
    ) { accept ->
        DevicePerformance.getClient(context.applicationContext).mediaPerformanceClass()
            .addOnSuccessListener { value -> accept(value) }
            .addOnFailureListener { /* Unknown; never fabricate performance. */ }
    }
}
