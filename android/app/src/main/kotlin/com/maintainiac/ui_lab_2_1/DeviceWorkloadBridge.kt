package com.maintainiac.ui_lab_2_1

import android.app.Activity
import io.flutter.plugin.common.StandardMethodCodec
import android.Manifest
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.location.LocationManager
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.os.StatFs
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

// No identity, sensor samples, location reads, permission requests or persistence.
class DeviceWorkloadBridge(private val context: Activity) {
    private val extended = DeviceExtendedProbe(context)
    fun register(messenger: BinaryMessenger) {
        DeviceResourceEvents(context).register(messenger)
        MethodChannel(messenger, "app.device_capabilities", StandardMethodCodec.INSTANCE, messenger.makeBackgroundTaskQueue()).setMethodCallHandler { call, result ->
            if (call.method != "readRuntimeCapabilities") result.notImplemented()
            else result.success(read())
        }
    }

    private fun read(): Map<String, Any> {
        val facts = mutableMapOf<String, Any>("probeAvailable" to true)
        runCatching {
            val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val memory = ActivityManager.MemoryInfo().also(manager::getMemoryInfo)
            facts["physicalRamMb"] = memory.totalMem / 1048576
            facts["availableRamMb"] = memory.availMem / 1048576
            facts["applicationHeapMb"] = manager.memoryClass
            facts["lowRam"] = manager.isLowRamDevice
            facts["lowMemory"] = memory.lowMemory
        }
        facts["cpuCores"] = Runtime.getRuntime().availableProcessors()
        Build.SUPPORTED_ABIS.firstOrNull()?.let { facts["cpuArchitecture"] = it }
        facts["mediaPerformanceClass"] = DevicePerformanceProbe.read(context)
        runCatching { facts["freeStorageBytes"] = StatFs(context.filesDir.absolutePath).availableBytes }
        runCatching {
            val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            facts["powerSaving"] = power.isPowerSaveMode
            facts["thermalState"] = if (Build.VERSION.SDK_INT >= 29) when (power.currentThermalStatus) {
                PowerManager.THERMAL_STATUS_NONE -> "nominal"
                PowerManager.THERMAL_STATUS_LIGHT, PowerManager.THERMAL_STATUS_MODERATE -> "fair"
                PowerManager.THERMAL_STATUS_SEVERE -> "serious"
                in PowerManager.THERMAL_STATUS_CRITICAL..PowerManager.THERMAL_STATUS_SHUTDOWN -> "critical"
                else -> "unknown"
            } else "unknown"
        }
        runCatching {
            val battery = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            if (battery != null) {
                val level = battery.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = battery.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                if (level >= 0 && scale > 0) facts["batteryPercent"] = level * 100 / scale
                if (battery.hasExtra(BatteryManager.EXTRA_PLUGGED))
                    facts["externalPower"] = battery.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) != 0
                if (battery.hasExtra(BatteryManager.EXTRA_TEMPERATURE))
                    facts["batteryTemperatureC"] = battery.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) / 10.0
                facts["batteryHealth"] = when (battery.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)) {
                    BatteryManager.BATTERY_HEALTH_GOOD -> "good"
                    BatteryManager.BATTERY_HEALTH_OVERHEAT -> "overheating"
                    BatteryManager.BATTERY_HEALTH_DEAD -> "failure"
                    BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE,
                    BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE,
                    BatteryManager.BATTERY_HEALTH_COLD -> "degraded"
                    else -> "unknown"
                }
            }
        }
        facts["features"] = features()
        facts["extended"] = extended.read()
        facts["descriptor"] = mapOf("platform" to "android", "osVersion" to Build.VERSION.RELEASE,
            "manufacturer" to Build.MANUFACTURER, "model" to Build.MODEL, "sdk" to Build.VERSION.SDK_INT)
        // A partially failed probe remains useful, but cannot masquerade as a
        // complete runtime observation if neither memory nor thermal is available.
        facts["probeAvailable"] = facts.containsKey("availableRamMb") || facts["thermalState"] != null
        return facts
    }

    private fun permission(name: String): String =
        if (context.checkSelfPermission(name) == PackageManager.PERMISSION_GRANTED) "granted" else "denied"

    private fun features(): Map<String, Any> {
        val output = mutableMapOf<String, Any>()
        runCatching {
            val sensors = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
            val motionPermission = if (Build.VERSION.SDK_INT >= 29)
                permission(Manifest.permission.ACTIVITY_RECOGNITION) else "granted"
            val types = mapOf("accelerometer" to Sensor.TYPE_ACCELEROMETER,
                "gyroscope" to Sensor.TYPE_GYROSCOPE, "magnetometer" to Sensor.TYPE_MAGNETIC_FIELD,
                "barometer" to Sensor.TYPE_PRESSURE, "stepCounter" to Sensor.TYPE_STEP_COUNTER,
                "stepDetector" to Sensor.TYPE_STEP_DETECTOR, "significantMotion" to Sensor.TYPE_SIGNIFICANT_MOTION,
                "gravity" to Sensor.TYPE_GRAVITY, "linearAcceleration" to Sensor.TYPE_LINEAR_ACCELERATION,
                "rotationVector" to Sensor.TYPE_ROTATION_VECTOR, "stationaryDetection" to 29,
                "motionDetection" to 30, "ambientLight" to Sensor.TYPE_LIGHT, "proximity" to Sensor.TYPE_PROXIMITY)
            types.forEach { (name, type) ->
                output[name] = mapOf("availability" to if (sensors.getDefaultSensor(type) != null) "available" else "unavailable",
                    "permission" to if (name == "stepCounter" || name == "stepDetector") motionPermission else "granted")
            }
            // Android activity classification requires a separate provider; a
            // step sensor alone is not proof of driving/walking classification.
            output["activityRecognition"] = mapOf("availability" to "unknown", "permission" to motionPermission)
        }
        val pm = context.packageManager
        output["rearCamera"] = mapOf("availability" to if (pm.hasSystemFeature(PackageManager.FEATURE_CAMERA)) "available" else "unavailable",
            "permission" to permission(Manifest.permission.CAMERA))
        output["frontCamera"] = mapOf("availability" to if (pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_FRONT)) "available" else "unavailable",
            "permission" to permission(Manifest.permission.CAMERA))
        runCatching {
            val location = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
            output["gpsReceiver"] = mapOf("availability" to if (pm.hasSystemFeature(PackageManager.FEATURE_LOCATION_GPS)) "available" else "unavailable",
                "permission" to permission(Manifest.permission.ACCESS_FINE_LOCATION))
            output["backgroundLocation"] = mapOf("availability" to if (pm.hasSystemFeature(PackageManager.FEATURE_LOCATION)) "available" else "unavailable",
                "permission" to if (Build.VERSION.SDK_INT >= 29) permission(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                    else permission(Manifest.permission.ACCESS_FINE_LOCATION))
            output["location"] = mapOf("availability" to if (pm.hasSystemFeature(PackageManager.FEATURE_LOCATION)) "available" else "unavailable",
                "permission" to permission(Manifest.permission.ACCESS_FINE_LOCATION),
                "serviceEnabled" to if (Build.VERSION.SDK_INT >= 28) location.isLocationEnabled else
                    (location.isProviderEnabled(LocationManager.GPS_PROVIDER) || location.isProviderEnabled(LocationManager.NETWORK_PROVIDER)))
        }
        return output
    }
}
