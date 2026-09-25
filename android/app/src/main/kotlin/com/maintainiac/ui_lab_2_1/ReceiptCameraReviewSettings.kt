package com.maintainiac.ui_lab_2_1

import android.app.Activity
import android.content.Intent
import android.os.SystemClock
import android.view.View
import java.io.File
import java.time.Instant
import java.util.UUID
import io.flutter.plugins.imagepicker.ReceiptCameraHandoff


internal fun ReceiptCameraActivity.finishWithCapturedPhotos(closeReason: String = "done_returned_captured_sections") {
    if (closeResultDelivered || handoffInFlight) return
    closingCamera = true
    latestAutoCaptureStatus = "closing"
    if (capturedPhotoPaths.isEmpty()) {
        cancelWithoutCapturedPhoto("done_no_photo_cancel")
        return
    }
    closeAction = closeReason
    if (
        closeReason == "back_returned_captured_sections" ||
        closeReason == "back_capture_failed_returned_existing_sections"
    ) {
        closeReturnedSectionsCount += 1
    }
    latestCaptureToReviewReadyMs = captureElapsedSinceStart()
    latestCaptureLatencyBucket = captureReviewLatencyBucket(latestCaptureToReviewReadyMs)
    val capturedAt = firstCapturedAt ?: Instant.now().toString()
    val originals = capturedPhotoPaths.toList()
    val requestKey = intent.getStringExtra("receiptRequestKey")
    handoffInFlight = true
    guidance.text = "Saving receipt photos for review…"
    shutterButton.isEnabled = false
    receiptPhotoQualityExecutor.execute {
        try {
            val retained = ReceiptCameraHandoff(applicationContext).use {
                it.retain(requestKey, originals)
            }
            runOnUiThread {
                handoffInFlight = false
                if (isFinishing || isDestroyed) return@runOnUiThread
                closeResultDelivered = true
                val data = Intent().apply {
                    putStringArrayListExtra(ReceiptCameraActivity.extraOriginalPhotoPaths, ArrayList(retained))
                    putExtra(ReceiptCameraActivity.extraCapturedAt, capturedAt)
                    putExtra(ReceiptCameraActivity.extraCaptureDiagnostics,
                        nativeCaptureDiagnostics(totalCapturedByteSize, capturedAt))
                }
                setResult(Activity.RESULT_OK, data)
                finish()
            }
        } catch (_: Exception) {
            runOnUiThread {
                handoffInFlight = false
                if (isFinishing || isDestroyed) return@runOnUiThread
                closingCamera = false
                guidance.text = "Your photos are kept, but could not be prepared for review. Tap Review Photos to retry."
                updateDoneButton()
            }
        }
    }
}

internal fun ReceiptCameraActivity.updateDoneButton() {
    val count = capturedPhotoPaths.size
    val title = when (count) {
        0 -> receiptCameraText("Review Photos", "Revisar fotos")
        1 -> receiptCameraText("Review Photo", "Revisar foto")
        else -> "${receiptCameraText("Review Photos", "Revisar fotos")} ($count)"
    }
    if (hasInitializedReceiptCameraField { addPhotoButton }) {
        addPhotoButton.visibility = if (
            capturedPhotoPaths.isEmpty() ||
            !longReceiptMode ||
            capturedPhotoPaths.size >= maxSectionCount
        ) {
            View.GONE
        } else {
            View.VISIBLE
        }
        addPhotoButton.isEnabled = addPhotoButton.visibility == View.VISIBLE
        addPhotoButton.text = addSectionButtonTitle()
        addPhotoButton.contentDescription = addSectionButtonAccessibilityLabel()
    }
    if (hasInitializedReceiptCameraField { shutterButton }) {
        shutterButton.contentDescription = receiptCameraText("Take receipt photo", "Tomar foto del recibo")
    }
    if (hasInitializedReceiptCameraField { bottomReviewButton }) {
        bottomReviewButton.visibility = if (capturedPhotoPaths.isEmpty()) {
            View.GONE
        } else {
            View.VISIBLE
        }
        bottomReviewButton.isEnabled = capturedPhotoPaths.isNotEmpty()
        bottomReviewButton.text = title
        bottomReviewButton.contentDescription =
            receiptCameraText(
                "Review captured receipt photos in Maintainiac",
                "Revisar las fotos del recibo en Maintainiac",
            )
    }
    updateSettingsStatusStrip()
}

internal fun ReceiptCameraActivity.captureElapsedSinceStart(): Long {
    if (latestCaptureStartedElapsedMs <= 0L) return -1L
    return (SystemClock.elapsedRealtime() - latestCaptureStartedElapsedMs).coerceAtLeast(0L)
}

internal fun ReceiptCameraActivity.captureLatencyBucket(milliseconds: Long): String {
    return when {
        milliseconds < 0L -> "unknown"
        milliseconds <= 450L -> "save_fast_under_450ms"
        milliseconds <= 900L -> "save_good_under_900ms"
        milliseconds <= 1600L -> "save_review_under_1600ms"
        milliseconds <= 2800L -> "save_slow_under_2800ms"
        else -> "save_very_slow_over_2800ms"
    }
}

internal fun ReceiptCameraActivity.captureReviewLatencyBucket(milliseconds: Long): String {
    return when {
        milliseconds < 0L -> latestCaptureLatencyBucket
        milliseconds <= 700L -> "review_fast_under_700ms"
        milliseconds <= 1200L -> "review_good_under_1200ms"
        milliseconds <= 2200L -> "review_watch_under_2200ms"
        milliseconds <= 3800L -> "review_slow_under_3800ms"
        else -> "review_very_slow_over_3800ms"
    }
}

internal fun ReceiptCameraActivity.toggleTorch() {
    val cameraControl = camera?.cameraControl ?: return
    torchOn = !torchOn
    cameraControl.enableTorch(torchOn)
    torchButton.contentDescription = if (torchOn) "Turn light off" else "Turn light on"
}

internal fun ReceiptCameraActivity.newReceiptCaptureFile(): File {
    val directory = File(filesDir, "receipt_camera").apply {
        check(isDirectory || mkdirs()) { "Receipt storage is unavailable." }
    }
    val destination = File(directory, "receipt_${System.currentTimeMillis()}_${UUID.randomUUID()}.jpg")
    ReceiptCameraHandoff(applicationContext).use {
        it.plan(intent.getStringExtra("receiptRequestKey"), destination.absolutePath)
    }
    return destination
}
