package com.maintainiac.ui_lab_2_1

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.PowerManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

// Bounded adaptation of the 5.7 runtime probe. No camera or identity access.
class DeviceWorkloadBridge(private val context: Context) {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "maintainiac/device_capabilities").setMethodCallHandler { call, result ->
            if (call.method != "readRuntimeCapabilities") {
                result.notImplemented()
            } else {
                try {
                    val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    val memory = ActivityManager.MemoryInfo().also(manager::getMemoryInfo)
                    val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                    val thermal = if (Build.VERSION.SDK_INT >= 29) {
                        when (power.currentThermalStatus) {
                            in PowerManager.THERMAL_STATUS_CRITICAL..PowerManager.THERMAL_STATUS_SHUTDOWN -> "critical"
                            PowerManager.THERMAL_STATUS_SEVERE -> "serious"
                            PowerManager.THERMAL_STATUS_MODERATE -> "fair"
                            else -> "nominal"
                        }
                    } else "unknown"
                    result.success(mapOf(
                        "physicalRamMb" to memory.totalMem / 1048576,
                        "availableRamMb" to memory.availMem / 1048576,
                        "applicationHeapMb" to manager.memoryClass,
                        "lowRam" to manager.isLowRamDevice,
                        "lowMemory" to memory.lowMemory,
                        "powerSaving" to power.isPowerSaveMode,
                        "thermalState" to thermal
                    ))
                } catch (_: Exception) {
                    result.error("unavailable", "Device workload information is unavailable.", null)
                }
            }
        }
    }
}
