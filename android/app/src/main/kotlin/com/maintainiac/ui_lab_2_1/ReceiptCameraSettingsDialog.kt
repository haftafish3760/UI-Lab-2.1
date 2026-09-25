package com.maintainiac.ui_lab_2_1

import android.app.Dialog
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

internal fun ReceiptCameraActivity.showReceiptCameraSettings() {
    settingsOpenCount += 1
    val dialog = Dialog(this).apply {
        requestWindowFeature(Window.FEATURE_NO_TITLE)
    }
    val root = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        setBackgroundColor(Color.rgb(22, 29, 32))
    }
    root.addView(LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        setPadding(dp(12), dp(12), dp(12), dp(8))
        setBackgroundColor(Color.rgb(17, 24, 27))
        addView(TextView(this@showReceiptCameraSettings).apply {
            text = receiptCameraText("Receipt Camera Settings", "Configuración de la cámara de recibos")
            setTextColor(Color.WHITE)
            textSize = 20f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        })
        addView(android.widget.Button(this@showReceiptCameraSettings).apply {
            text = receiptCameraText("Done", "Listo")
            isAllCaps = false
            setTextColor(Color.rgb(16, 20, 22))
            setBackgroundColor(Color.rgb(255, 209, 102))
            setOnClickListener { dialog.dismiss() }
        })
    })
    val content = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(dp(18), dp(12), dp(18), dp(18))
    }
    content.addView(settingSummary(
        receiptCameraText("Live camera", "Cámara en vivo"),
        receiptCameraText(
            "Changes apply to this camera session. The phone keeps control of its supported autofocus, lens, exposure, and stabilization features.",
            "Estos controles se aplican mientras esta cámara está abierta. " +
                "Configure sus valores predeterminados de recibos en Configuración de recibos. " +
                "El teléfono conserva el control de las funciones compatibles de enfoque, " +
                "lente, exposición y estabilización.",
        ),
    ))
    content.addView(settingSectionHeader(receiptCameraText("CAPTURE FLOW", "FLUJO DE CAPTURA")))
    content.addView(settingSwitch(
        receiptCameraText("Automatic capture", "Captura automática"),
        autoCaptureDetail(),
        autoCaptureEnabled,
    ) {
        if (it && !isAutoCaptureCurrentlyAllowed()) {
            autoCaptureEnabled = false
            guidance.text = autoCaptureBlockedMessage()
            return@settingSwitch
        }
        autoCaptureEnabled = it
        if (!it) {
            autoCaptureStableFrameCount = 0
            latestAutoCaptureStatus = "off"
        }
        guidance.text = if (it) {
            receiptCameraText(
                "Automatic capture is on. Hold steady, or capture anytime.",
                "La captura automática está activada. Mantenga firme el teléfono o capture en cualquier momento.",
            )
        } else {
            guidanceText()
        }
        updateSettingsStatusStrip()
    })
    content.addView(settingSwitch(
        receiptCameraText("Receipt framing checks", "Revisiones de encuadre del recibo"),
        receiptCameraText(
            "Warn when paper edges may be cut off or the receipt may be too far away. The shutter button always works immediately.",
            "Advierte cuando los bordes del papel pueden estar cortados o el recibo está demasiado lejos. El disparador siempre funciona de inmediato.",
        ),
        receiptGuidanceWarningsEnabled(),
    ) {
        setReceiptGuidanceWarningsEnabled(it)
        guidance.text = if (it) {
            receiptCameraText("Receipt framing checks are on.", "Las revisiones de encuadre están activadas.")
        } else {
            receiptCameraText("Receipt framing checks are off. Manual shutter still works.", "Las revisiones de encuadre están desactivadas. El disparador manual sigue funcionando.")
        }
        updateSettingsStatusStrip()
    })
    content.addView(settingSwitch(
        receiptCameraText("Find receipt edges", "Detectar bordes del recibo"),
        receiptCameraText(
            "Show edge guidance for cropping and straightening. Manual shutter still works.",
            "Muestra guía de bordes para recortar y enderezar. El disparador manual sigue funcionando.",
        ),
        edgeDetectionEnabled,
    ) {
        edgeDetectionEnabled = it
        if (!it && autoCaptureEnabled) {
            autoCaptureEnabled = false
            autoCaptureStableFrameCount = 0
            latestAutoCaptureStatus = "edge_detection_off"
        }
        receiptFrameGuide.visibility = if (it && edgeOverlayEnabled) View.VISIBLE else View.GONE
        guidance.text = if (it) {
            receiptCameraText("Receipt edge guidance is on.", "La guía de bordes del recibo está activada.")
        } else {
            receiptCameraText("Receipt edge guidance is off. Take the clearest photo you can.", "La guía de bordes del recibo está desactivada. Tome la foto más clara que pueda.")
        }
        updateSettingsStatusStrip()
    })
    content.addView(settingSectionHeader(receiptCameraText("CAMERA CONTROLS", "CONTROLES DE CÁMARA")))
    content.addView(settingSlider(
        receiptCameraText("Brightness", "Brillo"),
        if (exposureSliderEnabled && exposureSlider.isEnabled) {
            receiptCameraText(
                "Adjust only when receipt text looks too dark or washed out. Reset returns exposure to automatic.",
                "Ajuste solo si el texto se ve muy oscuro o descolorido. Restablecer devuelve la exposición a automático.",
            )
        } else {
            receiptCameraText(
                "This camera does not expose a supported brightness adjustment.",
                "Esta cámara no ofrece un ajuste de brillo compatible.",
            )
        },
        exposureSliderEnabled && exposureSlider.isEnabled,
        exposureSlider.max,
        exposureSlider.progress,
        onChanged = { progress ->
            exposureSlider.progress = progress
            setExposureFromSlider(progress)
        },
        onReset = { resetExposure() },
    ))
    content.addView(settingSwitch(
        receiptCameraText("Automatic brightness help", "Ayuda de brillo automático"),
        receiptCameraText(
            "Keep the phone's automatic exposure and allow safe receipt-paper brightness correction. The brightness button can still make a temporary adjustment.",
            "Mantiene la exposición automática del teléfono y permite una corrección segura para el papel. El botón de brillo aún permite un ajuste temporal.",
        ),
        autoExposureAssistEnabled,
    ) {
        autoExposureAssistEnabled = it
        userExposureOverride = false
        resetExposure()
        guidance.text = if (it) {
            receiptCameraText("Automatic brightness help is on.", "La ayuda de brillo automático está activada.")
        } else {
            receiptCameraText("The phone now controls exposure without receipt brightness help.", "El teléfono ahora controla la exposición sin ayuda de brillo para recibos.")
        }
        updateSettingsStatusStrip()
    })
    content.addView(settingSummary(
        receiptCameraText("Autofocus and stabilization", "Enfoque automático y estabilización"),
        receiptCameraText(
            "Maintainiac uses the autofocus and stabilization that the phone exposes through its camera API. Pinch to zoom; use brightness or light only when needed.",
            "Maintainiac usa el enfoque automático y la estabilización que el teléfono ofrece mediante su API de cámara. Pellizque para acercar; use brillo o luz solo cuando sea necesario.",
        ),
    ))
    content.addView(settingSummary(
        receiptCameraText("Receipts with more than one photo", "Recibos con más de una foto"),
        receiptCameraText(
            "No mode is required. Capture the first section, then choose Add Photo when the receipt continues.",
            "No se requiere un modo. Capture la primera sección y elija Agregar foto cuando el recibo continúe.",
        ),
    ))
    content.addView(settingSummary(
        receiptCameraText("Image quality", "Calidad de imagen"),
        receiptCameraText(
            "Maintainiac reads the temporary full-quality photo first. A smaller saved copy is made only after the receipt is read.",
            "Maintainiac lee primero la foto temporal de calidad completa. Solo después de leer el recibo se crea una copia guardada más pequeña.",
        ),
    ))
    val scroll = ScrollView(this).apply {
        isFillViewport = true
        addView(content)
    }
    root.addView(scroll, LinearLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        0,
        1f,
    ))
    root.addView(android.widget.Button(this).apply {
        text = receiptCameraText("Reset This Camera Session", "Restablecer esta sesión de cámara")
        isAllCaps = false
        setTextColor(Color.rgb(255, 209, 102))
        setBackgroundColor(Color.rgb(31, 37, 40))
        setOnClickListener {
            resetReceiptCameraDefaults()
            dialog.dismiss()
        }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply {
            leftMargin = dp(18)
            rightMargin = dp(18)
            bottomMargin = dp(14)
        }
    })
    dialog.setContentView(root)
    dialog.setOnShowListener {
        dialog.window?.setBackgroundDrawable(ColorDrawable(Color.rgb(22, 29, 32)))
        dialog.window?.setLayout(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
        )
    }
    dialog.show()
}

internal fun ReceiptCameraActivity.resetReceiptCameraDefaults() {
    settingsResetCount += 1
    // Expense and account preferences are deliberately not reset here.
    longReceiptMode = false
    autoCaptureEnabled = false
    autoExposureAssistEnabled = true
    liveAnalysisEnabled = true
    edgeDetectionEnabled = true
    edgeOverlayEnabled = true
    setReceiptGuidanceWarningsEnabled(true)
    perspectiveCorrectionEnabled = true
    manualCropAfterCapture = true
    autoCropSuggestionEnabled = true
    grayscalePreviewEnabled = true
    contrastBoostEnabled = true
    sharpeningEnabled = true
    shadowReductionEnabled = true
    adaptiveThresholdEnabled = true
    orientationCorrectionEnabled = true
    autoCaptureStableFrameCount = 0
    latestAutoCaptureStatus = "reset_to_manual_capture"
    userExposureOverride = false
    resetExposure()
    if (hasInitializedReceiptCameraField { receiptFrameGuide }) {
        receiptFrameGuide.visibility = View.VISIBLE
    }
    updateDoneButton()
    updateSettingsStatusStrip()
    guidance.text = receiptCameraText(
        "Receipt camera defaults restored. Manual shutter is ready.",
        "Se restauraron los valores de la cámara. El disparador manual está listo.",
    )
}

internal fun ReceiptCameraActivity.receiptGuidanceWarningsEnabled(): Boolean {
    return tooFarTooCloseWarningEnabled ||
        receiptFullyVisibleWarningEnabled ||
        textTooSmallWarningEnabled
}

internal fun ReceiptCameraActivity.experimentalLiveReceiptQualityPolicyEnabled(): Boolean {
    return readabilityGuidancePolicy == "native_camera_receipt_quality_guidance_v1" ||
        readabilityGuidancePolicy == "experimental_live_receipt_quality_opt_in"
}

internal fun ReceiptCameraActivity.setReceiptGuidanceWarningsEnabled(enabled: Boolean) {
    tooFarTooCloseWarningEnabled = enabled
    receiptFullyVisibleWarningEnabled = enabled
    textTooSmallWarningEnabled = enabled
}
