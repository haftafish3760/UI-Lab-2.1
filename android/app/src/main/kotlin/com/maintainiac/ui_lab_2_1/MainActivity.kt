package com.maintainiac.ui_lab_2_1

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var receiptCameraBridge: ReceiptCameraBridge? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        DeviceWorkloadBridge(this).register(flutterEngine.dartExecutor.binaryMessenger)
        ReceiptRegionBridge(applicationContext).register(flutterEngine.dartExecutor.binaryMessenger)
        receiptCameraBridge = ReceiptCameraBridge(this).also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        if (receiptCameraBridge?.activityResult(requestCode, resultCode, data) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        if (receiptCameraBridge?.permissionResult(requestCode, grantResults) == true) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onDestroy() {
        receiptCameraBridge?.dispose()
        super.onDestroy()
    }
}
