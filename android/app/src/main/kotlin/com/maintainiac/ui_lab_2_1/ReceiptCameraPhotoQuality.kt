package com.maintainiac.ui_lab_2_1

import android.app.Activity
import android.content.Intent
import android.graphics.BitmapFactory
import androidx.lifecycle.Lifecycle
import java.io.File


internal fun ReceiptCameraActivity.finishPendingCloseAfterCaptureFailure() {
    pendingCloseAfterCapture = false
    if (capturedPhotoPaths.isNotEmpty()) {
        guidance.text =
            "That last photo did not save. Opening review with the receipt photos already captured."
        finishWithCapturedPhotos(closeReason = "back_capture_failed_returned_existing_sections")
        return
    }
    cancelWithoutCapturedPhoto("back_capture_failed_cancel")
}

internal fun ReceiptCameraActivity.isCameraSurfaceActive(): Boolean {
    return !isFinishing &&
        !isDestroyed &&
        lifecycleRegistry.currentState != Lifecycle.State.DESTROYED
}

internal fun ReceiptCameraActivity.cancelWithoutCapturedPhoto(reason: String) {
    if (closeResultDelivered) return
    closingCamera = true
    latestAutoCaptureStatus = "closing"
    closeAction = reason
    closeNoPhotoCancelCount += 1
    closeResultDelivered = true
    val data = Intent().apply {
        putExtra(ReceiptCameraActivity.extraCloseAction, reason)
    }
    setResult(Activity.RESULT_CANCELED, data)
    finish()
}

internal fun ReceiptCameraActivity.cancelForCameraStartupFailure(reason: String) {
    if (closeResultDelivered) return
    closingCamera = true
    closeAction = "camera_start_$reason"
    closeResultDelivered = true
    val data = Intent().apply {
        putExtra(ReceiptCameraActivity.extraCloseAction, closeAction)
        putExtra(ReceiptCameraActivity.extraCameraFailureReason, reason)
    }
    setResult(Activity.RESULT_CANCELED, data)
    finish()
}

internal fun ReceiptCameraActivity.recordCapturedPhotoQuality(file: File) {
    latestCapturedByteBucket = byteSizeBucket(file.length())
    val options = BitmapFactory.Options().apply {
        inJustDecodeBounds = true
    }
    BitmapFactory.decodeFile(file.absolutePath, options)
    latestCapturedPhotoWidth = options.outWidth.coerceAtLeast(0)
    latestCapturedPhotoHeight = options.outHeight.coerceAtLeast(0)
    latestCapturedMegapixelBucket = megapixelBucket(
        latestCapturedPhotoWidth,
        latestCapturedPhotoHeight,
    )
    val sampleOptions = BitmapFactory.Options().apply {
        inSampleSize = capturedPhotoSampleSize(
            latestCapturedPhotoWidth,
            latestCapturedPhotoHeight,
        )
    }
    val bitmap = BitmapFactory.decodeFile(file.absolutePath, sampleOptions)
    if (bitmap == null) {
        latestCapturedAverageLuma = -1.0
        latestCapturedEdgeScore = -1.0
        latestCapturedTopLuma = -1.0
        latestCapturedMiddleLuma = -1.0
        latestCapturedBottomLuma = -1.0
        latestCapturedBottomEdgeScore = -1.0
        latestCapturedBottomTopLumaDelta = -10000.0
        latestCapturedBottomTopLumaDeltaBucket = "unknown"
        latestCapturedVerticalQualitySignal = "unknown"
        latestCapturedBrightnessBucket = "unknown"
        latestCapturedSharpnessBucket = "unknown"
        latestCapturedQualitySignal = "unknown"
        latestCapturedLiveToSavedLumaDelta = -10000.0
        latestCapturedLiveToSavedLumaDeltaBucket = "unknown"
        latestCapturedPreviewParitySignal = "unknown"
        latestCapturedExposureMismatch = "unknown"
        capturedLightingEvidence = "unknown"
        return
    }
    try {
        val sample = sampleCapturedBitmapQuality(bitmap)
        latestCapturedAverageLuma = roundedDiagnostic(sample.averageLuma)
        latestCapturedEdgeScore = roundedDiagnostic(sample.edgeScore)
        latestCapturedTopLuma = roundedDiagnostic(sample.topLuma)
        latestCapturedMiddleLuma = roundedDiagnostic(sample.middleLuma)
        latestCapturedBottomLuma = roundedDiagnostic(sample.bottomLuma)
        latestCapturedBottomEdgeScore = roundedDiagnostic(sample.bottomEdgeScore)
        latestCapturedBottomTopLumaDelta = capturedBottomTopLumaDelta(sample)
        latestCapturedBottomTopLumaDeltaBucket =
            capturedBottomTopLumaDeltaBucket(latestCapturedBottomTopLumaDelta)
        latestCapturedVerticalQualitySignal = capturedVerticalQualitySignal(sample)
        latestCapturedBrightnessBucket = capturedBrightnessBucket(sample.averageLuma)
        latestCapturedSharpnessBucket = capturedSharpnessBucket(sample.edgeScore)
        latestCapturedQualitySignal = capturedQualitySignal(
            latestCapturedBrightnessBucket,
            latestCapturedSharpnessBucket,
        )
        latestCapturedLiveToSavedLumaDelta = capturedLiveToSavedLumaDelta(
            latestCaptureLiveBrightnessAtShutter,
            sample.averageLuma,
        )
        latestCapturedLiveToSavedLumaDeltaBucket =
            capturedLiveToSavedLumaDeltaBucket(latestCapturedLiveToSavedLumaDelta)
        latestCapturedPreviewParitySignal = capturedPreviewParitySignal(
            latestCapturedLiveToSavedLumaDeltaBucket,
            latestCapturedBrightnessBucket,
        )
        latestCapturedExposureMismatch = capturedExposureMismatch(
            latestCaptureLiveBrightnessAtShutter,
            latestCapturedBrightnessBucket,
            lastPreCaptureExposureDecision,
        )
        capturedLightingEvidence = capturedLightingEvidence(
            latestCapturedBrightnessBucket,
            latestCapturedVerticalQualitySignal,
            latestCapturedBottomTopLumaDeltaBucket,
            latestCapturedExposureMismatch,
        )
    } finally {
        bitmap.recycle()
    }
}
