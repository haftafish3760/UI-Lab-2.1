package com.maintainiac.ui_lab_2_1

import android.os.SystemClock
import android.widget.Toast
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import java.io.File
import java.time.Instant


internal fun ReceiptCameraActivity.capturePhoto(
    trigger: String = "manual_shutter",
    recordUserIntent: Boolean = true,
) {
    lastCaptureBlockReason = "none"
    if (recordUserIntent && (trigger == "manual_shutter" || trigger == "manual_add_photo")) {
        manualShutterTapCount += 1
    } else if (recordUserIntent && trigger == "auto_capture") {
        autoCaptureAttemptCount += 1
    }
    val capture = imageCapture
    if (capture == null) {
        captureBlockedNoCameraCount += 1
        lastCaptureBlockReason = "no_camera"
        reportManualCaptureBlocked(trigger, "no_camera")
        return
    }
    if (captureInFlight) {
        captureBlockedBusyCount += 1
        lastCaptureBlockReason = "capture_in_flight"
        reportManualCaptureBlocked(trigger, "capture_in_flight")
        return
    }
    if (closingCamera) {
        captureBlockedClosingCount += 1
        lastCaptureBlockReason = "closing_camera"
        reportManualCaptureBlocked(trigger, "closing_camera")
        return
    }
    if (capturedPhotoPaths.size >= maxSectionCount) {
        guidance.text = "Review the captured photos before adding more sections."
        return
    }
    // Last-mile admission on the actual destination volume. The shared Dart
    // capability gate must also admit this session before native launch.
    val reserve = 100L * 1024 * 1024
    val captureBudget = maxLocalPhotoBytes.toLong().coerceAtLeast(12L * 1024 * 1024)
    if (filesDir.usableSpace - captureBudget < reserve) {
        lastCaptureBlockReason = "storage_reserve"
        guidance.text = "Not enough free storage to save safely. Your photos are kept. Free space before trying again."
        return
    }
    if (!isCameraSurfaceActive()) {
        captureBlockedSurfaceInactiveCount += 1
        lastCaptureBlockReason = "camera_surface_inactive"
        reportManualCaptureBlocked(trigger, "camera_surface_inactive")
        return
    }
    if (zoomApplyInFlight) {
        if (trigger == "manual_shutter" || trigger == "manual_add_photo") {
            pendingCaptureAfterZoomTrigger = trigger
            lastCaptureBlockReason = "waiting_for_zoom"
            guidance.text = "Applying zoom, then capturing your receipt."
        } else {
            latestAutoCaptureStatus = "waiting_for_zoom"
        }
        return
    }
    // Keep provenance tied to the capture that actually begins. A blocked
    // double-tap or auto-capture attempt must not overwrite an in-flight
    // manual capture's trigger.
    lastCaptureTrigger = trigger
    if (trigger == "manual_shutter" || trigger == "manual_add_photo") {
        manualCaptureStartedCount += 1
    } else if (trigger == "auto_capture") {
        autoCaptureStartedCount += 1
    }
    captureInFlight = true
    captureAttemptSequence += 1L
    val captureAttemptId = captureAttemptSequence
    activeCaptureAttemptId = captureAttemptId
    latestCaptureStartedElapsedMs = SystemClock.elapsedRealtime()
    latestCaptureToSavedMs = -1L
    latestCaptureToReviewReadyMs = -1L
    latestCaptureLatencyBucket = "capture_started"
    latestCaptureLiveBrightnessAtShutter = latestFrameBrightness
    val exposureState = camera?.cameraInfo?.exposureState
    val zoomState = camera?.cameraInfo?.zoomState?.value
    latestCaptureShutterExposureIndex = exposureState?.exposureCompensationIndex ?: 0
    latestCaptureShutterZoomRatio = (zoomState?.zoomRatio ?: 1f).toDouble()
    shutterButton.isEnabled = false
    val outputFile = try {
        newReceiptCaptureFile()
    } catch (_: Exception) {
        finishCaptureAttempt(captureAttemptId)
        shutterButton.isEnabled = true
        guidance.text = "Receipt storage is unavailable. Your existing photos are kept."
        return
    }
    captureShutterZoomByPath[outputFile.absolutePath] = latestCaptureShutterZoomRatio
    val outputOptions = ImageCapture.OutputFileOptions.Builder(outputFile).build()
    shutterButton.postDelayed(
        { handleCaptureTimeout(captureAttemptId, outputFile) },
        captureTimeoutMs,
    )
    prepareExposureBeforeCapture {
        performReceiptCapture(capture, outputFile, outputOptions, captureAttemptId)
    }
}

internal fun ReceiptCameraActivity.reportManualCaptureBlocked(trigger: String, reason: String) {
    // Live analysis may encounter the same condition repeatedly. Only surface
    // a message for an intentional manual action so the guidance stays stable.
    if (trigger != "manual_shutter" && trigger != "manual_add_photo") return
    if (!hasInitializedReceiptCameraField { guidance }) return
    guidance.text = when (reason) {
        "capture_in_flight" -> "Saving the last receipt photo. Please wait."
        "closing_camera" -> "Opening receipt photo review. Your photo is being kept."
        "camera_surface_inactive" -> "Receipt camera is still getting ready. Try again in a moment."
        else -> "Receipt camera is unavailable. Check camera permission, then try again."
    }
}

internal fun ReceiptCameraActivity.performReceiptCapture(
    capture: ImageCapture,
    outputFile: File,
    outputOptions: ImageCapture.OutputFileOptions,
    captureAttemptId: Long,
) {
    val activity = this
    if (!isCameraSurfaceActive() || activeCaptureAttemptId != captureAttemptId) {
        finishCaptureAttempt(captureAttemptId)
        pendingCloseAfterCapture = false
        // Retain partial/captured originals; deletion requires explicit user action.
        if (hasInitializedReceiptCameraField { shutterButton }) shutterButton.isEnabled = true
        reportManualCaptureBlocked(lastCaptureTrigger, "camera_surface_inactive")
        return
    }
    capture.takePicture(
        outputOptions,
        mainExecutor(),
        object : ImageCapture.OnImageSavedCallback {
            override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                if (!finishCaptureAttempt(captureAttemptId)) {
                    // Retain partial/captured originals; deletion requires explicit user action.
                    return
                }
                if (!isCameraSurfaceActive() || closeResultDelivered) return
                val capturedAt = Instant.now().toString()
                latestCaptureToSavedMs = captureElapsedSinceStart()
                latestCaptureLatencyBucket = captureLatencyBucket(latestCaptureToSavedMs)
                val savedByteSize = outputFile.length()
                if (
                    maxLocalPhotoBytes > 0 &&
                    totalCapturedByteSize + savedByteSize > maxLocalPhotoBytes
                ) {
                    val shouldReturnExistingSections =
                        pendingCloseAfterCapture && capturedPhotoPaths.isNotEmpty()
                    // Retain partial/captured originals; deletion requires explicit user action.
                    latestCaptureLatencyBucket = "capture_rejected_over_byte_budget"
                    lastCaptureBlockReason = "native_capture_over_byte_budget"
                    latestAutoCaptureStatus = "native_capture_over_byte_budget"
                    pendingCloseAfterCapture = false
                    shutterButton.isEnabled = true
                    updateDoneButton()
                    guidance.text =
                        "That receipt photo was too large for this device setting. Try again with the receipt closer and clearer."
                    if (shouldReturnExistingSections) {
                        finishWithCapturedPhotos(
                            closeReason = "back_capture_failed_returned_existing_sections",
                        )
                    }
                    return
                }
                if (firstCapturedAt == null) firstCapturedAt = capturedAt
                capturedPhotoPaths.add(outputFile.absolutePath)
                totalCapturedByteSize += savedByteSize
                // Capture must return to photo review immediately. Quality
                // checks, receipt assembly, and text extraction happen only
                // after the person taps Continue with every section present.
                captureInFlight = false
                autoCaptureCooldownUntilMs =
                    System.currentTimeMillis() + autoCaptureCooldownMs
                if (pendingCloseAfterCapture) {
                    pendingCloseAfterCapture = false
                    finishWithCapturedPhotos(closeReason = "back_returned_captured_sections")
                    return
                }
                finishWithCapturedPhotos(closeReason = "capture_saved_open_review")
            }

            override fun onError(exception: ImageCaptureException) {
                if (!finishCaptureAttempt(captureAttemptId)) return
                captureShutterZoomByPath.remove(outputFile.absolutePath)
                if (!isCameraSurfaceActive() || closeResultDelivered) return
                if (pendingCloseAfterCapture) {
                    finishPendingCloseAfterCaptureFailure()
                    return
                }
                pendingCloseAfterCapture = false
                shutterButton.isEnabled = true
                guidance.text = "That photo did not save. Try again."
                Toast.makeText(
                    activity,
                    "Receipt photo did not save.",
                    Toast.LENGTH_SHORT,
                ).show()
            }
        },
    )
}

internal fun ReceiptCameraActivity.finishCaptureAttempt(captureAttemptId: Long): Boolean {
    if (activeCaptureAttemptId != captureAttemptId) return false
    activeCaptureAttemptId = 0L
    captureInFlight = false
    return true
}

internal fun ReceiptCameraActivity.handleCaptureTimeout(
    captureAttemptId: Long,
    outputFile: File,
) {
    if (!finishCaptureAttempt(captureAttemptId) || closeResultDelivered) return
    captureTimeoutCount += 1
    // Retain partial/captured originals; deletion requires explicit user action.
    captureShutterZoomByPath.remove(outputFile.absolutePath)
    latestCaptureLatencyBucket = "capture_timed_out"
    lastCaptureBlockReason = "capture_timeout"
    latestAutoCaptureStatus = "capture_timeout"
    val closeWasPending = pendingCloseAfterCapture
    pendingCloseAfterCapture = false
    if (closeWasPending && capturedPhotoPaths.isNotEmpty()) {
        finishWithCapturedPhotos(
            closeReason = "back_capture_failed_returned_existing_sections",
        )
        return
    }
    if (closeWasPending) {
        cancelWithoutCapturedPhoto("back_capture_failed_cancel")
        return
    }
    shutterButton.isEnabled = true
    updateDoneButton()
    guidance.text = "That receipt photo took too long. Try the shutter again."
    Toast.makeText(this, "Receipt photo timed out. Try again.", Toast.LENGTH_SHORT).show()
}

internal fun ReceiptCameraActivity.requestCloseCamera(backDispatchPath: String = "unknown") {
    closeRequestCount += 1
    lastBackDispatchPath = backDispatchPath
    if (closeResultDelivered) {
        closeRetryCount += 1
        if (!isFinishing && !isDestroyed) {
            finish()
        }
        return
    }
    if (captureInFlight) {
        closeDuringCaptureCount += 1
        pendingCloseAfterCapture = true
        latestAutoCaptureStatus = "closing_after_capture"
        shutterButton.isEnabled = false
        if (hasInitializedReceiptCameraField { addPhotoButton }) addPhotoButton.isEnabled = false
        if (hasInitializedReceiptCameraField { bottomReviewButton }) bottomReviewButton.isEnabled = false
        guidance.text = "Saving this receipt photo before opening review."
        return
    }
    closingCamera = true
    latestAutoCaptureStatus = "closing"
    if (capturedPhotoPaths.isEmpty()) {
        guidance.text = "Closing receipt camera without saving a photo."
        cancelWithoutCapturedPhoto("back_no_photo_cancel")
        return
    }
    guidance.text = "Opening receipt photo review. Captured photos are kept."
    finishWithCapturedPhotos(closeReason = "back_returned_captured_sections")
}
