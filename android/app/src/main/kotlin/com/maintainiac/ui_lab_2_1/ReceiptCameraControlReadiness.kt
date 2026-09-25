package com.maintainiac.ui_lab_2_1

import android.view.View

internal fun ReceiptCameraActivity.visibleControlSet(): String {
    val controls = mutableListOf(
        "back",
        "settings",
        "manual_shutter",
    )
    if (torchButton.isEnabled) controls.add("light")
    if (exposureControlsVisible()) controls.add("brightness")
    if (reviewNextControlReady()) {
        controls.add("long_receipt_done")
    }
    if (
        hasInitializedReceiptCameraField { addPhotoButton } &&
        addPhotoButton.visibility == View.VISIBLE &&
        addPhotoButton.isEnabled
    ) {
        controls.add("add_photo")
    }
    if (hasVisibleSectionGhostGuide()) {
        controls.add("section_ghost_guide")
    }
    if (edgeDetectionEnabled && edgeOverlayEnabled) controls.add("edge_guide")
    return controls.joinToString("|")
}

internal fun ReceiptCameraActivity.hasVisibleSectionGhostGuide(): Boolean {
    val previousVisible =
        hasInitializedReceiptCameraField { previousSectionGuidePanel } &&
            previousSectionGuidePanel.visibility == View.VISIBLE
    val nextVisible =
        hasInitializedReceiptCameraField { nextSectionGuidePanel } &&
            nextSectionGuidePanel.visibility == View.VISIBLE
    return previousVisible || nextVisible
}

internal fun ReceiptCameraActivity.reviewNextControlReady(): Boolean {
    val bottomReady =
        hasInitializedReceiptCameraField { bottomReviewButton } &&
            bottomReviewButton.visibility == View.VISIBLE &&
            bottomReviewButton.isEnabled
    return bottomReady
}

internal fun ReceiptCameraActivity.exposureControlsVisible(): Boolean {
    if (!hasInitializedReceiptCameraField { exposureSlider }) return false
    val parentView = exposureSlider.parent as? View
    return exposureSlider.visibility == View.VISIBLE &&
        parentView?.visibility == View.VISIBLE
}

internal fun ReceiptCameraActivity.controlStatus(visible: Boolean, enabled: Boolean): String {
    return when {
        visible && enabled -> "ready"
        visible -> "visible_disabled"
        else -> "missing"
    }
}

internal fun ReceiptCameraActivity.hasInitializedReceiptCameraField(
    access: ReceiptCameraActivity.() -> Any,
): Boolean {
    return try {
        access()
        true
    } catch (_: UninitializedPropertyAccessException) {
        false
    }
}

internal fun ReceiptCameraActivity.nativeControlReadinessSummary(): String {
    val statuses = listOf(
        backControlActualStatus(),
        settingsControlActualStatus(),
        manualShutterControlActualStatus(),
        reviewNextControlActualStatus(),
    )
    return if (statuses.any { it == "missing" || it == "visible_disabled" }) {
        "review_needed"
    } else {
        "ready"
    }
}

internal fun ReceiptCameraActivity.backControlActualStatus(): String {
    return controlStatus(visible = true, enabled = !closeResultDelivered)
}

internal fun ReceiptCameraActivity.settingsControlActualStatus(): String {
    return controlStatus(visible = true, enabled = !closeResultDelivered)
}

internal fun ReceiptCameraActivity.manualShutterControlActualStatus(): String {
    val visible = hasInitializedReceiptCameraField { shutterButton }
    val enabled = visible && shutterButton.isEnabled && !closingCamera && !closeResultDelivered
    return controlStatus(visible, enabled)
}

internal fun ReceiptCameraActivity.reviewNextControlActualStatus(): String {
    if (capturedPhotoPaths.isEmpty()) return "ready"
    val bottomVisible =
        hasInitializedReceiptCameraField { bottomReviewButton } &&
            bottomReviewButton.visibility == View.VISIBLE
    val visible = bottomVisible
    val enabled = bottomVisible && bottomReviewButton.isEnabled
    return controlStatus(visible, enabled)
}

internal fun ReceiptCameraActivity.tapFocusControlActualStatus(): String {
    return controlStatus(visible = false, enabled = false)
}

internal fun ReceiptCameraActivity.pinchZoomControlActualStatus(): String {
    val visible = hasInitializedReceiptCameraField { previewView } && pinchZoomEnabled
    val enabled = visible && camera != null && isCameraSurfaceActive()
    return controlStatus(visible, enabled)
}

internal fun ReceiptCameraActivity.exposureSliderControlActualStatus(): String {
    val visible = hasInitializedReceiptCameraField { exposureSlider } && exposureSliderEnabled
    val enabled = visible && exposureSlider.isEnabled
    return controlStatus(visible, enabled)
}

internal fun ReceiptCameraActivity.exposureResetControlActualStatus(): String {
    val visible = hasInitializedReceiptCameraField { exposureResetButton } && exposureResetEnabled
    val enabled = visible && exposureResetButton.isEnabled
    return controlStatus(visible, enabled)
}

internal fun ReceiptCameraActivity.torchControlActualStatus(): String {
    val hasTorch = camera?.cameraInfo?.hasFlashUnit() == true
    val visible = hasInitializedReceiptCameraField { torchButton } && hasTorch
    val enabled = visible && torchButton.isEnabled && camera != null && !closeResultDelivered
    return controlStatus(visible, enabled)
}

internal fun ReceiptCameraActivity.focusLockEnabled(): Boolean {
    return false
}

internal fun ReceiptCameraActivity.exposureLockEnabled(): Boolean {
    return false
}

internal fun ReceiptCameraActivity.focusLockControlActualStatus(): String {
    val visible = focusLockEnabled()
    val enabled = visible && camera != null && isCameraSurfaceActive()
    return controlStatus(visible, enabled)
}

internal fun ReceiptCameraActivity.exposureLockControlActualStatus(): String {
    val visible = exposureLockEnabled()
    val enabled = visible && camera != null && isCameraSurfaceActive()
    return controlStatus(visible, enabled)
}

internal fun ReceiptCameraActivity.whiteBalanceLockControlActualStatus(): String {
    return controlStatus(visible = false, enabled = false)
}
