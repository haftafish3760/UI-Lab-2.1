package com.maintainiac.ui_lab_2_1

import android.os.Build
import android.window.OnBackInvokedCallback
import android.window.OnBackInvokedDispatcher


internal fun ReceiptCameraActivity.readSessionArguments() {
    assistedReceiptFill = intent.getBooleanExtra("assistedReceiptFill", false)
    longReceiptMode = intent.getBooleanExtra("longReceiptMode", false)
    autoCaptureEnabled = intent.getBooleanExtra("autoCaptureEnabled", false)
    autoCaptureAllowed = intent.getBooleanExtra("autoCaptureAllowed", autoCaptureEnabled)
    if (!autoCaptureAllowed) autoCaptureEnabled = false
    deviceTier = intent.getStringExtra("deviceTier") ?: "medium"
    uiLocale = intent.getStringExtra("uiLocale") ?: "en-US"
    settingsContractVersion = intent.getStringExtra("settingsContractVersion")
        ?: "receipt_native_camera_settings_v1"
    devicePolicyLabel = intent.getStringExtra("devicePolicyLabel") ?: "balanced_receipt_camera"
    // Every capture opens the unified editable receipt review. Keep accepting
    // the old extra at the activity boundary, but never let it hide lines.
    reviewDepth = "detailedLines"
    focusMode = intent.getStringExtra("focusMode") ?: "continuous"
    exposureMode = intent.getStringExtra("exposureMode") ?: "auto"
    whiteBalanceMode = intent.getStringExtra("whiteBalanceMode") ?: "auto"
    whiteBalanceLockEnabled = false
    dataSaverLevel = intent.getStringExtra("dataSaverLevel") ?: "balanced"
    receiptPhotoBackupEnabled = intent.getBooleanExtra("receiptPhotoBackupEnabled", false)
    askSavedProofSizeEachReceipt = intent.getBooleanExtra(
        "askSavedProofSizeEachReceipt",
        false,
    )
    storageSafetyLevel = intent.getStringExtra("storageSafetyLevel") ?: dataSaverLevel
    storageConstrained = intent.getBooleanExtra("storageConstrained", false)
    storageSafetyReason = intent.getStringExtra("storageSafetyReason") ?: "normal"
    workloadProtectionPolicy = intent.getStringExtra("workloadProtectionPolicy")
        ?: "balanced_workload"
    maxLocalPhotoBytes = intent.getIntExtra("maxLocalPhotoBytes", maxLocalPhotoBytes)
    nativeCaptureMemoryPolicy = intent.getStringExtra("nativeCaptureMemoryPolicy")
        ?: nativeCaptureMemoryPolicy
    nativeControlContractTags = intent.getStringArrayListExtra("nativeControlContractTags")
        ?: arrayListOf()
    liveAnalysisEnabled = intent.getBooleanExtra("liveAnalysisEnabled", true)
    edgeDetectionEnabled = intent.getBooleanExtra("edgeDetectionEnabled", true)
    edgeOverlayEnabled = intent.getBooleanExtra("edgeOverlayEnabled", true)
    tapFocusEnabled = false
    pinchZoomEnabled = intent.getBooleanExtra("pinchZoomEnabled", true)
    exposureSliderEnabled = intent.getBooleanExtra("exposureSliderEnabled", true)
    exposureResetEnabled = intent.getBooleanExtra("exposureResetEnabled", true)
    tooFarTooCloseWarningEnabled = intent.getBooleanExtra("tooFarTooCloseWarningEnabled", true)
    receiptFullyVisibleWarningEnabled = intent.getBooleanExtra("receiptFullyVisibleWarningEnabled", true)
    textTooSmallWarningEnabled = intent.getBooleanExtra("textTooSmallWarningEnabled", true)
    autoExposureAssistEnabled = intent.getBooleanExtra("autoExposureAssistEnabled", true)
    perspectiveCorrectionEnabled = intent.getBooleanExtra("perspectiveCorrectionEnabled", true)
    manualCropAfterCapture = intent.getBooleanExtra("manualCropAfterCapture", true)
    autoCropSuggestionEnabled = intent.getBooleanExtra("autoCropSuggestionEnabled", true)
    grayscalePreviewEnabled = intent.getBooleanExtra("grayscalePreviewEnabled", true)
    contrastBoostEnabled = intent.getBooleanExtra("contrastBoostEnabled", true)
    sharpeningEnabled = intent.getBooleanExtra("sharpeningEnabled", true)
    shadowReductionEnabled = intent.getBooleanExtra("shadowReductionEnabled", true)
    adaptiveThresholdEnabled = intent.getBooleanExtra("adaptiveThresholdEnabled", true)
    orientationCorrectionEnabled = intent.getBooleanExtra("orientationCorrectionEnabled", true)
    saveOriginalTemporarily = intent.getBooleanExtra("saveOriginalTemporarily", true)
    queueAcceptedCaptureLocally = intent.getBooleanExtra("queueAcceptedCaptureLocally", true)
    ocrUsesOriginalFirst = intent.getBooleanExtra("ocrUsesOriginalFirst", true)
    analysisGapMs = intent.getIntExtra("analysisGapMs", 720).coerceIn(250, 2500).toLong()
    readyHoldMs = intent.getIntExtra("readyHoldMs", 700).coerceIn(250, 3000).toLong()
    assistedShotCount = intent.getIntExtra("assistedShotCount", 4).coerceIn(1, 12)
    bestShotCandidateCount = intent.getIntExtra("bestShotCandidateCount", 3).coerceIn(1, 12)
    cameraResolutionTier = intent.getStringExtra("cameraResolutionTier") ?: "high"
    cameraWorkloadTier = intent.getStringExtra("cameraWorkloadTier") ?: "balanced"
    previewExposurePolicy = intent.getStringExtra("previewExposurePolicy")
        ?: previewExposurePolicy
    previewBrightnessGuardPolicy = intent.getStringExtra("previewBrightnessGuardPolicy")
        ?: previewBrightnessGuardPolicy
    shutterSpeedPolicy = intent.getStringExtra("shutterSpeedPolicy") ?: shutterSpeedPolicy
    tapToFocusPolicy = "continuous_focus_primary_no_tap_focus"
    focusStrategyPolicy = intent.getStringExtra("focusStrategyPolicy") ?: focusStrategyPolicy
    continuousFocusEnabled =
        intent.getBooleanExtra("continuousFocusEnabled", continuousFocusEnabled)
    readabilityGuidancePolicy = intent.getStringExtra("readabilityGuidancePolicy")
        ?: readabilityGuidancePolicy
    lowLightWarningEnabled = readExperimentalReceiptQualityWarningFlag("lowLightWarningEnabled")
    glareWarningEnabled = readExperimentalReceiptQualityWarningFlag("glareWarningEnabled")
    dirtyLensWarningEnabled = readExperimentalReceiptQualityWarningFlag("dirtyLensWarningEnabled")
    motionBlurWarningEnabled = readExperimentalReceiptQualityWarningFlag("motionBlurWarningEnabled")
    shadowWarningEnabled = readExperimentalReceiptQualityWarningFlag("shadowWarningEnabled")
    enforceExperimentalReceiptQualityPolicyGuard()
    receiptCameraQualityBaseline =
        intent.getBooleanExtra("receiptCameraQualityBaseline", receiptCameraQualityBaseline)
    zoomGesturePolicy = intent.getStringExtra("zoomGesturePolicy") ?: zoomGesturePolicy
    autoCapturePolicy = intent.getStringExtra("autoCapturePolicy") ?: autoCapturePolicy
    val requestedAutoCaptureStableFrameTarget = intent.getIntExtra(
        "autoCaptureStableFrameTarget",
        autoCaptureStableFrameTarget,
    )
    autoCaptureStableFrameTarget = if (autoCaptureAllowed) {
        requestedAutoCaptureStableFrameTarget.coerceIn(2, 8)
    } else {
        0
    }
    autoCaptureMaxMotionScore = finiteDoubleExtra(
        "autoCaptureMaxMotionScore",
        autoCaptureMaxMotionScore,
    ).coerceIn(3.0, 18.0)
    autoCaptureMinBrightness = finiteDoubleExtra(
        "autoCaptureMinBrightness",
        autoCaptureMinBrightness,
    ).coerceIn(72.0, 180.0)
    autoCaptureMaxBrightness = finiteDoubleExtra(
        "autoCaptureMaxBrightness",
        autoCaptureMaxBrightness,
    ).coerceIn(autoCaptureMinBrightness + 20.0, 252.0)
    val requestedAutoCaptureCooldownMs = intent.getIntExtra(
        "autoCaptureCooldownMs",
        autoCaptureCooldownMs.toInt(),
    )
    autoCaptureCooldownMs = if (autoCaptureAllowed) {
        requestedAutoCaptureCooldownMs.coerceIn(1200, 6000).toLong()
    } else {
        0L
    }
    preCaptureExposurePolicy = intent.getStringExtra("preCaptureExposurePolicy")
        ?: preCaptureExposurePolicy
    maxLiveAnalysisPixels = intent.getIntExtra("maxLiveAnalysisPixels", 0).coerceAtLeast(0)
    maxCleanupPixels = intent.getIntExtra("maxCleanupPixels", 10000000).coerceAtLeast(0)
    maxStitchOutputPixels = intent.getIntExtra("maxStitchOutputPixels", 14000000).coerceAtLeast(0)
    maxStitchOutputHeight = intent.getIntExtra("maxStitchOutputHeight", 18000).coerceAtLeast(0)
    sessionMinZoom = finiteDoubleExtra("minZoom", 1.0).coerceAtLeast(1.0)
    sessionMaxZoom = finiteDoubleExtra("maxZoom", 1.0).coerceAtLeast(sessionMinZoom)
    sessionInitialZoom = finiteDoubleExtra(
        "initialZoomRatio",
        sessionMinZoom
    ).coerceIn(sessionMinZoom, sessionMaxZoom)
        .coerceIn(sessionMinZoom, sessionMaxZoom)
    sessionMinExposureOffset = finiteDoubleExtra("minExposureOffset", 0.0)
    sessionMaxExposureOffset = finiteDoubleExtra("maxExposureOffset", 0.0)
    maxSectionCount = intent.getIntExtra("maxSectionCount", 8).coerceIn(1, 24)
    if (!canUseLongReceiptMode()) {
        longReceiptMode = false
    }
    previousSectionGuidePhotoPath = intent
        .getStringExtra("previousSectionGuidePhotoPath")
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
    nextSectionGuidePhotoPath = intent
        .getStringExtra("nextSectionGuidePhotoPath")
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
    previousSectionReasonCode = intent
        .getStringExtra("previousSectionReasonCode")
        ?.trim()
        ?.lowercase()
        ?.takeIf { it.isNotEmpty() }
        ?: if (previousSectionGuidePhotoPath != null) "continue_long_receipt" else "none"
    previousSectionGuidance = intent
        .getStringExtra("previousSectionGuidance")
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
        ?: ""
    previousSectionGhostSourceStartFraction = boundedFraction(
        intent.getDoubleExtra("previousSectionGhostSourceStartFraction", previousSectionGhostSourceStartFraction),
        previousSectionGhostSourceStartFraction,
    )
    previousSectionGhostSourceHeightFraction = boundedFraction(
        intent.getDoubleExtra("previousSectionGhostSourceHeightFraction", previousSectionGhostSourceHeightFraction),
        previousSectionGhostSourceHeightFraction,
    )
    previousSectionGhostOverlayTopFraction = boundedFraction(
        intent.getDoubleExtra("previousSectionGhostOverlayTopFraction", previousSectionGhostOverlayTopFraction),
        previousSectionGhostOverlayTopFraction,
    )
    previousSectionGhostOverlayHeightFraction = boundedFraction(
        intent.getDoubleExtra("previousSectionGhostOverlayHeightFraction", previousSectionGhostOverlayHeightFraction),
        previousSectionGhostOverlayHeightFraction,
    )
    previousSectionGhostOpacity = boundedFraction(
        intent.getDoubleExtra("previousSectionGhostOpacity", previousSectionGhostOpacity),
        previousSectionGhostOpacity,
    )
}

internal fun ReceiptCameraActivity.finiteDoubleExtra(key: String, fallback: Double): Double {
    val value = intent.getDoubleExtra(key, fallback)
    return if (value.isFinite()) value else fallback
}

internal fun ReceiptCameraActivity.readExperimentalReceiptQualityWarningFlag(
    key: String,
): Boolean {
    if (!experimentalLiveReceiptQualityPolicyEnabled()) return false
    return intent.getBooleanExtra(key, false)
}

internal fun ReceiptCameraActivity.enforceExperimentalReceiptQualityPolicyGuard() {
    if (experimentalLiveReceiptQualityPolicyEnabled()) return
    lowLightWarningEnabled = false
    glareWarningEnabled = false
    dirtyLensWarningEnabled = false
    motionBlurWarningEnabled = false
    shadowWarningEnabled = false
}

internal fun ReceiptCameraActivity.registerSystemBackHandler() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
    val callback = OnBackInvokedCallback {
        requestCloseCamera(backDispatchPath = "system_on_back_invoked")
    }
    onBackInvokedDispatcher.registerOnBackInvokedCallback(
        OnBackInvokedDispatcher.PRIORITY_DEFAULT,
        callback,
    )
    systemBackCallback = callback
}

internal fun ReceiptCameraActivity.unregisterSystemBackHandler() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
    val callback = systemBackCallback ?: return
    runCatching {
        onBackInvokedDispatcher.unregisterOnBackInvokedCallback(callback)
    }
    systemBackCallback = null
}
