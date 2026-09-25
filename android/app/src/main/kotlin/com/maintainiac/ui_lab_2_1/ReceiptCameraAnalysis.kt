package com.maintainiac.ui_lab_2_1

import android.hardware.camera2.CaptureRequest
import androidx.camera.camera2.interop.Camera2Interop
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import android.view.Surface
import android.widget.Toast
import androidx.camera.core.AspectRatio
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.core.UseCaseGroup
import androidx.camera.lifecycle.ProcessCameraProvider
import kotlin.math.min


internal fun ReceiptCameraActivity.startCamera() {
    if (cameraStartInProgress || closingCamera || closeResultDelivered) return
    // CameraX must share PreviewView's viewport with ImageCapture. Without
    // that contract, FILL_CENTER can show a tightly framed receipt while the
    // saved 4:3 JPEG contains a much wider scene, which makes pinch zoom look
    // as though it was lost when review opens.
    val captureViewPort = previewView.viewPort
    if (previewView.width <= 0 || previewView.height <= 0 || captureViewPort == null) {
        lastCameraStartStatus = "waiting_for_preview_viewport"
        previewView.post {
            if (isCameraSurfaceActive() && !closingCamera && camera == null) startCamera()
        }
        return
    }
    cameraStartInProgress = true
    cameraStartAttemptCount += 1
    lastCameraStartStatus = "provider_requested"
    val providerFuture = ProcessCameraProvider.getInstance(this)
    providerFuture.addListener(
        {
            if (!isCameraSurfaceActive()) {
                cameraStartInProgress = false
                lastCameraStartStatus = "surface_inactive"
                return@addListener
            }
            val provider = runCatching { providerFuture.get() }.getOrElse { error ->
                handleCameraStartFailure(error)
                return@addListener
            }
            cameraProvider = provider
            if (!isCameraSurfaceActive()) {
                runCatching { provider.unbindAll() }
                cameraStartInProgress = false
                lastCameraStartStatus = "surface_inactive"
                return@addListener
            }
            val targetRotation = previewView.display?.rotation ?: Surface.ROTATION_0
            val preview = Preview.Builder()
                .setTargetRotation(targetRotation)
                .setTargetAspectRatio(AspectRatio.RATIO_4_3)
                .applyReceiptContinuousFocusIfEnabled(this)
                .build().apply {
                setSurfaceProvider(previewView.surfaceProvider)
            }
            val captureMode = receiptStillCaptureMode()
            stillCaptureJpegQuality = receiptStillJpegQuality()
            val stillCapture = ImageCapture.Builder()
                .setTargetRotation(targetRotation)
                .setTargetAspectRatio(AspectRatio.RATIO_4_3)
                .setCaptureMode(captureMode)
                .setJpegQuality(stillCaptureJpegQuality)
                .applyReceiptContinuousFocusIfEnabled(this)
                .build()
            imageCapture = stillCapture
            val imageAnalysis = buildImageAnalysis(targetRotation)
            try {
                provider.unbindAll()
                if (!isCameraSurfaceActive()) {
                    cameraStartInProgress = false
                    lastCameraStartStatus = "surface_inactive"
                    return@addListener
                }
                val useCaseGroupBuilder = UseCaseGroup.Builder()
                    .setViewPort(captureViewPort)
                    .addUseCase(preview)
                    .addUseCase(stillCapture)
                if (imageAnalysis != null) useCaseGroupBuilder.addUseCase(imageAnalysis)
                camera = provider.bindToLifecycle(
                    this,
                    CameraSelector.DEFAULT_BACK_CAMERA,
                    useCaseGroupBuilder.build(),
                )
                applySessionInitialZoom()
                torchButton.isEnabled = camera?.cameraInfo?.hasFlashUnit() == true
                lastFocusStatus = receiptContinuousFocusStatus()
                configureTouchControls()
                configureExposureControls()
                guidance.text = guidanceText()
                cameraStartInProgress = false
                lastCameraStartStatus = "ready"
            } catch (error: Throwable) {
                runCatching { provider.unbindAll() }
                handleCameraStartFailure(error)
            }
        },
        mainExecutor(),
    )
}

internal fun ReceiptCameraActivity.applySessionInitialZoom() {
    val activeCamera = camera ?: return
    val zoomState = activeCamera.cameraInfo.zoomState.value
    val minZoom = effectiveMinZoom(zoomState?.minZoomRatio)
    val maxZoom = effectiveMaxZoom(zoomState?.maxZoomRatio)
    // The bound CameraX lens is authoritative. A stale capability preflight
    // must never make a receipt camera open digitally zoomed. Starting at the
    // live lens minimum preserves the wide framing the user sees at 1x.
    val initialZoom = minZoom.coerceIn(1.0, maxZoom)
    if (!initialZoom.isFinite() || minZoom.isInfinite() || maxZoom.isInfinite()) {
        lastZoomRatio = 1.0
        return
    }
    if (initialZoom == 1.0 && minZoom == maxZoom) {
        lastZoomRatio = roundedDiagnostic(initialZoom)
        return
    }
    if ((activeCamera.cameraInfo.zoomState.value?.zoomRatio ?: -1.0f) == initialZoom.toFloat()) {
        lastZoomRatio = roundedDiagnostic(initialZoom)
        return
    }
    val zoomFuture = activeCamera.cameraControl.setZoomRatio(initialZoom.toFloat())
    val zoomRequestId = ++zoomApplyRequestSequence
    zoomApplyInFlight = true
    zoomFuture.addListener(
        {
            val applied = runCatching {
                zoomFuture.get()
                true
            }.getOrDefault(false)
            completeZoomApplication(zoomRequestId, applied)
        },
        mainExecutor(),
    )
    lastZoomRatio = roundedDiagnostic(initialZoom)
}

private fun effectiveMinZoom(
    deviceMin: Float?,
): Double {
    val safeDeviceMin = deviceMin?.takeIf { it.isFinite() }?.toDouble()
    // CameraX reports the live lower bound for the lens we actually bound.
    // Never inherit a higher preflight minimum: that makes a capable device
    // appear to start zoomed and prevents pinching back to the native wide
    // framing. CameraX zoom ratios use 1x as the neutral minimum.
    return (safeDeviceMin ?: 1.0).coerceAtLeast(1.0)
}

private fun effectiveMaxZoom(
    deviceMax: Float?,
): Double {
    val safeDeviceMax = deviceMax?.takeIf { it.isFinite() && it >= 1f }?.toDouble()
    // Use the bound CameraX lens range, not a pre-bind capability snapshot.
    // Some Android devices report a limited or stale range before the camera
    // is bound; using that value makes a real pinch look disabled.
    return (safeDeviceMax ?: 1.0).coerceAtLeast(1.0)
}

internal fun ReceiptCameraActivity.handleCameraStartFailure(error: Throwable) {
    cameraStartInProgress = false
    cameraStartFailureCount += 1
    camera = null
    imageCapture = null
    if (hasInitializedReceiptCameraField { torchButton }) torchButton.isEnabled = false
    if (hasInitializedReceiptCameraField { shutterButton }) shutterButton.isEnabled = false
    val reason = if (error is SecurityException) "permission_denied" else "provider_unavailable"
    lastCameraStartStatus = reason
    if (cameraStartAttemptCount < 2 && isCameraSurfaceActive()) {
        lastCameraStartStatus = "retry_scheduled_$reason"
        guidance.text = "Restarting the receipt camera."
        previewView.postDelayed(
            {
                if (isCameraSurfaceActive() && !closingCamera && camera == null) startCamera()
            },
            350L,
        )
        return
    }
    guidance.text = "The receipt camera could not open. Returning to backup choices."
    Toast.makeText(this, "Receipt camera could not open.", Toast.LENGTH_LONG).show()
    cancelForCameraStartupFailure(reason)
}

internal fun ReceiptCameraActivity.receiptContinuousFocusStatus(): String {
    return when {
        continuousFocusEnabled && focusMode == "continuous" -> "continuous_autofocus_configured"
        focusMode == "continuous" -> "continuous_autofocus_unavailable"
        else -> "continuous_focus_not_requested"
    }
}

@OptIn(ExperimentalCamera2Interop::class)
internal fun Preview.Builder.applyReceiptContinuousFocusIfEnabled(
    activity: ReceiptCameraActivity,
): Preview.Builder {
    if (!activity.continuousFocusEnabled || activity.focusMode != "continuous") return this
    Camera2Interop.Extender(this)
        .setCaptureRequestOption(
            CaptureRequest.CONTROL_AF_MODE,
            CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE,
        )
        .setCaptureRequestOption(
            CaptureRequest.CONTROL_AE_MODE,
            CaptureRequest.CONTROL_AE_MODE_ON,
        )
    return this
}

@OptIn(ExperimentalCamera2Interop::class)
internal fun ImageCapture.Builder.applyReceiptContinuousFocusIfEnabled(
    activity: ReceiptCameraActivity,
): ImageCapture.Builder {
    if (!activity.continuousFocusEnabled || activity.focusMode != "continuous") return this
    Camera2Interop.Extender(this)
        .setCaptureRequestOption(
            CaptureRequest.CONTROL_AF_MODE,
            CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE,
        )
        .setCaptureRequestOption(
            CaptureRequest.CONTROL_AE_MODE,
            CaptureRequest.CONTROL_AE_MODE_ON,
        )
    return this
}

internal fun ReceiptCameraActivity.receiptStillCaptureMode(): Int {
    return when (cameraWorkloadTier) {
        "light" -> {
            stillCaptureModeLabel = "receipt_latency_light_device"
            ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY
        }
        "flagship" -> {
            stillCaptureModeLabel = "receipt_fast_document_shutter"
            ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY
        }
        else -> {
            stillCaptureModeLabel = "receipt_fast_document_shutter"
            ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY
        }
    }
}

internal fun ReceiptCameraActivity.receiptStillJpegQuality(): Int {
    return when (cameraWorkloadTier) {
        "flagship" -> 96
        "light" -> 94
        else -> 95
    }
}

internal fun ReceiptCameraActivity.buildImageAnalysis(targetRotation: Int): ImageAnalysis? {
    val experimentalQualityWarningsEnabled =
        experimentalLiveReceiptQualityPolicyEnabled() && (
            lowLightWarningEnabled ||
                glareWarningEnabled ||
                motionBlurWarningEnabled ||
                shadowWarningEnabled ||
                dirtyLensWarningEnabled
            )
    // Device capability policy can disable live analysis entirely. When it is
    // available, edge guidance must analyze frames even with manual capture;
    // otherwise the visible receipt frame would only be decorative.
    val needsLiveAnalysis = edgeDetectionEnabled ||
        autoCaptureEnabled ||
        experimentalQualityWarningsEnabled
    if (!liveAnalysisEnabled || !needsLiveAnalysis) {
        return null
    }
    return ImageAnalysis.Builder()
        .setTargetRotation(targetRotation)
        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
        .build()
        .apply {
            setAnalyzer(cameraAnalysisExecutor) { image -> analyzeLiveFrame(image) }
        }
}

internal fun ReceiptCameraActivity.hasExperimentalReceiptQualityWarningsEnabled(): Boolean {
    if (!experimentalLiveReceiptQualityPolicyEnabled()) {
        return false
    }
    return motionBlurWarningEnabled ||
        lowLightWarningEnabled ||
        glareWarningEnabled ||
        shadowWarningEnabled ||
        dirtyLensWarningEnabled
}

internal fun ReceiptCameraActivity.updateExperimentalReceiptQualityGuidance(
    signal: String,
    message: String,
) {
    if (stableExperimentalReceiptQualitySignal(signal)) {
        guidance.text = message
    } else {
        resetExperimentalReceiptQualityGuidanceIfNeeded()
    }
}

internal fun ReceiptCameraActivity.stableExperimentalReceiptQualitySignal(signal: String): Boolean {
    if (experimentalReceiptQualityCandidateSignal == signal) {
        experimentalReceiptQualityCandidateCount += 1
    } else {
        experimentalReceiptQualityCandidateSignal = signal
        experimentalReceiptQualityCandidateCount = 1
    }
    return experimentalReceiptQualityCandidateCount >= experimentalReceiptQualityRequiredFrames
}

internal fun ReceiptCameraActivity.resetExperimentalReceiptQualityCandidate() {
    experimentalReceiptQualityCandidateSignal = "none"
    experimentalReceiptQualityCandidateCount = 0
}

internal fun ReceiptCameraActivity.resetExperimentalReceiptQualityGuidanceIfNeeded() {
    val currentGuidance = guidance.text.toString()
    if (
        currentGuidance.startsWith("Receipt quality needs another look") ||
        currentGuidance.startsWith("Hold steady so the receipt text stays sharp") ||
        currentGuidance.startsWith("Receipt looks dark") ||
        currentGuidance.startsWith("Receipt is very bright") ||
        currentGuidance.startsWith("Receipt has heavy shadows") ||
        currentGuidance.startsWith("Lens may be smudged")
    ) {
        guidance.text = guidanceText()
    }
}

internal fun ReceiptCameraActivity.averageLuma(image: ImageProxy): Double {
    val plane = image.planes.firstOrNull() ?: return -1.0
    val buffer = plane.buffer.duplicate()
    val remaining = buffer.remaining()
    if (remaining <= 0) return -1.0
    val sampleLimit = 2048
    val step = maxOf(1, remaining / sampleLimit)
    var sum = 0L
    var count = 0
    while (buffer.hasRemaining()) {
        sum += (buffer.get().toInt() and 0xFF).toLong()
        count += 1
        if (step > 1 && buffer.hasRemaining()) {
            buffer.position(min(buffer.limit(), buffer.position() + step - 1))
        }
    }
    return if (count == 0) -1.0 else sum.toDouble() / count.toDouble()
}
