package com.maintainiac.ui_lab_2_1

import io.flutter.plugins.imagepicker.ReceiptCameraHandoff
import java.io.File

/** File hashing and durability checks must not block preview rendering. */
internal fun ReceiptCameraActivity.checkpointCapturedPhoto(file: File, ready: () -> Unit) {
    val requestKey = intent.getStringExtra("receiptRequestKey")
    try {
        receiptPhotoQualityExecutor.execute {
            val saved = runCatching {
                ReceiptCameraHandoff(applicationContext).use {
                    it.complete(requestKey, file.absolutePath)
                }
            }.isSuccess
            runOnUiThread {
                if (saved) {
                    // Even a late callback checkpoints its bytes before the
                    // capture-attempt guard decides whether to update the UI.
                    ready()
                } else if (!isFinishing && !isDestroyed) {
                    captureInFlight = false
                    pendingCloseAfterCapture = false
                    shutterButton.isEnabled = true
                    guidance.text = "Your photo is kept, but saving its recovery record failed. Try review again."
                }
            }
        }
    } catch (_: java.util.concurrent.RejectedExecutionException) {
        // The request/path was saved before capture. A closing activity must
        // not delete the resulting file or report it as successfully delivered.
    }
}
