package com.maintainiac.ui_lab_2_1

import android.util.Range

internal fun ReceiptCameraActivity.prepareExposureBeforeCapture(onReady: () -> Unit) {
    lastPreCaptureExposureSkipReason = "none"
    lastPreCaptureExposureAbortReason = "none"
    if (!autoExposureAssistEnabled) {
        lastPreCaptureExposureDecision = "assist_off"
        lastPreCaptureExposureSkipReason = "assist_off"
        onReady()
        return
    }
    if (userExposureOverride) {
        lastPreCaptureExposureDecision = "manual_override"
        lastPreCaptureExposureSkipReason = "manual_override"
        onReady()
        return
    }
    val activeCamera = camera
    if (
        activeCamera == null ||
        !latestFrameBrightness.isFinite() ||
        latestFrameBrightness < 0.0
    ) {
        lastPreCaptureExposureDecision = "brightness_unknown"
        lastPreCaptureExposureSkipReason = "brightness_unknown"
        onReady()
        return
    }
    val exposureState = activeCamera.cameraInfo.exposureState
    val range = effectiveExposureRange(exposureState.exposureCompensationRange)
    if (range.lower == range.upper) {
        lastPreCaptureExposureDecision = "not_supported"
        lastPreCaptureExposureSkipReason = "not_supported"
        onReady()
        return
    }
    val current = exposureState.exposureCompensationIndex
    val target = preCaptureExposureTarget(current, range)
    if (target == current) {
        lastPreCaptureExposureDecision = preCaptureExposureSkipDecision()
        lastPreCaptureExposureSkipReason = lastPreCaptureExposureDecision
        onReady()
        return
    }
    lastPreCaptureExposureDecision = if (target > current) {
        "brightening_before_capture"
    } else {
        "dimming_before_capture"
    }
    preCaptureExposureAdjustmentCount += 1
    lastPreCaptureExposureTargetIndex = target
    lastAutoExposureIndex = target
    val future = activeCamera.cameraControl.setExposureCompensationIndex(target)
    exposureSlider.progress = target - range.lower
    future.addListener(
        {
            if (!isCameraSurfaceActive() || closeResultDelivered) {
                captureInFlight = false
                activeCaptureAttemptId = 0L
                pendingCloseAfterCapture = false
                captureBlockedSurfaceInactiveCount += 1
                lastCaptureBlockReason = "camera_surface_inactive_during_exposure_prepare"
                if (hasInitializedReceiptCameraField { shutterButton }) {
                    shutterButton.isEnabled = true
                }
                reportManualCaptureBlocked(lastCaptureTrigger, "camera_surface_inactive")
                preCaptureExposureAbortCount += 1
                lastPreCaptureExposureDecision = "aborted_camera_closing"
                lastPreCaptureExposureAbortReason = if (closeResultDelivered) {
                    "result_already_delivered"
                } else {
                    "camera_surface_inactive"
                }
                return@addListener
            }
            runCatching { future.get() }
                .onSuccess {
                    preCaptureExposureAdjustmentConfirmedCount += 1
                    lastPreCaptureExposureDecision = if (target > current) {
                        "brightened_before_capture"
                    } else {
                        "dimmed_before_capture"
                    }
                }
                .onFailure { lastPreCaptureExposureDecision = "adjustment_not_confirmed" }
            onReady()
        },
        mainExecutor(),
    )
}

internal fun ReceiptCameraActivity.preCaptureExposureTarget(current: Int, range: Range<Int>): Int {
    return when {
        // Last-second prep should rescue genuinely dark receipts, not fight native AE.
        latestFrameBrightness <= 55.0 -> (current + 4).coerceAtMost(range.upper)
        latestFrameBrightness <= 70.0 -> (current + 3).coerceAtMost(range.upper)
        // Let the device's exposure system keep normal paper at its native baseline.
        // A last-second lift can slow the shutter and soften small thermal print.
        latestFrameBrightness <= 104.0 -> (current + 1).coerceAtMost(range.upper)
        // Bright receipts are safer at the native camera baseline; glare is handled by
        // live assist and user guidance so manual shutter stays predictable.
        latestFrameBrightness >= 238.0 -> current
        else -> current
    }
}

internal fun ReceiptCameraActivity.preCaptureExposureSkipDecision(): String {
    return when {
        latestFrameBrightness in 104.0..238.0 -> "native_auto_exposure_kept_for_capture"
        latestFrameBrightness > 238.0 -> "pre_capture_dimming_skipped_native_auto"
        else -> "already_at_limit"
    }
}
