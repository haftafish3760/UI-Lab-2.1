package com.maintainiac.ui_lab_2_1

import android.graphics.Bitmap
import android.os.Looper
import android.view.View
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.LooperMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
@LooperMode(LooperMode.Mode.PAUSED)
class ReceiptGuideLifecycleTest {
    @Test fun clearingEitherGuideRejectsQueuedDecode() {
        val activity = Robolectric.buildActivity(ReceiptCameraActivity::class.java).get()
        val release = CountDownLatch(1)
        try {
            activity.buildPreviousSectionGuide()
            activity.buildNextSectionGuide()
            // Hold the real serial decoder so both selection and clear happen
            // before decoding. Expected state comes from the user's clear action.
            activity.receiptPhotoQualityExecutor.submit {
                check(release.await(10, TimeUnit.SECONDS))
            }
            val photo = File(activity.cacheDir, "guide-fixture.png")
            val bitmap = Bitmap.createBitmap(20, 60, Bitmap.Config.ARGB_8888)
            photo.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
            bitmap.recycle()
            activity.updatePreviousSectionGuide(photo.path)
            activity.updateNextSectionGuide(photo.path)
            activity.updatePreviousSectionGuide(null)
            activity.updateNextSectionGuide("missing.png")
            release.countDown()
            activity.receiptPhotoQualityExecutor.submit {}.get(10, TimeUnit.SECONDS)
            shadowOf(Looper.getMainLooper()).idle()
            assertEquals(View.GONE, activity.previousSectionGuidePanel.visibility)
            assertEquals(View.GONE, activity.nextSectionGuidePanel.visibility)
            assertNull(activity.previousSectionGuideImage.drawable)
            assertNull(activity.nextSectionGuideImage.drawable)
        } finally {
            release.countDown()
            activity.receiptPhotoQualityExecutor.shutdownNow()
            activity.cameraAnalysisExecutor.shutdownNow()
        }
    }
}
