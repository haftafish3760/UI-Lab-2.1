package com.maintainiac.ui_lab_2_1

import android.graphics.Bitmap
import android.graphics.Color
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.round

internal fun ReceiptCameraActivity.capturedPhotoSampleSize(width: Int, height: Int): Int {
    val maxSide = max(width, height)
    if (maxSide <= 640) return 1
    var sample = 1
    while (maxSide / sample > 640) sample *= 2
    return sample
}

internal data class CapturedPhotoQualitySample(
    val averageLuma: Double,
    val edgeScore: Double,
    val topLuma: Double,
    val middleLuma: Double,
    val bottomLuma: Double,
    val bottomEdgeScore: Double,
)

internal fun ReceiptCameraActivity.sampleCapturedBitmapQuality(bitmap: Bitmap): CapturedPhotoQualitySample {
    val width = bitmap.width
    val height = bitmap.height
    if (width <= 1 || height <= 1) {
        return CapturedPhotoQualitySample(-1.0, -1.0, -1.0, -1.0, -1.0, -1.0)
    }
    val strideX = max(1, width / 96)
    val strideY = max(1, height / 128)
    var count = 0
    var lumaTotal = 0.0
    var edgeTotal = 0.0
    var edgeCount = 0
    val bandLumaTotals = DoubleArray(3)
    val bandCounts = IntArray(3)
    val bandEdgeTotals = DoubleArray(3)
    val bandEdgeCounts = IntArray(3)
    var previousRowLuma = DoubleArray(width / strideX + 2)
    var rowIndex = 0
    var y = 0
    while (y < height) {
        var x = 0
        var previousLuma = -1.0
        var columnIndex = 0
        val bandIndex = min(2, (y * 3) / height)
        while (x < width) {
            val luma = pixelLuma(bitmap.getPixel(x, y))
            lumaTotal += luma
            count += 1
            bandLumaTotals[bandIndex] += luma
            bandCounts[bandIndex] += 1
            if (previousLuma >= 0.0) {
                val delta = abs(luma - previousLuma)
                edgeTotal += delta
                bandEdgeTotals[bandIndex] += delta
                edgeCount += 1
                bandEdgeCounts[bandIndex] += 1
            }
            if (rowIndex > 0 && columnIndex < previousRowLuma.size) {
                val delta = abs(luma - previousRowLuma[columnIndex])
                edgeTotal += delta
                bandEdgeTotals[bandIndex] += delta
                edgeCount += 1
                bandEdgeCounts[bandIndex] += 1
            }
            previousRowLuma[columnIndex] = luma
            previousLuma = luma
            columnIndex += 1
            x += strideX
        }
        rowIndex += 1
        y += strideY
    }
    return CapturedPhotoQualitySample(
        averageLuma = if (count == 0) -1.0 else lumaTotal / count,
        edgeScore = if (edgeCount == 0) -1.0 else edgeTotal / edgeCount,
        topLuma = bandAverage(bandLumaTotals, bandCounts, 0),
        middleLuma = bandAverage(bandLumaTotals, bandCounts, 1),
        bottomLuma = bandAverage(bandLumaTotals, bandCounts, 2),
        bottomEdgeScore = bandAverage(bandEdgeTotals, bandEdgeCounts, 2),
    )
}

internal fun ReceiptCameraActivity.bandAverage(totals: DoubleArray, counts: IntArray, index: Int): Double {
    if (index < 0 || index >= totals.size || index >= counts.size) return -1.0
    return if (counts[index] <= 0) -1.0 else totals[index] / counts[index]
}

internal fun ReceiptCameraActivity.pixelLuma(pixel: Int): Double {
    return (Color.red(pixel) * 0.299) +
        (Color.green(pixel) * 0.587) +
        (Color.blue(pixel) * 0.114)
}

internal fun ReceiptCameraActivity.roundedDiagnostic(value: Double): Double {
    if (!value.isFinite() || value < 0.0) return -1.0
    return round(value * 10.0) / 10.0
}

internal fun ReceiptCameraActivity.capturedBrightnessBucket(luma: Double): String {
    return when {
        !luma.isFinite() || luma < 0.0 -> "unknown"
        luma < 70.0 -> "captured_too_dark"
        luma < 105.0 -> "captured_dim"
        luma < 205.0 -> "captured_readable"
        luma < 246.0 -> "captured_bright"
        else -> "captured_glare_risk"
    }
}

internal fun ReceiptCameraActivity.capturedSharpnessBucket(edgeScore: Double): String {
    return when {
        !edgeScore.isFinite() || edgeScore < 0.0 -> "unknown"
        edgeScore < 5.5 -> "captured_soft_blur_risk"
        edgeScore < 10.0 -> "captured_usable_soft"
        edgeScore < 24.0 -> "captured_sharp"
        else -> "captured_high_contrast_edges"
    }
}

internal fun ReceiptCameraActivity.capturedQualitySignal(
    brightnessBucket: String,
    sharpnessBucket: String,
): String {
    if (brightnessBucket == "unknown" || sharpnessBucket == "unknown") return "unknown"
    if (brightnessBucket == "captured_too_dark" || brightnessBucket == "captured_glare_risk") {
        return "retake_brightness_risk"
    }
    if (sharpnessBucket == "captured_soft_blur_risk") return "retake_blur_risk"
    if (brightnessBucket == "captured_dim" || sharpnessBucket == "captured_usable_soft") {
        return "review_before_saving"
    }
    return "captured_readable"
}

internal fun ReceiptCameraActivity.nativeCapturedPhotoDiagnostics(
    photoByteSize: Long,
    capturedAt: String,
): HashMap<String, Any> {
    return hashMapOf(
        "capturedAt" to capturedAt,
        "photoByteSize" to photoByteSize,
        "photoByteSizeBucket" to byteSizeBucket(photoByteSize),
        "latestCapturedPhotoWidth" to latestCapturedPhotoWidth,
        "latestCapturedPhotoHeight" to latestCapturedPhotoHeight,
        "latestCapturedAverageLuma" to latestCapturedAverageLuma,
        "latestCapturedEdgeScore" to latestCapturedEdgeScore,
        "latestCapturedTopLuma" to latestCapturedTopLuma,
        "latestCapturedMiddleLuma" to latestCapturedMiddleLuma,
        "latestCapturedBottomLuma" to latestCapturedBottomLuma,
        "latestCapturedBottomEdgeScore" to latestCapturedBottomEdgeScore,
        "receiptBottomEdgeDetected" to receiptBottomEdgeDetected(),
        "receiptBottomEdgeStatus" to receiptBottomEdgeStatus(),
        "receiptTotalsTextEvidenceStatus" to "not_evaluated_native_capture",
        "latestCapturedBottomTopLumaDelta" to latestCapturedBottomTopLumaDelta,
        "latestCapturedBottomTopLumaDeltaBucket" to latestCapturedBottomTopLumaDeltaBucket,
        "latestCapturedVerticalQualitySignal" to latestCapturedVerticalQualitySignal,
        "latestCapturedMegapixelBucket" to latestCapturedMegapixelBucket,
        "latestCapturedByteBucket" to latestCapturedByteBucket,
        "latestCapturedBrightnessBucket" to latestCapturedBrightnessBucket,
        "latestCapturedSharpnessBucket" to latestCapturedSharpnessBucket,
        "latestCapturedQualitySignal" to latestCapturedQualitySignal,
        "latestCaptureLiveBrightnessAtShutter" to latestCaptureLiveBrightnessAtShutter,
        "latestCaptureShutterZoomRatio" to latestCaptureShutterZoomRatio,
        "latestCaptureShutterExposureIndex" to latestCaptureShutterExposureIndex,
        "latestCapturedLiveToSavedLumaDelta" to latestCapturedLiveToSavedLumaDelta,
        "latestCapturedLiveToSavedLumaDeltaBucket" to latestCapturedLiveToSavedLumaDeltaBucket,
        "latestCapturedPreviewParitySignal" to latestCapturedPreviewParitySignal,
        "latestCapturedExposureMismatch" to latestCapturedExposureMismatch,
        "capturedLightingEvidence" to capturedLightingEvidence,
        "latestCaptureToSavedMs" to latestCaptureToSavedMs,
        "latestCaptureToReviewReadyMs" to latestCaptureToReviewReadyMs,
    )
}

internal fun ReceiptCameraActivity.capturedVerticalQualitySignal(sample: CapturedPhotoQualitySample): String {
    if (
        !sample.bottomLuma.isFinite() ||
        !sample.topLuma.isFinite() ||
        !sample.middleLuma.isFinite() ||
        !sample.bottomEdgeScore.isFinite() ||
        !sample.edgeScore.isFinite() ||
        sample.bottomLuma < 0.0 ||
        sample.topLuma < 0.0 ||
        sample.middleLuma < 0.0
    ) {
        return "unknown"
    }
    val upperLuma = (sample.topLuma + sample.middleLuma) / 2.0
    return when {
        sample.bottomLuma < 70.0 -> "bottom_too_dark"
        sample.bottomEdgeScore in 0.0..5.5 && sample.edgeScore >= 8.0 -> "bottom_soft_blur_risk"
        upperLuma - sample.bottomLuma >= 28.0 -> "bottom_darker_than_upper"
        sample.bottomLuma - upperLuma >= 42.0 -> "bottom_glare_than_upper"
        else -> "vertical_quality_even"
    }
}

internal fun ReceiptCameraActivity.capturedBottomTopLumaDelta(sample: CapturedPhotoQualitySample): Double {
    if (sample.bottomLuma < 0.0 || sample.topLuma < 0.0) return -10000.0
    return roundedDiagnostic(sample.bottomLuma - sample.topLuma)
}

internal fun ReceiptCameraActivity.capturedBottomTopLumaDeltaBucket(delta: Double): String {
    return when {
        !delta.isFinite() || delta < -999.0 -> "unknown"
        delta <= -42.0 -> "bottom_much_darker_than_top"
        delta <= -24.0 -> "bottom_darker_than_top"
        delta >= 42.0 -> "bottom_much_brighter_than_top"
        delta >= 24.0 -> "bottom_brighter_than_top"
        else -> "top_bottom_brightness_close"
    }
}

internal fun ReceiptCameraActivity.receiptBottomEdgeDetected(): Boolean {
    return receiptBottomEdgeStatus() == "bottom_visible"
}

internal fun ReceiptCameraActivity.hasLiveReceiptCutOffRisk(): Boolean {
    return latestFramingSignal.equals("possibly_cut_off") ||
        latestPerspectiveReadiness == "perspective_skipped_cut_off_risk"
}

internal fun ReceiptCameraActivity.hasLiveReceiptFramingOk(): Boolean {
    return latestFramingSignal.equals("framing_ok")
}

internal fun ReceiptCameraActivity.receiptBottomEdgeStatus(): String {
    if (hasLiveReceiptCutOffRisk()) {
        return "possibly_cut_off"
    }
    if (
        !latestCapturedBottomEdgeScore.isFinite() ||
        !latestCapturedEdgeScore.isFinite() ||
        !latestEdgeCoverage.isFinite()
    ) {
        return "not_evaluated"
    }
    if (latestCapturedBottomEdgeScore in 0.0..5.5 && latestCapturedEdgeScore >= 8.0) {
        return "bottom_soft_or_missing"
    }
    if (latestCapturedBottomEdgeScore >= 10.0) {
        return "bottom_visible"
    }
    if (latestEdgeCoverage >= 0.70 && hasLiveReceiptFramingOk()) {
        return "bottom_visible"
    }
    if (latestCapturedBottomEdgeScore >= 0.0) {
        return "bottom_uncertain"
    }
    return "not_evaluated"
}
