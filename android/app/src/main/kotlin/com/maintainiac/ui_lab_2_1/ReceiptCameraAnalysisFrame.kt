package com.maintainiac.ui_lab_2_1

import androidx.camera.core.ImageProxy

internal data class ReceiptLiveFrameSignals(
    val analyzedAtMs: Long,
    val brightness: Double,
    val motionScore: Double,
    val shadowScore: Double,
    val framing: LiveReceiptFraming,
    val edgeDetectionWasEnabled: Boolean,
)

internal fun ReceiptCameraActivity.analyzeLiveFrame(image: ImageProxy) {
    try {
        val now = System.currentTimeMillis()
        if (now - lastLiveAnalysisAt < analysisGapMs) return
        lastLiveAnalysisAt = now
        val lumaSamples = sampleLiveLumaGrid(image)
        val edgeDetectionForFrame = edgeDetectionEnabled
        val signals = ReceiptLiveFrameSignals(
            analyzedAtMs = now,
            brightness = averageLuma(image),
            motionScore = evaluateLiveMotion(lumaSamples),
            shadowScore = estimateShadowScore(lumaSamples),
            framing = if (edgeDetectionForFrame) {
                estimateReceiptFraming(image)
            } else {
                LiveReceiptFraming()
            },
            edgeDetectionWasEnabled = edgeDetectionForFrame,
        )
        mainExecutor().execute { applyAnalyzedLiveFrame(signals) }
    } finally {
        image.close()
    }
}

internal fun ReceiptCameraActivity.applyAnalyzedLiveFrame(signals: ReceiptLiveFrameSignals) {
    if (!isCameraSurfaceActive() || closeResultDelivered) return
    val brightness = signals.brightness
    val motionScore = signals.motionScore
    val shadowScore = signals.shadowScore
    val framing = signals.framing
    val now = signals.analyzedAtMs
    latestFrameBrightness = brightness
    latestMotionScore = motionScore
    latestShadowScore = shadowScore
    val hasReceiptTarget = if (signals.edgeDetectionWasEnabled) {
        applyLiveFraming(framing)
        maybeAutoCapture(framing, brightness, motionScore, now)
        autoAdjustExposureForLiveFrame(brightness, now, framing)
        hasUsableLiveFramingBounds(framing)
    } else {
        applyEdgeDetectionOffAnalysisState(brightness)
        true
    }
    if (!hasReceiptTarget || !hasReliableLiveReceiptTargetForQualityWarnings(framing)) {
        applyWaitingForReceiptTargetState()
        return
    }
    if (!hasExperimentalReceiptQualityWarningsEnabled()) {
        latestMotionSignal = "neutral_workflow_guidance_only"
        latestReadabilitySignal = "neutral_workflow_guidance_only"
        resetExperimentalReceiptQualityCandidate()
        resetExperimentalReceiptQualityGuidanceIfNeeded()
        return
    }
    applyExperimentalReceiptQualitySignals(brightness, motionScore, shadowScore)
}

private fun ReceiptCameraActivity.applyEdgeDetectionOffAnalysisState(brightness: Double) {
    latestFramingSignal = "edge_detection_off"
    latestFramingConfidence = "off"
    latestEdgeCoverage = -1.0
    latestPerspectiveReadiness = "perspective_skipped_edge_detection_off"
    autoCaptureStableFrameCount = 0
    latestAutoCaptureStatus = if (autoCaptureEnabled) "waiting_for_edges" else "off"
    lastAutoExposureBrightnessBucket = brightnessBucket(brightness)
    lastAutoExposureDecision = "waiting_for_receipt_target"
}

private fun ReceiptCameraActivity.applyWaitingForReceiptTargetState() {
    latestMotionSignal = "waiting_for_receipt_target"
    latestReadabilitySignal = "waiting_for_receipt_target"
    resetExperimentalReceiptQualityCandidate()
    resetExperimentalReceiptQualityGuidanceIfNeeded()
}

private fun ReceiptCameraActivity.applyExperimentalReceiptQualitySignals(
    brightness: Double,
    motionScore: Double,
    shadowScore: Double,
) {
    if (!brightness.isFinite() || !motionScore.isFinite() || !shadowScore.isFinite()) {
        latestMotionSignal = "unknown"
        latestReadabilitySignal = "readability_unknown"
        updateExperimentalReceiptQualityGuidance(
            "readability_unknown",
            "Receipt quality needs another look. Keep it flat and readable.",
        )
    } else if (motionBlurWarningEnabled && motionScore > 22.0) {
        latestMotionSignal = "moving_too_much"
        updateExperimentalReceiptQualityGuidance(
            "moving_too_much",
            "Hold steady so the receipt text stays sharp.",
        )
    } else if (lowLightWarningEnabled && brightness in 0.0..58.0) {
        latestReadabilitySignal = "low_light"
        updateExperimentalReceiptQualityGuidance(
            "low_light",
            "Receipt looks dark. Add light or raise Brightness.",
        )
    } else if (glareWarningEnabled && brightness >= 246.0) {
        latestReadabilitySignal = "glare_or_overbright"
        updateExperimentalReceiptQualityGuidance(
            "glare_or_overbright",
            "Receipt is very bright. Tilt it or lower Brightness.",
        )
    } else if (shadowWarningEnabled && shadowScore >= 150.0) {
        latestReadabilitySignal = "shadow_risk"
        updateExperimentalReceiptQualityGuidance(
            "shadow_risk",
            "Receipt has heavy shadows. Move it into even light.",
        )
    } else if (dirtyLensWarningEnabled && brightness in 120.0..235.0 &&
        shadowScore in 0.0..24.0 && motionScore in 0.0..7.0
    ) {
        latestReadabilitySignal = "dirty_lens_or_haze"
        updateExperimentalReceiptQualityGuidance(
            "dirty_lens_or_haze",
            "Lens may be smudged. Wipe it if the receipt looks hazy.",
        )
    } else {
        latestMotionSignal = if (motionScore >= 0) "steady" else "unknown"
        latestReadabilitySignal = "lighting_ok"
        resetExperimentalReceiptQualityCandidate()
        resetExperimentalReceiptQualityGuidanceIfNeeded()
    }
}
