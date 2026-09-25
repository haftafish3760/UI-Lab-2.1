package com.maintainiac.ui_lab_2_1

import android.app.Activity
import android.Manifest
import android.content.Intent
import android.content.Context
import android.hardware.camera2.CameraManager
import android.os.BatteryManager
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.Shadows.shadowOf
import org.robolectric.shadows.ShadowCameraCharacteristics

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28, 33])
class DeviceExtendedProbeTest {
    @Test fun cameraCacheRefreshesOnPermissionChangeAndExpiration() {
        val owner = Robolectric.buildActivity(Activity::class.java).setup()
        try {
            val activity = owner.get()
            val application = shadowOf(activity.application)
            application.denyPermissions(Manifest.permission.CAMERA)
            val manager = shadowOf(activity.getSystemService(Context.CAMERA_SERVICE) as CameraManager)
            val probe = DeviceExtendedProbe(activity)
            fun addCamera(id: String) = manager.addCamera(id,
                ShadowCameraCharacteristics.newCameraCharacteristics())
            fun lensCount() = (probe.read()["cameraLenses"] as List<*>).size
            addCamera("first")
            assertEquals(1, lensCount())
            addCamera("second")
            assertEquals("Static metadata should be cached", 1, lensCount())
            application.grantPermissions(Manifest.permission.CAMERA)
            assertEquals("Authorization change must refresh metadata", 2, lensCount())
            addCamera("third")
            assertEquals(2, lensCount())
            // Robolectric advances its simulated clock; no wall-clock sleep.
            android.os.SystemClock.sleep(600_001)
            assertEquals("Expired metadata must refresh", 3, lensCount())
        } finally { owner.pause().stop().destroy() }
    }
    @Test fun incompleteCameraMetadataDoesNotClaimUnsupportedFeatures() {
        val owner = Robolectric.buildActivity(Activity::class.java).setup()
        try {
            val manager = owner.get().getSystemService(Context.CAMERA_SERVICE) as CameraManager
            shadowOf(manager).addCamera("synthetic-camera", ShadowCameraCharacteristics.newCameraCharacteristics())
            val lenses = DeviceExtendedProbe(owner.get()).read()["cameraLenses"] as List<*>
            assertEquals(1, lenses.size)
            val lens = lenses.first() as Map<*, *>
            for (field in listOf("supportsRaw", "supportsTorch", "supportsAutofocus",
                "supportsStabilization", "supportsTapFocus", "supportsHdr",
                "maxZoomRatio", "maxDigitalZoom")) {
                assertFalse("Missing $field must remain unknown", lens.containsKey(field))
            }
            assertFalse(lens.toString().contains("synthetic-camera"))
        } finally { owner.pause().stop().destroy() }
    }
    @Suppress("DEPRECATION")
    @Test fun absentBatteryExtrasRemainUnknown() {
        val owner = Robolectric.buildActivity(Activity::class.java).setup()
        try {
            owner.get().sendStickyBroadcast(Intent(Intent.ACTION_BATTERY_CHANGED))
            val battery = DeviceExtendedProbe(owner.get()).read()["battery"] as Map<*, *>
            for (field in listOf("levelPercent", "isCharging", "isExternalPowerConnected",
                "powerSource", "temperatureCelsius")) {
                assertFalse("Missing $field must not become a value", battery.containsKey(field))
            }
        } finally { owner.pause().stop().destroy() }
    }
    @Test fun unavailableGroupsDoNotDiscardOtherObservations() {
        val owner = Robolectric.buildActivity(Activity::class.java).setup()
        try {
            val result = DeviceExtendedProbe(owner.get()).read()
            assertTrue(result.containsKey("battery"))
            assertTrue(result.containsKey("sensors"))
            assertTrue(result.containsKey("display"))
            assertTrue(result.containsKey("connectivity"))
            assertFalse(result.containsKey("deviceId"))
            assertFalse(result.containsKey("registeredOwner"))
        } finally { owner.pause().stop().destroy() }
    }

    @Suppress("DEPRECATION")
    @Test fun liveBatteryRefreshIsNotHeldInStaticCameraCache() {
        val owner = Robolectric.buildActivity(Activity::class.java).setup()
        try {
            val activity = owner.get()
            val probe = DeviceExtendedProbe(activity)
            fun battery(level: Int, temperature: Int): Map<*, *> {
                activity.sendStickyBroadcast(Intent(Intent.ACTION_BATTERY_CHANGED).apply {
                    putExtra(BatteryManager.EXTRA_LEVEL, level)
                    putExtra(BatteryManager.EXTRA_SCALE, 100)
                    putExtra(BatteryManager.EXTRA_TEMPERATURE, temperature)
                    putExtra(BatteryManager.EXTRA_PLUGGED, 0)
                })
                return probe.read()["battery"] as Map<*, *>
            }
            assertEquals(80, battery(80, 300)["levelPercent"])
            val hot = battery(5, 470)
            assertEquals(5, hot["levelPercent"])
            assertEquals(47.0, hot["temperatureCelsius"])
        } finally { owner.pause().stop().destroy() }
    }
}
