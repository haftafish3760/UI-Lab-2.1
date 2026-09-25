package com.maintainiac.ui_lab_2_1

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Matrix
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import androidx.exifinterface.media.ExifInterface
import java.io.File
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.min
import kotlin.math.roundToInt

// The two guides deliberately live in separate narrow bands. The middle of
// the camera stays clear so the person can see the receipt they are retaking.
internal fun ReceiptCameraActivity.buildPreviousSectionGuide(): View {
    previousSectionGuidePanel = guidePanel(Gravity.TOP, topMargin = dp(56), bottomMargin = 0)
    previousSectionGuideImage = guideImage(readableGuideOpacity(previousSectionGhostOpacity.toFloat())).apply {
        contentDescription = "Top overlap guide showing the bottom of the previous receipt photo"
    }
    previousSectionGuidePanel.addView(previousSectionGuideImage)
    updatePreviousSectionGuide(previousSectionGuidePhotoPath)
    return previousSectionGuidePanel
}

internal fun ReceiptCameraActivity.buildNextSectionGuide(): View {
    nextSectionGuidePanel = guidePanel(Gravity.BOTTOM, topMargin = 0, bottomMargin = dp(72))
    nextSectionGuideImage = guideImage(readableGuideOpacity(nextSectionGhostOpacity())).apply {
        contentDescription = "Bottom overlap guide showing the top of the next receipt photo"
    }
    nextSectionGuidePanel.addView(nextSectionGuideImage)
    updateNextSectionGuide(nextSectionGuidePhotoPath)
    return nextSectionGuidePanel
}

private fun ReceiptCameraActivity.guidePanel(
    gravity: Int,
    topMargin: Int,
    bottomMargin: Int,
): LinearLayout = LinearLayout(this).apply {
    orientation = LinearLayout.VERTICAL
    // A solid black band separates the translucent reference from the live
    // camera. It keeps faded receipt text readable without adding a gap that
    // would make the person guess where the next section begins.
    setBackgroundColor(Color.BLACK)
    setPadding(0, 0, 0, 0)
    visibility = View.GONE
    layoutParams = FrameLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        dp(152),
        gravity,
    ).apply {
        this.topMargin = topMargin
        this.bottomMargin = bottomMargin
        leftMargin = 0
        rightMargin = 0
    }
}

private fun ReceiptCameraActivity.guideImage(alpha: Float): ImageView = ImageView(this).apply {
    // Keep all reference text visible instead of cropping away either edge.
    scaleType = ImageView.ScaleType.FIT_CENTER
    this.alpha = alpha.coerceIn(0f, 1f)
    layoutParams = LinearLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        0,
        1f,
    )
}

internal fun ReceiptCameraActivity.updatePreviousSectionGuide(path: String?) {
    if (!hasInitializedReceiptCameraField { previousSectionGuidePanel }) return
    val guidePath = path?.trim()?.takeIf { it.isNotEmpty() } ?: run {
        previousSectionGuidePanel.visibility = View.GONE
        return
    }
    val guideFile = File(guidePath)
    if (!guideFile.isAbsolute || !guideFile.isFile || !isPreviousSectionGuideImagePath(guidePath)) {
        previousSectionGuidePanel.visibility = View.GONE
        return
    }
    val request = ++previousSectionGuideLoadRequest
    previousSectionGuidePanel.visibility = View.GONE
    receiptPhotoQualityExecutor.execute {
        val guideSlice = previousSectionGhostSliceBitmap(guideFile)
        runOnUiThread {
            if (request != previousSectionGuideLoadRequest || isFinishing || isDestroyed) return@runOnUiThread
            if (guideSlice == null) {
                previousSectionGuidePanel.visibility = View.GONE
                return@runOnUiThread
            }
            previousSectionGuideImage.setImageBitmap(guideSlice)
            previousSectionGuideImage.alpha = readableGuideOpacity(previousSectionGhostOpacity.toFloat())
            previousSectionGuidePanel.visibility = View.VISIBLE
        }
    }
}

internal fun ReceiptCameraActivity.updateNextSectionGuide(path: String?) {
    if (!hasInitializedReceiptCameraField { nextSectionGuidePanel }) return
    val guidePath = path?.trim()?.takeIf { it.isNotEmpty() } ?: run {
        nextSectionGuidePanel.visibility = View.GONE
        return
    }
    val guideFile = File(guidePath)
    if (!guideFile.isAbsolute || !guideFile.isFile || !isPreviousSectionGuideImagePath(guidePath)) {
        nextSectionGuidePanel.visibility = View.GONE
        return
    }
    val request = ++nextSectionGuideLoadRequest
    nextSectionGuidePanel.visibility = View.GONE
    receiptPhotoQualityExecutor.execute {
        val guideSlice = nextSectionGhostSliceBitmap(guideFile)
        runOnUiThread {
            if (request != nextSectionGuideLoadRequest || isFinishing || isDestroyed) return@runOnUiThread
            if (guideSlice == null) {
                nextSectionGuidePanel.visibility = View.GONE
                return@runOnUiThread
            }
            nextSectionGuideImage.setImageBitmap(guideSlice)
            nextSectionGuideImage.alpha = readableGuideOpacity(nextSectionGhostOpacity())
            nextSectionGuidePanel.visibility = View.VISIBLE
        }
    }
}

internal fun ReceiptCameraActivity.previousSectionGhostSliceBitmap(file: File): Bitmap? {
    val source = receiptGhostBitmapWithVisualOrientation(file) ?: return null
    if (source.width <= 0 || source.height <= 0) return source
    val requestedHeight = ceil(source.height * boundedFraction(previousSectionGhostSourceHeightFraction, 0.34))
        .roundToInt().coerceIn(1, source.height)
    // Derive the start from the same strip height. The old .80 start + .34
    // height silently clipped the previous strip to .20 while next used .34.
    val startY = source.height - requestedHeight
    return cropGhostSlice(source, startY, requestedHeight)
}

internal fun ReceiptCameraActivity.nextSectionGhostSliceBitmap(file: File): Bitmap? {
    val source = receiptGhostBitmapWithVisualOrientation(file) ?: return null
    if (source.width <= 0 || source.height <= 0) return source
    return cropGhostSlice(
        source,
        0,
        ceil(source.height * boundedFraction(previousSectionGhostSourceHeightFraction, 0.34))
            .roundToInt()
            .coerceAtLeast(1),
    )
}

private fun cropGhostSlice(source: Bitmap, startY: Int, requestedHeight: Int): Bitmap {
    val safeStart = startY.coerceIn(0, source.height - 1)
    val safeHeight = min(requestedHeight, source.height - safeStart).coerceAtLeast(1)
    return try {
        Bitmap.createBitmap(source, 0, safeStart, source.width, safeHeight).also {
            if (it !== source) source.recycle()
        }
    } catch (_: IllegalArgumentException) {
        source
    }
}

private fun receiptGhostBitmapWithVisualOrientation(file: File): Bitmap? {
    // A full camera image can require hundreds of MiB. A reference strip only
    // needs preview resolution; probe dimensions before allocating its bitmap.
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(file.absolutePath, bounds)
    if (bounds.outWidth <= 0 || bounds.outHeight <= 0 ||
        bounds.outWidth > 30000 || bounds.outHeight > 30000) return null
    var sample = 1
    while (bounds.outWidth.toLong() * bounds.outHeight / sample / sample > 1000000L) {
        sample *= 2
    }
    val options = BitmapFactory.Options().apply { inSampleSize = sample }
    val source = BitmapFactory.decodeFile(file.absolutePath, options) ?: return null
    val orientation = try {
        ExifInterface(file.absolutePath).getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_NORMAL,
        )
    } catch (_: Exception) { ExifInterface.ORIENTATION_NORMAL }
    val matrix = Matrix()
    when (orientation) {
        ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.setScale(-1f, 1f)
        ExifInterface.ORIENTATION_ROTATE_180 -> matrix.setRotate(180f)
        ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.setScale(1f, -1f)
        ExifInterface.ORIENTATION_TRANSPOSE -> { matrix.setRotate(90f); matrix.postScale(-1f, 1f) }
        ExifInterface.ORIENTATION_ROTATE_90 -> matrix.setRotate(90f)
        ExifInterface.ORIENTATION_TRANSVERSE -> { matrix.setRotate(-90f); matrix.postScale(-1f, 1f) }
        ExifInterface.ORIENTATION_ROTATE_270 -> matrix.setRotate(-90f)
        else -> return source
    }
    return try {
        Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true).also {
            if (it !== source) source.recycle()
        }
    }
    catch (_: IllegalArgumentException) { source }
}

internal fun ReceiptCameraActivity.nextSectionGhostOpacity(): Float = 0.42f

// A guide is deliberately narrow, so it must remain readable on faded thermal
// paper. Keep it visible without allowing it to obscure the live center view.
private fun readableGuideOpacity(requested: Float): Float = requested.coerceIn(0.58f, 0.80f)

internal fun ReceiptCameraActivity.isPreviousSectionGuideImagePath(path: String): Boolean {
    val lowerPath = path.lowercase()
    return lowerPath.endsWith(".jpg") || lowerPath.endsWith(".jpeg") ||
        lowerPath.endsWith(".png") || lowerPath.endsWith(".heic") || lowerPath.endsWith(".webp")
}

internal fun ReceiptCameraActivity.boundedFraction(value: Double, fallback: Double): Double {
    if (value.isNaN() || value.isInfinite()) return fallback
    return value.coerceIn(0.0, 1.0)
}

internal fun ReceiptCameraActivity.previousSectionGhostGuideTitle(): String = "Top guide: bottom of previous photo"

internal fun ReceiptCameraActivity.previousSectionGhostGuideInstruction(): String =
    "Line up 3-5 readable lines at the top."

internal fun ReceiptCameraActivity.previousSectionGuideUsesNextContext(): Boolean =
    previousSectionReasonCode == "retake_top_with_next_context"

internal fun ReceiptCameraActivity.previousSectionGhostGuidePolicy(): String =
    when {
        previousSectionGuideUsesNextContext() ->
            "next_section_top_context_ghost_at_bottom_repeat_3_to_5_lines"
        previousSectionReasonCode == "missing_bottom_edge_and_totals" ->
            "bottom_overlap_ghost_at_top_repeat_3_to_5_lines"
        else -> "section_overlap_ghost_at_top_repeat_3_to_5_lines"
    }

internal fun ReceiptCameraActivity.previousSectionGhostGuideMatchTarget(): String =
    when {
        previousSectionGuideUsesNextContext() -> "next_section_top_lines"
        previousSectionReasonCode == "missing_bottom_edge_and_totals" ->
            "subtotal_total_and_final_lines"
        else -> "repeated_receipt_lines"
    }

internal fun ReceiptCameraActivity.addSectionButtonTitle(): String =
    if (previousSectionReasonCode == "missing_bottom_edge_and_totals") "Add Bottom" else "Add Photo"

internal fun ReceiptCameraActivity.addSectionButtonAccessibilityLabel(): String =
    if (previousSectionReasonCode == "missing_bottom_edge_and_totals")
        "Add bottom receipt section with overlap from this photo"
    else "Add another receipt photo if this receipt continues"
