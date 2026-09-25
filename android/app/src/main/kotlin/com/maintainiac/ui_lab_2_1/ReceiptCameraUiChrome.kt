package com.maintainiac.ui_lab_2_1

import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.SeekBar
import android.widget.TextView
import androidx.camera.view.PreviewView
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updateLayoutParams
import androidx.core.view.updatePadding


internal fun ReceiptCameraActivity.buildContentView(): View {
    cameraRootView = FrameLayout(this).apply {
        setBackgroundColor(Color.BLACK)
    }
    previewView = PreviewView(this).apply {
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
        )
        // The capture keeps the full-resolution source. The live view fills the
        // display so letterboxing never steals the receipt framing area.
        scaleType = PreviewView.ScaleType.FILL_CENTER
    }
    cameraRootView.addView(previewView)
    cameraRootView.addView(buildReceiptFrameGuide())
    cameraRootView.addView(buildTopBar())
    cameraRootView.addView(buildGuidance())
    cameraRootView.addView(buildPreviousSectionGuide())
    cameraRootView.addView(buildNextSectionGuide())
    cameraRootView.addView(buildSettingsStatusStrip())
    cameraRootView.addView(buildExposureControls())
    cameraRootView.addView(buildBottomBar())
    return cameraRootView
}

internal fun ReceiptCameraActivity.buildReceiptFrameGuide(): View {
    receiptFrameGuide = View(this).apply {
        background = frameGuideDrawable(Color.argb(176, 255, 209, 102))
        visibility = if (edgeDetectionEnabled && edgeOverlayEnabled) View.VISIBLE else View.GONE
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
            Gravity.CENTER,
        ).apply {
            leftMargin = dp(16)
            rightMargin = dp(16)
            topMargin = dp(64)
            bottomMargin = dp(92)
        }
        alpha = 0.72f
    }
    return receiptFrameGuide
}

internal fun ReceiptCameraActivity.buildTopBar(): View {
    topBar = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        setPadding(dp(8), dp(4), dp(8), dp(4))
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(52),
            Gravity.TOP,
        )
    }
    topBar.addView(iconButton(receiptCameraText("Back", "Atrás"), R.drawable.ic_receipt_camera_back) {
        requestCloseCamera(backDispatchPath = "top_bar_back_button")
    })
    topBar.addView(View(this).apply {
        layoutParams = LinearLayout.LayoutParams(0, 1, 1f)
    })
    topBar.addView(iconButton(receiptCameraText("Receipt camera settings", "Configuración de la cámara de recibos"), R.drawable.ic_receipt_camera_settings) {
        showReceiptCameraSettings()
    })
    brightnessButton = iconButton(
        receiptCameraText("Adjust brightness", "Ajustar brillo"),
        R.drawable.ic_receipt_camera_brightness,
    ) {
        toggleExposureControls()
    }
    topBar.addView(brightnessButton)
    torchButton = iconButton(
        receiptCameraText("Turn light on", "Encender luz"),
        R.drawable.ic_receipt_camera_flash,
    ) {
        toggleTorch()
    }
    topBar.addView(torchButton)
    return topBar
}

internal fun ReceiptCameraActivity.updateReceiptQuickControlsPanel() {
    // Receipt preferences live in the dedicated settings screen, not over the preview.
}

internal fun ReceiptCameraActivity.buildGuidance(): View {
    guidance = TextView(this).apply {
        text = guidanceText()
        visibility = View.GONE
        importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
        layoutParams = FrameLayout.LayoutParams(0, 0)
    }
    return guidance
}

internal fun ReceiptCameraActivity.buildExposureControls(): View {
    exposurePanel = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        setPadding(dp(10), dp(6), dp(10), dp(6))
        setBackgroundColor(Color.argb(118, 5, 6, 7))
        visibility = View.GONE
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(48),
            Gravity.BOTTOM,
        ).apply {
            bottomMargin = dp(80)
            leftMargin = dp(12)
            rightMargin = dp(12)
        }
    }
    exposurePanel.addView(TextView(this).apply {
        text = receiptCameraText("Brightness", "Brillo")
        setTextColor(Color.WHITE)
        textSize = 12f
        setTypeface(typeface, Typeface.BOLD)
    })
    exposureSlider = SeekBar(this).apply {
        isEnabled = false
        max = 0
        progress = 0
        layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                if (fromUser) setExposureFromSlider(progress)
            }

            override fun onStartTrackingTouch(seekBar: SeekBar?) = Unit
            override fun onStopTrackingTouch(seekBar: SeekBar?) {
                restoreWorkflowGuidanceIfNeeded()
            }
        })
    }
    exposurePanel.addView(exposureSlider)
    exposureResetButton = Button(this).apply {
        text = receiptCameraText("Reset", "Restablecer")
        isEnabled = false
        setOnClickListener { resetExposure() }
    }
    exposurePanel.addView(exposureResetButton)
    return exposurePanel
}

internal fun ReceiptCameraActivity.buildSettingsStatusStrip(): View {
    settingsStatusStrip = TextView(this).apply {
        text = settingsStatusText()
        setTextColor(Color.rgb(228, 235, 238))
        textSize = 11.5f
        gravity = Gravity.CENTER
        setTypeface(typeface, Typeface.BOLD)
        setPadding(dp(10), dp(6), dp(10), dp(6))
        setBackgroundColor(Color.argb(104, 5, 6, 7))
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.BOTTOM,
        ).apply {
            bottomMargin = dp(154)
            leftMargin = dp(18)
            rightMargin = dp(18)
        }
        visibility = View.GONE
    }
    return settingsStatusStrip
}

internal fun ReceiptCameraActivity.updateSettingsStatusStrip() {
    if (!hasInitializedReceiptCameraField { settingsStatusStrip }) return
    settingsStatusStrip.text = settingsStatusText()
    settingsStatusStrip.visibility = if (shouldShowSettingsStatusStrip()) {
        View.VISIBLE
    } else {
        View.GONE
    }
}

internal fun ReceiptCameraActivity.settingsStatusText(): String {
    val assist = if (assistedReceiptFill) "Assist on" else "Manual fill"
    val depth = "Editable lines"
    val length = if (longReceiptMode) "Long receipt" else "Single photo"
    val light = if (autoExposureAssistEnabled) "Auto light" else "Manual light"
    return "$assist • $depth • $length • $light"
}

internal fun ReceiptCameraActivity.shouldShowSettingsStatusStrip(): Boolean {
    // Keep the active preview chrome minimal. The full settings summary stays
    // inside the dedicated receipt camera settings surface instead.
    return false
}

internal fun ReceiptCameraActivity.buildBottomBar(): View {
    bottomBar = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
        setPadding(dp(8), dp(4), dp(8), dp(8))
        setBackgroundColor(Color.TRANSPARENT)
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(72),
            Gravity.BOTTOM,
        )
    }
    addPhotoButton = Button(this).apply {
        text = receiptCameraText("Add Photo", "Agregar foto")
        contentDescription = receiptCameraText("Add another receipt photo", "Agregar otra foto del recibo")
        isEnabled = false
        visibility = View.GONE
        setOnClickListener { capturePhoto("manual_add_photo") }
        layoutParams = LinearLayout.LayoutParams(0, dp(54), 1f)
    }
    bottomBar.addView(addPhotoButton)
    // Keep the center of the camera completely clear, but do not make the
    // normal pinch gesture invisible. The short label sits beside the shutter
    // instead of becoming another panel over the receipt.
    bottomBar.addView(TextView(this).apply {
        text = receiptCameraText("Pinch to zoom", "Pellizca para acercar")
        contentDescription = receiptCameraText(
            "Pinch the receipt view with two fingers to zoom",
            "Pellizque la vista del recibo con dos dedos para acercar",
        )
        setTextColor(Color.rgb(228, 235, 238))
        textSize = 11f
        setTypeface(typeface, Typeface.BOLD)
        gravity = Gravity.CENTER
        maxLines = 1
        layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
    })
    shutterButton = ImageButton(this).apply {
        contentDescription = receiptCameraText("Take receipt photo", "Tomar foto del recibo")
        setImageResource(R.drawable.ic_receipt_camera_shutter)
        background = shutterDrawable()
        layoutParams = LinearLayout.LayoutParams(dp(64), dp(64)).apply {
            leftMargin = dp(16)
            rightMargin = dp(16)
        }
        setOnClickListener { capturePhoto("manual_shutter") }
    }
    bottomBar.addView(shutterButton)
    val rightSpacer = View(this)
    bottomBar.addView(rightSpacer, LinearLayout.LayoutParams(0, 1, 1f))
    bottomReviewButton = Button(this).apply {
        text = receiptCameraText("Review Photos", "Revisar fotos")
        contentDescription = receiptCameraText("Review captured receipt photos in Maintainiac", "Revisar las fotos del recibo en Maintainiac")
        isEnabled = false
        visibility = View.GONE
        setOnClickListener { finishWithCapturedPhotos() }
        layoutParams = LinearLayout.LayoutParams(0, dp(54), 1f)
    }
    bottomBar.addView(bottomReviewButton)
    return bottomBar
}

internal fun ReceiptCameraActivity.applyEdgeToEdgeReceiptInsets() {
    ViewCompat.setOnApplyWindowInsetsListener(cameraRootView) { _, windowInsets ->
        val insets = windowInsets.getInsets(
            WindowInsetsCompat.Type.systemBars() or
                WindowInsetsCompat.Type.displayCutout(),
        )
        topBar.updatePadding(
            left = dp(8) + insets.left,
            top = dp(4) + insets.top,
            right = dp(8) + insets.right,
            bottom = dp(4),
        )
        topBar.updateLayoutParams<FrameLayout.LayoutParams> {
            height = dp(52) + insets.top
        }
        settingsStatusStrip.updateLayoutParams<FrameLayout.LayoutParams> {
            leftMargin = dp(18) + insets.left
            rightMargin = dp(18) + insets.right
            bottomMargin = dp(154) + insets.bottom
        }
        previousSectionGuidePanel.updateLayoutParams<FrameLayout.LayoutParams> {
            leftMargin = insets.left
            rightMargin = insets.right
            topMargin = dp(56) + insets.top
        }
        nextSectionGuidePanel.updateLayoutParams<FrameLayout.LayoutParams> {
            leftMargin = insets.left
            rightMargin = insets.right
            bottomMargin = dp(72) + insets.bottom
        }
        exposurePanel.updateLayoutParams<FrameLayout.LayoutParams> {
            leftMargin = dp(12) + insets.left
            rightMargin = dp(12) + insets.right
            bottomMargin = dp(80) + insets.bottom
        }
        bottomBar.updatePadding(
            left = dp(8) + insets.left,
            top = dp(6),
            right = dp(8) + insets.right,
            bottom = dp(8) + insets.bottom,
        )
        bottomBar.updateLayoutParams<FrameLayout.LayoutParams> {
            height = dp(72) + insets.bottom
        }
        receiptFrameGuide.updateLayoutParams<FrameLayout.LayoutParams> {
            leftMargin = dp(16) + insets.left
            rightMargin = dp(16) + insets.right
            topMargin = dp(60) + insets.top
            bottomMargin = dp(88) + insets.bottom
        }
        windowInsets
    }
    ViewCompat.requestApplyInsets(cameraRootView)
}

internal fun ReceiptCameraActivity.pillDrawable(color: Int): GradientDrawable {
    return GradientDrawable().apply {
        setColor(color)
        cornerRadius = dp(999).toFloat()
    }
}

internal fun ReceiptCameraActivity.quickControlsDrawable(): GradientDrawable {
    return GradientDrawable().apply {
        setColor(Color.argb(156, 5, 6, 7))
        cornerRadius = dp(12).toFloat()
        setStroke(dp(1), Color.argb(118, 255, 255, 255))
    }
}

internal fun ReceiptCameraActivity.shutterDrawable(): GradientDrawable {
    return GradientDrawable().apply {
        shape = GradientDrawable.OVAL
        setColor(Color.WHITE)
        setStroke(dp(4), Color.argb(210, 5, 6, 7))
    }
}
