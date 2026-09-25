package com.maintainiac.ui_lab_2_1

import android.content.BroadcastReceiver
import android.content.ComponentCallbacks2
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.os.Build
import android.os.PowerManager
import android.os.Handler
import android.os.Looper
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

/** Health notifications only; never Bluetooth/network identities or samples. */
class DeviceResourceEvents(private val context: Context) : EventChannel.StreamHandler, ComponentCallbacks2 {
    private var sink: EventChannel.EventSink? = null
    private var registered = false
    private var thermal: PowerManager.OnThermalStatusChangedListener? = null
    private var network: ConnectivityManager.NetworkCallback? = null
    private val main = Handler(Looper.getMainLooper())
    private var generation = 0
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) { sink?.success("health") }
    }
    fun register(messenger: BinaryMessenger) {
        EventChannel(messenger, "app.device_capability_events").setStreamHandler(this)
    }
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        onCancel(null)
        sink = events
        ContextCompat.registerReceiver(context, receiver, IntentFilter().apply {
            addAction(Intent.ACTION_BATTERY_CHANGED)
            addAction(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
        }, ContextCompat.RECEIVER_NOT_EXPORTED)
        context.registerComponentCallbacks(this)
        registered = true
        if (Build.VERSION.SDK_INT >= 24) {
            val current = generation
            val callback = object : ConnectivityManager.NetworkCallback() {
                private fun changed() { main.post {
                    if (current == generation) sink?.success("network")
                } }
                override fun onAvailable(network: Network) = changed()
                override fun onLost(network: Network) = changed()
                override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) = changed()
            }
            runCatching {
                (context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager)
                    .registerDefaultNetworkCallback(callback)
                network = callback
            }
        }
        if (Build.VERSION.SDK_INT >= 29) {
            val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val listener = PowerManager.OnThermalStatusChangedListener { sink?.success("thermal") }
            runCatching {
                power.addThermalStatusListener(ContextCompat.getMainExecutor(context), listener)
                thermal = listener
            }
        }
        sink?.success("ready")
    }
    override fun onCancel(arguments: Any?) {
        sink = null
        generation++
        network?.let { callback -> runCatching {
            (context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager)
                .unregisterNetworkCallback(callback)
        } }
        network = null
        if (registered) {
            runCatching { context.unregisterReceiver(receiver) }
            context.unregisterComponentCallbacks(this)
            registered = false
        }
        if (Build.VERSION.SDK_INT >= 29) {
            thermal?.let { listener ->
                val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                runCatching { power.removeThermalStatusListener(listener) }
            }
        }
        thermal = null
    }
    override fun onLowMemory() { sink?.success("memory") }
    override fun onTrimMemory(level: Int) {
        // UI_HIDDEN is a lifecycle transition, not evidence of memory pressure.
        if (level == ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW ||
            level == ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL ||
            level >= ComponentCallbacks2.TRIM_MEMORY_BACKGROUND) sink?.success("memory")
    }
    override fun onConfigurationChanged(configuration: Configuration) {}
}
