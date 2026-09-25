package com.maintainiac.ui_lab_2_1

import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.util.Range
import android.view.Gravity
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min


internal fun ReceiptCameraActivity.iconButton(
    label: String,
    icon: Int,
    onClick: () -> Unit,
): ImageButton {
    return ImageButton(this).apply {
        contentDescription = label
        setImageResource(icon)
        setColorFilter(Color.WHITE)
        background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.argb(220, 17, 24, 27))
        }
        layoutParams = LinearLayout.LayoutParams(dp(48), dp(48)).apply {
            leftMargin = dp(2)
            rightMargin = dp(2)
        }
        setOnClickListener { onClick() }
    }
}

internal fun ReceiptCameraActivity.receiptCameraText(english: String, spanish: String): String {
    return if (uiLocale.lowercase().startsWith("es")) spanish else english
}

internal fun ReceiptCameraActivity.modeLabel(title: String, detail: String): TextView {
    return TextView(this).apply {
        text = "$title\n$detail"
        setTextColor(Color.WHITE)
        textSize = 12f
        gravity = Gravity.CENTER
        setPadding(dp(8), dp(8), dp(8), dp(8))
        setBackgroundColor(Color.argb(220, 17, 24, 27))
        layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
    }
}

internal fun ReceiptCameraActivity.guidanceText(): String {
    return if (longReceiptMode) {
        receiptCameraText(
            "Fill the screen with readable receipt text. Use more photos for long receipts.",
            "Llene la pantalla con texto legible del recibo. Use más fotos para recibos largos.",
        )
    } else if (autoCaptureEnabled) {
        receiptCameraText(
            "Fill the screen with readable receipt text. Auto capture can help when the receipt is steady.",
            "Llene la pantalla con texto legible del recibo. La captura automática ayuda cuando el recibo está estable.",
        )
    } else {
        receiptCameraText(
            "Fill the screen with readable receipt text, then tap the shutter.",
            "Llene la pantalla con texto legible del recibo y luego toque el disparador.",
        )
    }
}

internal fun ReceiptCameraActivity.isTemporaryControlGuidance(message: String): Boolean {
    return message.startsWith("Zoom ") || message.startsWith("Brightness ")
}

internal fun ReceiptCameraActivity.restoreWorkflowGuidanceIfNeeded() {
    val current = guidance.text?.toString()?.trim().orEmpty()
    if (isTemporaryControlGuidance(current)) {
        guidance.text = guidanceText()
    }
}

internal fun ReceiptCameraActivity.dataSaverLabel(): String {
    return when (dataSaverLevel) {
        "original" -> "Local original"
        "light" -> "High quality"
        "strong" -> "Low storage"
        "maximum" -> "Tiny proof"
        else -> "Normal proof"
    }
}

internal fun ReceiptCameraActivity.autoCaptureDetail(): String {
    return if (isAutoCaptureCurrentlyAllowed()) {
        "Off by default. Waits for 3 steady readable frames. Manual shutter always works."
    } else if (!edgeDetectionEnabled) {
        "Turn receipt edge guidance on before using automatic capture."
    } else {
        "Manual capture is safest for this device or storage mode."
    }
}

internal fun ReceiptCameraActivity.autoCaptureBlockedMessage(): String {
    if (!edgeDetectionEnabled) {
        return "Receipt edge guidance is off, so automatic capture is held back. Tap the shutter when ready."
    }
    return if (storageConstrained) {
        "Storage is tight, so automatic capture is held back. Tap the shutter when ready."
    } else {
        "Automatic capture is held back on this device. Tap the shutter when ready."
    }
}

internal fun ReceiptCameraActivity.isAutoCaptureCurrentlyAllowed(): Boolean {
    return autoCaptureAllowed && edgeDetectionEnabled
}

internal fun ReceiptCameraActivity.canUseLongReceiptMode(): Boolean {
    return maxSectionCount > 1
}

internal fun ReceiptCameraActivity.effectiveMinZoom(cameraMinZoom: Float): Float {
    // The live CameraX lens owns its lower zoom bound. A capability result
    // collected before binding must not force the capture screen to start
    // zoomed or keep the user from returning to 1x.
    return max(cameraMinZoom.toDouble(), 1.0).toFloat()
}

internal fun ReceiptCameraActivity.effectiveMaxZoom(cameraMinZoom: Float, cameraMaxZoom: Float): Float {
    val minZoom = effectiveMinZoom(cameraMinZoom)
    // The bound CameraX camera is authoritative for the actual rear lens.
    // Do not clamp it to a possibly stale preflight capability snapshot.
    val maxZoom = cameraMaxZoom
    return max(minZoom, maxZoom)
}

internal fun ReceiptCameraActivity.effectiveExposureRange(cameraRange: Range<Int>): Range<Int> {
    val lower = max(cameraRange.lower, ceil(sessionMinExposureOffset).toInt())
    val upper = min(cameraRange.upper, floor(sessionMaxExposureOffset).toInt())
    return if (lower <= upper) {
        Range(lower, upper)
    } else {
        Range(cameraRange.lower, cameraRange.upper)
    }
}

internal fun ReceiptCameraActivity.clampExposureIndex(index: Int, range: Range<Int>): Int {
    return index.coerceIn(range.lower, range.upper)
}

internal fun ReceiptCameraActivity.storageSafetyDetail(): String {
    return if (storageConstrained) {
        "Keeps long receipts lighter"
    } else {
        "Reads the clearest photo first"
    }
}
