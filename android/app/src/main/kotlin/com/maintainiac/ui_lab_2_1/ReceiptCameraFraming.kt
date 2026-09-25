package com.maintainiac.ui_lab_2_1

import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.camera.core.ImageProxy
import kotlin.math.roundToInt

internal fun ReceiptCameraActivity.applyLiveFraming(framing: LiveReceiptFraming) {
    latestFramingConfidence = framing.confidenceBucket
    latestEdgeCoverage = framing.edgeCoverage
    latestFramingWidthRatio = framing.widthRatio
    latestFramingHeightRatio = framing.heightRatio
    latestPerspectiveReadiness = perspectiveReadinessFor(framing)
    if (!framing.found) {
        latestFramingSignal = "receipt_not_found"
        resetFrameGuideBounds()
        setFrameGuideColor(Color.argb(185, 255, 209, 102))
        if (receiptFullyVisibleWarningEnabled) {
            updateStableFramingGuidance(
                signal = "receipt_not_found",
                message = "Place the receipt inside the frame. Manual capture still works.",
            )
        }
        return
    }
    if (!hasUsableLiveFramingBounds(framing)) {
        latestFramingSignal = "receipt_bounds_invalid"
        resetFrameGuideBounds()
        setFrameGuideColor(Color.argb(185, 255, 209, 102))
        if (receiptFullyVisibleWarningEnabled) {
            updateStableFramingGuidance(
                signal = "receipt_bounds_invalid",
                message = "Receipt edges need another look. Keep the paper flat and visible.",
            )
        }
        return
    }
    updateFrameGuideBounds(framing)
    if (framing.widthRatio < 0.42 || framing.heightRatio < 0.36) {
        latestFramingSignal = "move_closer"
        setFrameGuideColor(Color.argb(210, 255, 209, 102))
        if (textTooSmallWarningEnabled || tooFarTooCloseWarningEnabled) {
            updateStableFramingGuidance(
                signal = "move_closer",
                message = "Move closer if text looks small; tap shutter if readable.",
            )
        }
        return
    }
    if (framing.touchesEdge) {
        latestFramingSignal = "possibly_cut_off"
        setFrameGuideColor(Color.argb(220, 255, 176, 32))
        if (receiptFullyVisibleWarningEnabled) {
            updateStableFramingGuidance(
                signal = "possibly_cut_off",
                message = "Receipt may be cut off. Leave paper edge visible, or tap shutter if readable.",
            )
        }
        return
    }
    latestFramingSignal = "framing_ok"
    setFrameGuideColor(Color.argb(205, 142, 246, 164))
    if (receiptFullyVisibleWarningEnabled) {
        updateStableFramingGuidance(
            signal = "framing_${framing.confidenceBucket}",
            message = framingGuidanceCopy(framing.confidenceBucket),
        )
    }
}

internal fun ReceiptCameraActivity.updateStableFramingGuidance(
    signal: String,
    message: String,
) {
    if (stableFramingGuidanceSignal(signal)) {
        guidance.text = message
    }
}

internal fun ReceiptCameraActivity.stableFramingGuidanceSignal(signal: String): Boolean {
    if (framingGuidanceCandidateSignal == signal) {
        framingGuidanceCandidateCount += 1
    } else {
        framingGuidanceCandidateSignal = signal
        framingGuidanceCandidateCount = 1
    }
    return framingGuidanceCandidateCount >= 2
}

internal fun ReceiptCameraActivity.perspectiveReadinessFor(
    framing: LiveReceiptFraming,
): String {
    if (!perspectiveCorrectionEnabled) return "perspective_skipped_setting_off"
    if (!edgeDetectionEnabled) return "perspective_skipped_edge_detection_off"
    if (!framing.found) return "perspective_skipped_no_receipt_bounds"
    if (!hasUsableLiveFramingBounds(framing)) return "perspective_skipped_invalid_bounds"
    if (framing.widthRatio < 0.34 || framing.heightRatio < 0.34) {
        return "perspective_skipped_bounds_too_small"
    }
    if (framing.touchesEdge) return "perspective_skipped_cut_off_risk"
    if (
        framing.confidenceBucket != "strong_edges" &&
        framing.confidenceBucket != "usable_edges"
    ) {
        return "perspective_skipped_weak_edges"
    }
    return "perspective_ready_safe_bounds"
}

internal fun ReceiptCameraActivity.framingGuidanceCopy(
    confidenceBucket: String,
): String {
    return when (confidenceBucket) {
        "strong_edges" -> "Receipt edges found. Hold steady and capture when ready."
        "usable_edges" -> "Receipt edges look usable. Tap the shutter if the text is clear."
        "weak_edges" -> "Receipt edges are weak. Leave paper edges visible if you can."
        else -> "Receipt edge hint found. Make sure all text is readable."
    }
}

internal fun ReceiptCameraActivity.estimateReceiptFraming(
    image: ImageProxy,
): LiveReceiptFraming {
    val plane = image.planes.firstOrNull() ?: return LiveReceiptFraming()
    val buffer = plane.buffer.duplicate()
    val width = image.width
    val height = image.height
    val rowStride = plane.rowStride
    val pixelStride = plane.pixelStride.coerceAtLeast(1)
    var left = width
    var top = height
    var right = 0
    var bottom = 0
    var hits = 0
    var totalSamples = 0
    val rowStep = maxOf(2, height / 72)
    val colStep = maxOf(2, width / 72)
    var y = 0
    while (y < height) {
        var x = 0
        while (x < width) {
            totalSamples += 1
            val index = y * rowStride + x * pixelStride
            if (index >= 0 && index < buffer.limit()) {
                val luma = buffer.get(index).toInt() and 0xFF
                if (luma > 188 || luma < 82) {
                    hits += 1
                    if (x < left) left = x
                    if (x > right) right = x
                    if (y < top) top = y
                    if (y > bottom) bottom = y
                }
            }
            x += colStep
        }
        y += rowStep
    }
    if (hits < 40 || right <= left || bottom <= top) return LiveReceiptFraming()
    val widthRatio = (right - left).toDouble() / width.toDouble()
    val heightRatio = (bottom - top).toDouble() / height.toDouble()
    val edgeCoverage = (widthRatio * heightRatio).coerceIn(0.0, 1.0)
    val hitDensity = if (totalSamples <= 0) 0.0 else hits.toDouble() / totalSamples.toDouble()
    val confidenceScore = ((edgeCoverage * 0.72) + (hitDensity * 0.28)).coerceIn(0.0, 1.0)
    val touchesEdge = left < width * .035 ||
        top < height * .035 ||
        right > width * .965 ||
        bottom > height * .965
    if (looksLikeFullDisplayFalsePositive(widthRatio, heightRatio, touchesEdge)) {
        return LiveReceiptFraming()
    }
    return LiveReceiptFraming(
        found = true,
        widthRatio = widthRatio,
        heightRatio = heightRatio,
        edgeCoverage = edgeCoverage,
        confidenceBucket = framingConfidenceBucket(confidenceScore),
        touchesEdge = touchesEdge,
        leftRatio = left.toDouble() / width.toDouble(),
        topRatio = top.toDouble() / height.toDouble(),
        rightRatio = right.toDouble() / width.toDouble(),
        bottomRatio = bottom.toDouble() / height.toDouble(),
    )
}

internal fun ReceiptCameraActivity.framingConfidenceBucket(score: Double): String {
    return when {
        score >= 0.72 -> "strong_edges"
        score >= 0.48 -> "usable_edges"
        score >= 0.28 -> "weak_edges"
        else -> "edge_hint_only"
    }
}

internal fun ReceiptCameraActivity.looksLikeFullDisplayFalsePositive(
    widthRatio: Double,
    heightRatio: Double,
    touchesEdge: Boolean,
): Boolean {
    if (!touchesEdge) return false
    if (!widthRatio.isFinite() || !heightRatio.isFinite()) return false
    val nearFullDisplay = widthRatio >= 0.78 && heightRatio >= 0.78
    val tallScreenLikePanel = heightRatio >= 0.88 && widthRatio in 0.46..0.82
    return nearFullDisplay || tallScreenLikePanel
}

internal fun ReceiptCameraActivity.hasUsableLiveFramingBounds(
    framing: LiveReceiptFraming,
): Boolean {
    if (!framing.found) return false
    val ratios = listOf(
        framing.widthRatio,
        framing.heightRatio,
        framing.edgeCoverage,
        framing.leftRatio,
        framing.topRatio,
        framing.rightRatio,
        framing.bottomRatio,
    )
    if (ratios.any { !it.isFinite() }) return false
    return framing.widthRatio > 0.0 &&
        framing.heightRatio > 0.0 &&
        framing.edgeCoverage in 0.0..1.0 &&
        framing.leftRatio in 0.0..1.0 &&
        framing.topRatio in 0.0..1.0 &&
        framing.rightRatio in 0.0..1.0 &&
        framing.bottomRatio in 0.0..1.0 &&
        framing.leftRatio < framing.rightRatio &&
        framing.topRatio < framing.bottomRatio
}

internal fun ReceiptCameraActivity.hasReliableLiveReceiptTargetForQualityWarnings(
    framing: LiveReceiptFraming,
): Boolean {
    if (!edgeDetectionEnabled) return false
    if (!framing.found || !hasUsableLiveFramingBounds(framing)) return false
    if (framing.touchesEdge) return false
    if (framing.widthRatio < 0.42 || framing.heightRatio < 0.36) return false
    return framing.confidenceBucket == "strong_edges" ||
        framing.confidenceBucket == "usable_edges"
}

internal fun ReceiptCameraActivity.setFrameGuideColor(color: Int) {
    if (!hasInitializedReceiptCameraField { receiptFrameGuide }) return
    receiptFrameGuide.background = frameGuideDrawable(color)
}

internal fun ReceiptCameraActivity.resetFrameGuideBounds() {
    if (!hasInitializedReceiptCameraField { receiptFrameGuide }) return
    receiptFrameGuide.layoutParams = FrameLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.MATCH_PARENT,
        Gravity.CENTER,
    ).apply {
        leftMargin = dp(16)
        rightMargin = dp(16)
        topMargin = dp(60)
        bottomMargin = dp(88)
    }
}

internal fun ReceiptCameraActivity.updateFrameGuideBounds(
    framing: LiveReceiptFraming,
) {
    if (!hasInitializedReceiptCameraField { receiptFrameGuide }) return
    val previewWidth = previewView.width
    val previewHeight = previewView.height
    if (previewWidth <= 0 || previewHeight <= 0) return
    val minLeft = dp(10)
    val minTop = dp(56)
    val maxRight = previewWidth - dp(10)
    val maxBottom = previewHeight - dp(84)
    val left = (framing.leftRatio * previewWidth).roundToInt()
        .coerceIn(minLeft, maxRight)
    val top = (framing.topRatio * previewHeight).roundToInt()
        .coerceIn(minTop, maxBottom)
    val right = (framing.rightRatio * previewWidth).roundToInt()
        .coerceIn(left + dp(42), maxRight)
    val bottom = (framing.bottomRatio * previewHeight).roundToInt()
        .coerceIn(top + dp(72), maxBottom)
    receiptFrameGuide.layoutParams = FrameLayout.LayoutParams(
        right - left,
        bottom - top,
        Gravity.TOP or Gravity.START,
    ).apply {
        leftMargin = left
        topMargin = top
    }
}

internal fun ReceiptCameraActivity.frameGuideDrawable(color: Int): GradientDrawable {
    return GradientDrawable().apply {
        setColor(Color.TRANSPARENT)
        setStroke(dp(2), color)
        cornerRadius = dp(14).toFloat()
    }
}
