package com.maintainiac.ui_lab_2_1

internal fun ReceiptCameraActivity.configureExposureControls() {
    val activeCamera = camera ?: return
    val exposureState = activeCamera.cameraInfo.exposureState
    val range = effectiveExposureRange(exposureState.exposureCompensationRange)
    if (!exposureSliderEnabled || range.lower == range.upper) {
        exposureSlider.isEnabled = false
        exposureSlider.alpha = 0.45f
    } else {
        exposureSlider.max = range.upper - range.lower
        exposureSlider.progress =
            clampExposureIndex(exposureState.exposureCompensationIndex, range) - range.lower
        exposureSlider.isEnabled = true
        exposureSlider.alpha = 1f
    }
    if (!exposureResetEnabled || range.lower == range.upper) {
        exposureResetButton.isEnabled = false
        exposureResetButton.alpha = 0.45f
        return
    }
    exposureResetButton.isEnabled = true
    exposureResetButton.alpha = 1f
}

internal fun ReceiptCameraActivity.toggleExposureControls() {
    if (!exposureSliderEnabled || !exposureSlider.isEnabled) {
        guidance.text = receiptCameraText(
            "Brightness adjustment is not available on this camera.",
            "El ajuste de brillo no está disponible en esta cámara.",
        )
        return
    }
    val visible = exposurePanel.visibility == android.view.View.VISIBLE
    exposurePanel.visibility = if (visible) android.view.View.GONE else android.view.View.VISIBLE
    guidance.text = if (visible) {
        guidanceText()
    } else {
        receiptCameraText(
            "Adjust Brightness. The phone still controls autofocus and exposure timing.",
            "Ajuste el brillo. El teléfono aún controla el enfoque automático y el tiempo de exposición.",
        )
    }
}

internal fun ReceiptCameraActivity.setExposureFromSlider(progress: Int) {
    val activeCamera = camera ?: return
    if (!exposureSliderEnabled) return
    val range = effectiveExposureRange(activeCamera.cameraInfo.exposureState.exposureCompensationRange)
    val index = range.lower + progress
    userExposureOverride = true
    manualExposureChangeCount += 1
    activeCamera.cameraControl.setExposureCompensationIndex(index)
    guidance.text = if (index == 0) {
        receiptCameraText("Brightness reset.", "Brillo restablecido.")
    } else {
        "${receiptCameraText("Brightness", "Brillo")} ${if (index > 0) "+" else ""}$index"
    }
}

internal fun ReceiptCameraActivity.resetExposure() {
    val activeCamera = camera ?: return
    if (!exposureResetEnabled) return
    val range = effectiveExposureRange(activeCamera.cameraInfo.exposureState.exposureCompensationRange)
    val resetIndex = clampExposureIndex(0, range)
    exposureSlider.progress = resetIndex - range.lower
    activeCamera.cameraControl.setExposureCompensationIndex(resetIndex)
    userExposureOverride = false
    manualExposureChangeCount += 1
    guidance.text = receiptCameraText("Brightness reset.", "Brillo restablecido.")
}

internal fun ReceiptCameraActivity.autoAdjustExposureForLiveFrame(
    brightness: Double,
    nowMs: Long,
    framing: LiveReceiptFraming?,
) {
    lastAutoExposureBrightnessBucket = brightnessBucket(brightness)
    if (!brightness.isFinite() || brightness < 0.0) {
        lastAutoExposureDecision = "brightness_unknown"
        resetAutoExposureCandidate()
        return
    }
    if (framing == null || !framing.found) {
        when {
            brightness <= 104.0 -> {
                if (!stableAutoExposureCandidate("fallback_brighten", requiredFrames = 4)) return
                autoAdjustExposureForLiveFrame(
                    brighten = true,
                    strongCorrection = brightness <= 70.0,
                    nowMs = nowMs,
                )
            }
            brightness >= 252.0 -> {
                if (!stableAutoExposureCandidate("fallback_dim", requiredFrames = 5)) return
                autoAdjustExposureForLiveFrame(
                    brighten = false,
                    strongCorrection = brightness >= 254.0,
                    nowMs = nowMs,
                )
            }
            else -> {
                lastAutoExposureDecision = "waiting_for_receipt_target"
                resetAutoExposureCandidate()
            }
        }
        return
    }
    when {
        brightness <= 150.0 -> {
            if (!stableAutoExposureCandidate("brighten")) return
            autoAdjustExposureForLiveFrame(
                brighten = true,
                strongCorrection = brightness <= 104.0,
                nowMs = nowMs,
            )
        }
        brightness >= 250.0 -> {
            if (!stableAutoExposureCandidate("dim", requiredFrames = 5)) return
            autoAdjustExposureForLiveFrame(
                brighten = false,
                strongCorrection = brightness >= 254.0,
                nowMs = nowMs,
            )
        }
        else -> {
            lastAutoExposureDecision = "lighting_ok"
            resetAutoExposureCandidate()
        }
    }
}

internal fun ReceiptCameraActivity.stableAutoExposureCandidate(
    candidate: String,
    requiredFrames: Int = 2,
): Boolean {
    if (lastAutoExposureCandidate == candidate) {
        autoExposureCandidateFrameCount += 1
    } else {
        lastAutoExposureCandidate = candidate
        autoExposureCandidateFrameCount = 1
    }
    if (autoExposureCandidateFrameCount < requiredFrames) {
        lastAutoExposureDecision = "stabilizing_$candidate"
        return false
    }
    return true
}

internal fun ReceiptCameraActivity.resetAutoExposureCandidate() {
    lastAutoExposureCandidate = "none"
    autoExposureCandidateFrameCount = 0
}

internal fun ReceiptCameraActivity.autoAdjustExposureForLiveFrame(
    brighten: Boolean,
    strongCorrection: Boolean,
    nowMs: Long,
) {
    if (!autoExposureAssistEnabled) {
        lastAutoExposureDecision = "off"
        return
    }
    if (userExposureOverride) {
        lastAutoExposureDecision = "manual_override"
        return
    }
    if (nowMs - lastAutoExposureAdjustmentAt < 900L) {
        lastAutoExposureDecision = "cooling_down"
        return
    }
    val activeCamera = camera ?: return
    val exposureState = activeCamera.cameraInfo.exposureState
    val range = effectiveExposureRange(exposureState.exposureCompensationRange)
    if (range.lower == range.upper) {
        lastAutoExposureDecision = "not_supported"
        return
    }
    val current = exposureState.exposureCompensationIndex
    lastAutoExposureIndex = current
    val step = if (strongCorrection) 2 else 1
    val target = if (brighten) {
        (current + step).coerceAtMost(range.upper)
    } else {
        (current - step).coerceAtLeast(range.lower)
    }
    if (target == current) {
        lastAutoExposureDecision = if (brighten) {
            "already_at_brightest"
        } else {
            "already_at_dimmest"
        }
        return
    }
    activeCamera.cameraControl.setExposureCompensationIndex(target)
    exposureSlider.progress = target - range.lower
    autoExposureAdjustmentCount += 1
    lastAutoExposureAdjustmentAt = nowMs
    lastAutoExposureIndex = target
    resetAutoExposureCandidate()
    lastAutoExposureDecision = if (brighten) {
        if (strongCorrection) "brightened_strong" else "brightened"
    } else {
        if (strongCorrection) "dimmed_strong" else "dimmed"
    }
}

internal fun ReceiptCameraActivity.brightnessBucket(brightness: Double): String {
    return when {
        !brightness.isFinite() || brightness < 0.0 -> "unknown"
        brightness <= 70.0 -> "too_dark_warning"
        brightness <= 138.0 -> "dark_assisted"
        brightness >= 246.0 -> "glare_warning"
        brightness >= 232.0 -> "bright_receipt_ok"
        else -> "lighting_ok"
    }
}

internal fun ReceiptCameraActivity.exposureAssistStatus(): String {
    val activeCamera = camera ?: return "camera_unavailable"
    val exposureState = activeCamera.cameraInfo.exposureState
    val range = effectiveExposureRange(exposureState.exposureCompensationRange)
    return when {
        range.lower == range.upper -> "not_supported"
        userExposureOverride -> "manual_override"
        !autoExposureAssistEnabled -> "off"
        autoExposureAdjustmentCount > 0 -> "auto_adjusted"
        else -> "ready"
    }
}

internal fun ReceiptCameraActivity.preCaptureExposureOutcome(): String {
    return when (lastPreCaptureExposureDecision) {
        "brightened_before_capture",
        "brightening_before_capture" -> "lifted_for_dim_receipt"
        "dimmed_before_capture",
        "dimming_before_capture" -> "dimmed_for_glare_risk"
        "native_auto_exposure_kept_for_capture",
        "pre_capture_dimming_skipped_native_auto" -> "kept_native_auto"
        "manual_override" -> "manual_brightness_used"
        "assist_off" -> "assist_off"
        "not_supported" -> "not_supported"
        "brightness_unknown" -> "brightness_unknown"
        "adjustment_not_confirmed" -> "adjustment_not_confirmed"
        "already_at_limit" -> "already_at_limit"
        "aborted_camera_closing" -> "aborted_camera_closing"
        else -> "not_evaluated"
    }
}
