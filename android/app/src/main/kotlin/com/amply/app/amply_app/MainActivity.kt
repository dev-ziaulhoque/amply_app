package com.amply.app.amply_app

import android.app.ActivityManager
import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.amply.app.amply_app/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryHardwareInfo" -> result.success(getBatteryHardwareInfo())
                "getDeviceInfo" -> result.success(getDeviceInfo())
                else -> result.notImplemented()
            }
        }
    }

    private fun getBatteryHardwareInfo(): Map<String, Any> {
        val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val info = mutableMapOf<String, Any>()

        intent?.let {
            info["level"] = it.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            info["voltage"] = it.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1)
            info["temperature"] = it.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) / 10.0
            info["status"] = it.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
            info["health"] = it.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)
            info["technology"] = it.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY) ?: "Li-ion"
            info["plugged"] = it.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val current = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
            info["currentNow"] = current / 1000
            info["chargeCounter"] = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER) / 1000
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info["remainingTime"] = batteryManager.computeChargeTimeRemaining()
        } else {
            info["remainingTime"] = -1L
        }
        return info
    }

    private fun getDeviceInfo(): Map<String, Any> {
        // Storage Info
        val stat = StatFs(Environment.getDataDirectory().path)
        val totalStorage = (stat.blockCountLong * stat.blockSizeLong) / (1024 * 1024 * 1024)
        val freeStorage = (stat.availableBlocksLong * stat.blockSizeLong) / (1024 * 1024 * 1024)

        // RAM Info
        val actManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memInfo = ActivityManager.MemoryInfo()
        actManager.getMemoryInfo(memInfo)
        val totalRam = memInfo.totalMem / (1024 * 1024 * 1024.0)
        val availRam = memInfo.availMem / (1024 * 1024 * 1024.0)

        // Bluetooth Info
        val mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        val btStatus = when {
            mBluetoothAdapter == null -> "Not Supported"
            mBluetoothAdapter.isEnabled -> "Enabled"
            else -> "Disabled"
        }

        return mapOf(
            "model" to Build.MODEL,
            "brand" to Build.MANUFACTURER,
            "androidVer" to Build.VERSION.RELEASE,
            "totalStorage" to totalStorage,
            "freeStorage" to freeStorage,
            "totalRam" to String.format("%.2f", totalRam),
            "availRam" to String.format("%.2f", availRam),
            "bluetooth" to btStatus
        )
    }
}