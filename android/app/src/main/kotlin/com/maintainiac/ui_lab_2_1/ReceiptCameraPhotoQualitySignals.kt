package com.maintainiac.ui_lab_2_1

internal fun ReceiptCameraActivity.capturedLiveToSavedLumaDelta(
    liveBrightnessAtShutter: Double,
    capturedAverageLuma: Double,
): Double {
    if (
        !liveBrightnessAtShutter.isFinite() ||
        !capturedAverageLuma.isFinite() ||
        liveBrightnessAtShutter < 0.0 ||
        capturedAverageLuma < 0.0
    ) return -10000.0
    return roundedDiagnostic(capturedAverageLuma - liveBrightnessAtShutter)
}

internal fun ReceiptCameraActivity.capturedLiveToSavedLumaDeltaBucket(delta: Double): String {
    return when {
        !delta.isFinite() || delta <= -9999.0 -> "unknown"
        delta <= -58.0 -> "saved_much_darker_than_preview"
        delta <= -32.0 -> "saved_darker_than_preview"
        delta >= 58.0 -> "saved_much_brighter_than_preview"
        delta >= 32.0 -> "saved_brighter_than_preview"
        else -> "saved_matches_preview"
    }
}

internal fun ReceiptCameraActivity.capturedPreviewParitySignal(
    deltaBucket: String,
    capturedBrightnessBucket: String,
): String {
    if (deltaBucket == "unknown" || capturedBrightnessBucket == "unknown") return "unknown"
    if (
        deltaBucket == "saved_much_darker_than_preview" ||
        (
            deltaBucket == "saved_darker_than_preview" &&
                (
                    capturedBrightnessBucket == "captured_dim" ||
                        capturedBrightnessBucket == "captured_too_dark"
                    )
            )
    ) {
        return "saved_photo_darker_than_preview_review_needed"
    }
    if (deltaBucket == "saved_darker_than_preview") {
        return "saved_photo_darker_than_preview_watch"
    }
    if (
        deltaBucket == "saved_much_brighter_than_preview" ||
        (
            deltaBucket == "saved_brighter_than_preview" &&
                capturedBrightnessBucket == "captured_glare_risk"
            )
    ) {
        return "saved_photo_brighter_than_preview_review_needed"
    }
    if (deltaBucket == "saved_brighter_than_preview") {
        return "saved_photo_brighter_than_preview_watch"
    }
    return "saved_photo_matches_preview"
}

internal fun ReceiptCameraActivity.capturedExposureMismatch(
    liveBrightness: Double,
    capturedBrightnessBucket: String,
    preCaptureDecision: String,
): String {
    if (!liveBrightness.isFinite() ||
        liveBrightness < 0.0 ||
        capturedBrightnessBucket == "unknown") return "unknown"
    val liveBucket = brightnessBucket(liveBrightness)
    if (liveBucket == "unknown") return "unknown"
    val preCaptureAdjusted = preCaptureDecision == "brightened_before_capture" ||
        preCaptureDecision == "brightening_before_capture"
    if (preCaptureAdjusted && capturedBrightnessBucket == "captured_too_dark") {
        return "pre_capture_brightened_still_too_dark"
    }
    if (preCaptureAdjusted && capturedBrightnessBucket == "captured_dim") {
        return "pre_capture_brightened_still_dim"
    }
    return when {
        liveBucket == "lighting_ok" && capturedBrightnessBucket == "captured_too_dark" ->
            "live_ok_capture_too_dark"
        liveBucket == "lighting_ok" && capturedBrightnessBucket == "captured_dim" ->
            "live_ok_capture_dim"
        liveBucket == "too_dark_warning" && capturedBrightnessBucket == "captured_readable" ->
            "live_dark_capture_readable"
        liveBucket == "dark_assisted" && capturedBrightnessBucket == "captured_readable" ->
            "live_dark_capture_readable"
        liveBucket == "glare_warning" && capturedBrightnessBucket == "captured_readable" ->
            "live_bright_capture_readable"
        liveBucket == "bright_receipt_ok" && capturedBrightnessBucket == "captured_readable" ->
            "live_bright_capture_readable"
        else -> "live_capture_aligned"
    }
}

internal fun ReceiptCameraActivity.capturedLightingEvidence(
    brightnessBucket: String,
    verticalQualitySignal: String,
    bottomTopDeltaBucket: String,
    exposureMismatch: String,
): String {
    if (brightnessBucket == "unknown" || exposureMismatch == "unknown") return "unknown"
    if (exposureMismatch == "pre_capture_brightened_still_too_dark" ||
        brightnessBucket == "captured_too_dark") {
        return "capture_too_dark"
    }
    if (exposureMismatch == "pre_capture_brightened_still_dim" ||
        exposureMismatch == "live_ok_capture_dim" ||
        brightnessBucket == "captured_dim") {
        return "capture_dim_review_needed"
    }
    if (verticalQualitySignal == "bottom_too_dark" ||
        verticalQualitySignal == "bottom_darker_than_upper" ||
        bottomTopDeltaBucket == "bottom_darker_than_top" ||
        bottomTopDeltaBucket == "bottom_much_darker_than_top") {
        return "bottom_lighting_risk"
    }
    if (brightnessBucket == "captured_glare_risk") return "capture_glare_risk"
    return "lighting_readable"
}

internal fun ReceiptCameraActivity.byteSizeBucket(bytes: Long): String {
    return when {
        bytes <= 0L -> "unknown"
        bytes < 350_000L -> "tiny_under_350kb"
        bytes < 1_000_000L -> "small_under_1mb"
        bytes < 3_000_000L -> "normal_1mb_to_3mb"
        bytes < 8_000_000L -> "large_3mb_to_8mb"
        else -> "very_large_over_8mb"
    }
}

internal fun ReceiptCameraActivity.megapixelBucket(width: Int, height: Int): String {
    if (width <= 0 || height <= 0) return "unknown"
    val megapixels = (width.toDouble() * height.toDouble()) / 1_000_000.0
    return when {
        megapixels < 4.0 -> "low_under_4mp"
        megapixels < 9.0 -> "medium_4mp_to_9mp"
        megapixels < 18.0 -> "high_9mp_to_18mp"
        megapixels < 40.0 -> "very_high_18mp_to_40mp"
        else -> "extreme_over_40mp"
    }
}
