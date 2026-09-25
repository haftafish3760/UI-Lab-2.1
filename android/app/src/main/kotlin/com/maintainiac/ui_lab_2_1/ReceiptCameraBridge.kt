package com.maintainiac.ui_lab_2_1

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.imagepicker.ReceiptCameraHandoff
import java.util.concurrent.Executors

/** Only receipt capture uses this bridge; gallery/PDF/job-site pickers stay separate. */
internal class ReceiptCameraBridge(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null
    private var launch: Intent? = null
    private var requestKey: String? = null
    private var previousGuide: Map<*, *>? = null
    private val recovery = Executors.newSingleThreadExecutor()

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "maintainiac/receipt_camera").setMethodCallHandler { call, result ->
            when (call.method) {
                "capture" -> {
                    if (pending != null) {
                        result.error("camera_busy", "Receipt camera is already open.", null)
                        return@setMethodCallHandler
                    }
                    val key = call.argument<String>("requestKey")
                    val bytes = call.argument<Number>("maxLocalPhotoBytes")?.toLong()
                    val pixels = call.argument<Number>("maxLiveAnalysisPixels")?.toLong()
                    if (key == null || !key.matches(Regex("[A-Za-z0-9_-]{8,160}")) ||
                        bytes == null || bytes !in 1..(12L * 1024 * 1024) ||
                        pixels == null || pixels !in 1..3000000L) {
                        result.error("camera_arguments", "Receipt camera settings are invalid.", null)
                        return@setMethodCallHandler
                    }
                    pending = result
                    requestKey = key
                    previousGuide = call.argument<Map<*, *>>("previousGuide")
                    launch = Intent(activity, ReceiptCameraActivity::class.java).apply {
                        putExtra("receiptRequestKey", key)
                        putExtra("maxLocalPhotoBytes", bytes.toInt())
                        putExtra("maxLiveAnalysisPixels", pixels.toInt())
                        putExtra("maxSectionCount", 1)
                        putExtra("autoCaptureAllowed", false)
                        putExtra("autoCaptureEnabled", false)
                        putExtra("cameraResolutionTier", "balanced")
                        putExtra("analysisGapMs", call.argument<Number>("analysisGapMs")?.toInt() ?: 720)
                        putExtra("uiLocale", activity.resources.configuration.locales[0].toLanguageTag())
                    }
                    if (activity.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                        openCamera()
                    } else {
                        activity.requestPermissions(arrayOf(Manifest.permission.CAMERA), permissionCode)
                    }
                }
                "stop" -> {
                    if (call.argument<String>("requestKey") == requestKey) {
                        if (launch != null) fail("camera_resources", "Capture paused to protect your device.")
                        else ReceiptCameraActivity.stopForResources(requestKey)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openCamera() {
        val intent = launch ?: return
        val guide = previousGuide
        recovery.execute {
            val checked = runCatching { verifiedReceiptGuide(activity.applicationContext, guide) }
            activity.runOnUiThread {
                if (launch !== intent || pending == null) return@runOnUiThread
                if (checked.isFailure) {
                    fail("camera_guide", "The previous receipt photo could not be verified. Your draft is kept.")
                    return@runOnUiThread
                }
                checked.getOrNull()?.let {
                    intent.putExtra("previousSectionGuidePhotoPath", it)
                    intent.putExtra("previousSectionReasonCode", "continue_long_receipt")
                    intent.putExtra("longReceiptMode", true)
                }
                try {
                    activity.startActivityForResult(intent, captureCode)
                    launch = null
                } catch (_: Exception) {
                    fail("camera_unavailable", "Receipt camera could not be opened.")
                }
            }
        }
    }

    fun permissionResult(code: Int, grants: IntArray): Boolean {
        if (code != permissionCode) return false
        if (grants.isNotEmpty() && grants[0] == PackageManager.PERMISSION_GRANTED) openCamera()
        else fail("camera_permission", "Camera permission is required to photograph a receipt.")
        return true
    }

    fun activityResult(code: Int, resultCode: Int, data: Intent?): Boolean {
        if (code != captureCode) return false
        val key = requestKey ?: return true // Process restart uses durable Dart recovery.
        val reply = pending ?: return true
        recovery.execute {
            val outcome = runCatching {
                ReceiptCameraHandoff(activity.applicationContext).use { it.recover(key) }
            }
            activity.runOnUiThread {
                if (pending !== reply) return@runOnUiThread
                val saved = outcome.getOrNull()
                val paths = saved?.get("paths") as? List<*>
                when {
                    outcome.isFailure || paths == null ->
                        fail("camera_recovery", "Your capture is kept. Reopen the receipt draft to recover it.")
                    paths.isNotEmpty() -> {
                        clear()
                        reply.success(mapOf("requestKey" to key, "paths" to paths))
                    }
                    saved["hasCameraCapture"] == true || resultCode == Activity.RESULT_OK ->
                        fail("camera_incomplete", "Capture was interrupted. Your saved draft and files are kept.")
                    data?.hasExtra(ReceiptCameraActivity.extraCameraFailureReason) == true ->
                        fail("camera_unavailable", "Receipt camera could not capture a photo.")
                    else -> {
                        clear()
                        reply.success(mapOf("requestKey" to key, "paths" to emptyList<String>()))
                    }
                }
            }
        }
        return true
    }

    private fun clear() { pending = null; launch = null; requestKey = null; previousGuide = null }
    private fun fail(code: String, message: String) { val reply = pending; clear(); reply?.error(code, message, null) }
    fun dispose() { recovery.shutdown() }

    companion object {
        private const val captureCode = 24071
        private const val permissionCode = 24072
    }
}
