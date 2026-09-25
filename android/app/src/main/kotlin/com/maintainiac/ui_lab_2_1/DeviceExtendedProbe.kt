package com.maintainiac.ui_lab_2_1

import android.Manifest
import android.app.Activity
import android.app.ActivityManager
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.ImageFormat
import android.hardware.Sensor
import android.hardware.SensorManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.util.DisplayMetrics
import androidx.core.content.ContextCompat
import kotlin.math.roundToInt

/** Adapted read-only metadata from 5.7; never opens cameras or starts sensors. */
class DeviceExtendedProbe(private val activity: Activity) {
    private val context = activity.applicationContext
    private var staticFacts: Map<String, Any>? = null
    private var staticAt = 0L
    private var cameraPermission: Int? = null
    fun read(): Map<String, Any> {
        val now = android.os.SystemClock.elapsedRealtime()
        val permission = ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
        if (staticFacts == null || now - staticAt > 600_000L || cameraPermission != permission) {
            cameraPermission = permission
            val stable = mutableMapOf<String, Any>()
            runCatching { stable["cameraLenses"] = readCameraLenses() }
            runCatching { stable["media"] = readMedia() }
            runCatching { stable["graphics"] = readGraphics() }
            staticFacts = stable
            staticAt = now
        }
        val result = staticFacts!!.toMutableMap()
        runCatching { result["sensors"] = readSensors() }
        runCatching { result["battery"] = readBattery() }
        runCatching { result["display"] = readDisplay() }
        runCatching { result["connectivity"] = readConnectivity() }
        runCatching { result["bluetooth"] = readBluetoothCapabilities() }
        return result
    }

    private fun readBluetoothCapabilities(): Map<String, Any> {
        val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = manager?.adapter
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            Manifest.permission.BLUETOOTH_CONNECT else Manifest.permission.BLUETOOTH
        val authorized = ContextCompat.checkSelfPermission(context, permission) ==
                PackageManager.PERMISSION_GRANTED
        val result = mutableMapOf<String, Any>(
            "adapterAvailable" to (adapter != null),
            "authorization" to if (authorized) "authorized" else "denied",
            "supportsApprovedDeviceObservation" to (authorized && adapter != null),
        )
        if (authorized) result["poweredOn"] = adapter?.isEnabled == true
        return result
    }

    private fun readCameraLenses(): List<Map<String, Any>> {
        val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val result = mutableListOf<Map<String, Any>>()
        val seen = mutableSetOf<String>()
        val physicalIds = if (Build.VERSION.SDK_INT >= 29) {
            manager.cameraIdList.flatMap { id ->
                runCatching { manager.getCameraCharacteristics(id).physicalCameraIds }
                    .getOrDefault(emptySet())
            }.toSet()
        } else emptySet()
        manager.cameraIdList.forEach { id ->
            val characteristics = runCatching { manager.getCameraCharacteristics(id) }.getOrNull()
                ?: return@forEach
            val memberIds = if (Build.VERSION.SDK_INT >= 29) {
                runCatching { characteristics.physicalCameraIds }.getOrDefault(emptySet())
            } else emptySet()
            if (id !in physicalIds && seen.add(id)) {
                result += cameraLensMap(characteristics, memberIds.size.coerceAtLeast(1))
            }
            memberIds.forEach { physicalId ->
                runCatching { manager.getCameraCharacteristics(physicalId) }.getOrNull()?.let {
                    if (seen.add(physicalId)) result += cameraLensMap(it, 1)
                }
            }
        }
        return result
    }

    private fun cameraLensMap(c: CameraCharacteristics, physicalCount: Int): Map<String, Any> {
        val facing = when (c.get(CameraCharacteristics.LENS_FACING)) {
            CameraCharacteristics.LENS_FACING_FRONT -> "front"
            CameraCharacteristics.LENS_FACING_BACK -> "rear"
            CameraCharacteristics.LENS_FACING_EXTERNAL -> "external"
            else -> "unknown"
        }
        val focal = c.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
            ?.map(Float::toDouble).orEmpty()
        val apertures = c.get(CameraCharacteristics.LENS_INFO_AVAILABLE_APERTURES)
            ?.map(Float::toDouble).orEmpty()
        val still = c.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
            ?.getOutputSizes(ImageFormat.JPEG)?.maxByOrNull { it.width.toLong() * it.height }
        val capabilities = c.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)
            ?.toSet()
        val focusModes = c.get(CameraCharacteristics.CONTROL_AF_AVAILABLE_MODES)
            ?.toSet()
        val exposureRange = c.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_RANGE)
        val maxFps = c.get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES)
            ?.maxOfOrNull { it.upper } ?: 0
        val maxZoom = c.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM)
            ?.toDouble()
        val zoomRatio = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            c.get(CameraCharacteristics.CONTROL_ZOOM_RATIO_RANGE)?.upper?.toDouble()
        } else null
        return mapOf<String, Any?>(
            "position" to facing,
            "lensType" to if (physicalCount > 1) "logical_multi_camera"
                else "unknown",
            "physicalLensCount" to physicalCount,
            "maxStillWidth" to (still?.width ?: 0),
            "maxStillHeight" to (still?.height ?: 0),
            "minFocalLengthMm" to (focal.minOrNull() ?: 0.0),
            "maxFocalLengthMm" to (focal.maxOrNull() ?: 0.0),
            "minAperture" to (apertures.minOrNull() ?: 0.0),
            "maxZoomRatio" to zoomRatio,
            "maxDigitalZoom" to maxZoom,
            "maxVideoFps" to maxFps,
            "supportsTapFocus" to c.get(CameraCharacteristics.CONTROL_MAX_REGIONS_AF)?.let { it > 0 },
            "supportsContinuousFocus" to focusModes?.let { it.contains(CameraCharacteristics.CONTROL_AF_MODE_CONTINUOUS_PICTURE) || it.contains(CameraCharacteristics.CONTROL_AF_MODE_CONTINUOUS_VIDEO) },
            "supportsAutofocus" to focusModes?.any { it != CameraCharacteristics.CONTROL_AF_MODE_OFF },
            "supportsExposureCompensation" to (
                exposureRange?.let { it.lower < it.upper }
            ),
            "supportsStabilization" to supportsStabilization(c),
            "supportsRaw" to capabilities?.contains(
                CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_RAW,
            ),
            "supportsDepth" to capabilities?.contains(
                CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_DEPTH_OUTPUT,
            ),
            "supportsHdr" to supportsTenBitHdr(capabilities),
            "supportsTorch" to c.get(CameraCharacteristics.FLASH_INFO_AVAILABLE),
        ).filterValues { it != null }.mapValues { it.value!! }
    }

    private fun supportsStabilization(c: CameraCharacteristics): Boolean? {
        val optical = c.get(CameraCharacteristics.LENS_INFO_AVAILABLE_OPTICAL_STABILIZATION)
            ?.contains(CameraCharacteristics.LENS_OPTICAL_STABILIZATION_MODE_ON)
        val video = c.get(CameraCharacteristics.CONTROL_AVAILABLE_VIDEO_STABILIZATION_MODES)
            ?.contains(CameraCharacteristics.CONTROL_VIDEO_STABILIZATION_MODE_ON)
        return if (optical == true || video == true) true
            else if (optical == null || video == null) null else false
    }

    private fun supportsTenBitHdr(capabilities: Set<Int>?): Boolean? =
        if (Build.VERSION.SDK_INT >= 33) capabilities?.contains(
            CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_DYNAMIC_RANGE_TEN_BIT,
        ) else null

    private fun readSensors(): Map<String, Any> {
        val manager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensors = manager.getSensorList(Sensor.TYPE_ALL)
        val types = sensors.map { sensorType(it.type) }.distinct().sorted()
        val declaredBodySensors = buildSet {
            val packageManager = context.packageManager
            if (packageManager.hasSystemFeature("android.hardware.sensor.heartrate")) {
                add("heart_rate")
            }
            if (packageManager.hasSystemFeature("android.hardware.sensor.heartrate.ecg")) {
                add("heart_rate_ecg")
            }
        }
        return mapOf(
            "sensorCount" to sensors.size,
            "types" to types,
            "permissionGatedTypes" to declaredBodySensors.filterNot(types::contains).sorted(),
        )
    }

    @Suppress("DEPRECATION")
    private fun sensorType(type: Int): String = when (type) {
        Sensor.TYPE_ACCELEROMETER -> "accelerometer"
        Sensor.TYPE_MAGNETIC_FIELD -> "magnetometer"
        Sensor.TYPE_ORIENTATION -> "orientation_legacy"
        Sensor.TYPE_GYROSCOPE -> "gyroscope"
        Sensor.TYPE_PRESSURE -> "barometer"
        Sensor.TYPE_LIGHT -> "ambient_light"
        Sensor.TYPE_PROXIMITY -> "proximity"
        Sensor.TYPE_GRAVITY -> "gravity"
        Sensor.TYPE_LINEAR_ACCELERATION -> "linear_acceleration"
        Sensor.TYPE_ROTATION_VECTOR -> "rotation_vector"
        Sensor.TYPE_RELATIVE_HUMIDITY -> "humidity"
        Sensor.TYPE_AMBIENT_TEMPERATURE -> "ambient_temperature"
        14 -> "magnetometer_uncalibrated"
        15 -> "game_rotation_vector"
        16 -> "gyroscope_uncalibrated"
        Sensor.TYPE_SIGNIFICANT_MOTION -> "significant_motion"
        Sensor.TYPE_STEP_DETECTOR -> "step_detector"
        Sensor.TYPE_STEP_COUNTER -> "step_counter"
        20 -> "geomagnetic_rotation_vector"
        Sensor.TYPE_HEART_RATE -> "heart_rate"
        22 -> "tilt_detector"
        23 -> "wake_gesture"
        24 -> "glance_gesture"
        25 -> "pickup_gesture"
        26 -> "wrist_tilt_gesture"
        27 -> "device_orientation"
        28 -> "pose_6dof"
        29 -> "stationary_detect"
        30 -> "motion_detect"
        31 -> "heart_beat"
        32 -> "dynamic_sensor_metadata"
        33 -> "additional_sensor_info"
        34 -> "low_latency_offbody_detect"
        35 -> "accelerometer_uncalibrated"
        36 -> "hinge_angle"
        37 -> "head_tracker"
        38 -> "limited_axes_accelerometer"
        39 -> "limited_axes_gyroscope"
        40 -> "limited_axes_accelerometer_uncalibrated"
        41 -> "limited_axes_gyroscope_uncalibrated"
        42 -> "heading"
        else -> "type_$type"
    }

    private fun readBattery(): Map<String, Any> {
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED)) ?: return emptyMap()
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val percent = if (level >= 0 && scale > 0) (level * 100.0 / scale).roundToInt() else null
        val manager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val chargeMicroAh = manager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER)
        val remainingMah = chargeMicroAh.takeIf { it > 0 }?.div(1000)
        val estimatedFull = if (remainingMah != null && percent != null && percent > 0) {
            (remainingMah * 100.0 / percent).roundToInt()
        } else null
        val plugged = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0)
        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val result = mutableMapOf<String, Any>(
            "health" to batteryHealth(intent.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)),
            "capacityEstimateReliable" to false,
        )
        if (percent != null && percent in 0..100) result["levelPercent"] = percent
        if (intent.hasExtra(BatteryManager.EXTRA_PLUGGED)) {
            result["isExternalPowerConnected"] = plugged != 0
            result["powerSource"] = powerSource(plugged)
        }
        if (status in BatteryManager.BATTERY_STATUS_CHARGING..BatteryManager.BATTERY_STATUS_FULL) {
            result["isCharging"] = status == BatteryManager.BATTERY_STATUS_CHARGING
        }
        if (intent.hasExtra(BatteryManager.EXTRA_TEMPERATURE)) {
            result["temperatureCelsius"] = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) / 10.0
        }
        remainingMah?.let { result["remainingChargeMah"] = it }
        estimatedFull?.let { result["estimatedFullCapacityMah"] = it }
        intent.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY)?.let { result["technology"] = it }
        return result
    }

    private fun powerSource(value: Int): String = when (value) {
        BatteryManager.BATTERY_PLUGGED_AC -> "ac"
        BatteryManager.BATTERY_PLUGGED_USB -> "usb"
        BatteryManager.BATTERY_PLUGGED_WIRELESS -> "wireless"
        0 -> "battery"
        else -> "unknown"
    }

    private fun batteryHealth(value: Int?): String = when (value) {
        BatteryManager.BATTERY_HEALTH_GOOD -> "good"
        BatteryManager.BATTERY_HEALTH_OVERHEAT -> "overheating"
        BatteryManager.BATTERY_HEALTH_DEAD -> "failure"
        BatteryManager.BATTERY_HEALTH_COLD,
        BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE,
        BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "degraded"
        else -> "unknown"
    }

    @Suppress("DEPRECATION")
    private fun readDisplay(): Map<String, Any> {
        val display = activity.windowManager.defaultDisplay
        val metrics = DisplayMetrics().also(display::getRealMetrics)
        val hdr = if (Build.VERSION.SDK_INT >= 24) display.hdrCapabilities?.supportedHdrTypes?.isNotEmpty()
        else null
        val wideColor = Build.VERSION.SDK_INT >= 26 && display.isWideColorGamut
        val maxRefresh = if (Build.VERSION.SDK_INT >= 23) {
            display.supportedModes.maxOfOrNull { it.refreshRate.toDouble() } ?: display.refreshRate.toDouble()
        } else display.refreshRate.toDouble()
        return mapOf(
            "widthPixels" to metrics.widthPixels,
            "heightPixels" to metrics.heightPixels,
            "densityScale" to metrics.density.toDouble(),
            "maxRefreshRateHz" to maxRefresh,
            "supportsWideColor" to wideColor,
        ).toMutableMap().apply { if (hdr != null) put("supportsHdr", hdr) }
    }

    private fun readMedia(): Map<String, Any> {
        val decode = mutableSetOf<String>()
        val encode = mutableSetOf<String>()
        MediaCodecList(MediaCodecList.ALL_CODECS).codecInfos.forEach { info ->
            if (!isHardwareCodec(info)) return@forEach
            info.supportedTypes.mapNotNull(::normalizedCodec).forEach { codec ->
                if (info.isEncoder) encode += codec else decode += codec
            }
        }
        return mapOf(
            "hardwareDecodeTypes" to decode.sorted(),
            "hardwareEncodeTypes" to encode.sorted(),
        )
    }

    private fun isHardwareCodec(info: MediaCodecInfo): Boolean {
        if (Build.VERSION.SDK_INT >= 29) return info.isHardwareAccelerated
        return false // Pre-29 hardware acceleration cannot be certified by name.
    }

    private fun normalizedCodec(mime: String): String? = when (mime.lowercase()) {
        "video/avc" -> "h264"
        "video/hevc" -> "hevc"
        "video/x-vnd.on2.vp9" -> "vp9"
        "video/av01" -> "av1"
        "image/jpeg" -> "jpeg"
        else -> null
    }

    private fun readGraphics(): Map<String, Any> {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val openGlVersion = manager.deviceConfigurationInfo.reqGlEsVersion
        val major = openGlVersion shr 16
        val minor = openGlVersion and 0xffff
        val packageManager = context.packageManager
        val hasVulkan = Build.VERSION.SDK_INT >= 24 && packageManager.hasSystemFeature(
            android.content.pm.PackageManager.FEATURE_VULKAN_HARDWARE_LEVEL,
        )
        val vulkanVersion = if (Build.VERSION.SDK_INT >= 24) {
            packageManager.systemAvailableFeatures.firstOrNull {
                it.name == android.content.pm.PackageManager.FEATURE_VULKAN_HARDWARE_VERSION
            }?.version
        } else null
        return mapOf(
            "apiName" to if (hasVulkan) "vulkan+opengl_es" else "opengl_es",
            "apiVersion" to "$major.$minor",
            "featureLevel" to (vulkanVersion?.let { "vulkan_$it" } ?: "gles_$major$minor"),
            "supportsCompute" to (hasVulkan || major > 3 || (major == 3 && minor >= 1)),
        )
    }

    private fun readConnectivity(): Map<String, Any> {
        val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = manager.activeNetwork
        val caps = network?.let(manager::getNetworkCapabilities)
        val transports = mutableListOf<String>()
        if (caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true) transports += "wifi"
        if (caps?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true) transports += "cellular"
        if (caps?.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) == true) transports += "ethernet"
        if (caps?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true) transports += "vpn"
        val connected = caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true &&
            caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
        return mapOf(
            "transports" to transports,
            "isConnected" to connected,
            "isMetered" to manager.isActiveNetworkMetered,
            "isConstrained" to (caps?.hasCapability(
                NetworkCapabilities.NET_CAPABILITY_NOT_RESTRICTED,
            ) == false),
            "downstreamKbps" to (caps?.linkDownstreamBandwidthKbps ?: -1),
            "upstreamKbps" to (caps?.linkUpstreamBandwidthKbps ?: -1),
        )
    }

}
