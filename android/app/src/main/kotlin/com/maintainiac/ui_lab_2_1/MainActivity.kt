package com.maintainiac.ui_lab_2_1

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        DeviceWorkloadBridge(applicationContext).register(flutterEngine.dartExecutor.binaryMessenger)
        ReceiptRegionBridge(applicationContext).register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
