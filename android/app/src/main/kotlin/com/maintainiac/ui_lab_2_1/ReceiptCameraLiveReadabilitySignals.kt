package com.maintainiac.ui_lab_2_1

import androidx.camera.core.ImageProxy

internal fun ReceiptCameraActivity.sampleLiveLumaGrid(image: ImageProxy): IntArray {
    val plane = image.planes.firstOrNull() ?: return IntArray(0)
    val buffer = plane.buffer.duplicate()
    val width = image.width
    val height = image.height
    val rowStride = plane.rowStride
    val pixelStride = plane.pixelStride.coerceAtLeast(1)
    if (width <= 0 || height <= 0 || buffer.limit() <= 0) return IntArray(0)
    val samples = ArrayList<Int>(144)
    val rowStep = maxOf(1, height / 12)
    val colStep = maxOf(1, width / 12)
    var y = rowStep / 2
    while (y < height) {
        var x = colStep / 2
        while (x < width) {
            val index = y * rowStride + x * pixelStride
            if (index >= 0 && index < buffer.limit()) {
                samples.add(buffer.get(index).toInt() and 0xFF)
            }
            x += colStep
        }
        y += rowStep
    }
    return samples.toIntArray()
}

internal fun ReceiptCameraActivity.evaluateLiveMotion(samples: IntArray): Double {
    if (samples.isEmpty()) return -1.0
    val previous = previousLiveLumaSamples
    previousLiveLumaSamples = samples
    if (previous == null || previous.size != samples.size) {
        return -1.0
    }
    var totalDelta = 0.0
    for (index in samples.indices) {
        totalDelta += kotlin.math.abs(samples[index] - previous[index]).toDouble()
    }
    val score = totalDelta / samples.size.toDouble()
    return score
}

internal fun ReceiptCameraActivity.estimateShadowScore(samples: IntArray): Double {
    if (samples.isEmpty()) return -1.0
    var minSample = 255
    var maxSample = 0
    for (sample in samples) {
        if (sample < minSample) minSample = sample
        if (sample > maxSample) maxSample = sample
    }
    return (maxSample - minSample).toDouble()
}
