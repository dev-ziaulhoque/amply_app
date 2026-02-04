package com.amply.app.amply_app

import android.app.*
import android.app.usage.UsageStatsManager
import android.bluetooth.BluetoothAdapter
import android.content.*
import android.os.*
import android.provider.Settings
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.amply.app.amply_app/battery"
    private val NOTIFICATION_ID = 999
    private val NOTIFICATION_CHANNEL_ID = "Amply_Monitor_Channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryHardwareInfo" -> result.success(getBatteryHardwareInfo())
                "getDeviceInfo" -> result.success(getDeviceInfo())
                "getAppUsage" -> {
                    if (hasUsageStatsPermission()) {
                        result.success(getAppUsageStats())
                    } else {
                        result.error("PERMISSION_DENIED", "Usage access not granted", null)
                    }
                }
                "openUsageSettings" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "updateNotification" -> {
                    val mA = call.argument<Int>("mA") ?: 0
                    val level = call.argument<Int>("level") ?: 0
                    showChargingNotification(mA, level)
                    result.success(true)
                }
                "cancelNotification" -> {
                    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    manager.cancel(NOTIFICATION_ID)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ১. ব্যাটারি হার্ডওয়্যার ইনফো (রিয়েল-টাইম mA সহ)
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
            // চার্জিং অবস্থায় পজিটিভ, ডিসচার্জিং অবস্থায় নেগেটিভ
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

    // ২. ডিভাইস রিসোর্স ইনফো (RAM, Storage, Bluetooth)
    private fun getDeviceInfo(): Map<String, Any> {
        // Storage
        val stat = StatFs(Environment.getDataDirectory().path)
        val totalStorage = (stat.blockCountLong * stat.blockSizeLong) / (1024 * 1024 * 1024)
        val freeStorage = (stat.availableBlocksLong * stat.blockSizeLong) / (1024 * 1024 * 1024)

        // RAM
        val actManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memInfo = ActivityManager.MemoryInfo()
        actManager.getMemoryInfo(memInfo)
        val totalRam = memInfo.totalMem / (1024.0 * 1024 * 1024)
        val availRam = memInfo.availMem / (1024.0 * 1024 * 1024)

        // Bluetooth
        val btAdapter = BluetoothAdapter.getDefaultAdapter()
        val btStatus = when {
            btAdapter == null -> "Unsupported"
            btAdapter.isEnabled -> "Active"
            else -> "Inactive"
        }

        return mapOf(
            "model" to Build.MODEL,
            "brand" to Build.MANUFACTURER,
            "androidVer" to Build.VERSION.RELEASE,
            "totalStorage" to totalStorage,
            "freeStorage" to freeStorage,
            "totalRam" to String.format("%.1f", totalRam),
            "availRam" to String.format("%.1f", availRam),
            "bluetooth" to btStatus
        )
    }

    // ৩. অ্যাপ ইউজ স্ট্যাটাস (গত ২৪ ঘণ্টা)
    private fun getAppUsageStats(): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - (24 * 60 * 60 * 1000)

        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val usageList = mutableListOf<Map<String, Any>>()

        if (stats != null) {
            val sortedStats = stats.filter { it.totalTimeInForeground > 0 }
                .sortedByDescending { it.totalTimeInForeground }
                .take(15)

            for (stat in sortedStats) {
                val map = mutableMapOf<String, Any>()
                map["package"] = stat.packageName
                map["time"] = stat.totalTimeInForeground / 1000 // সেকেন্ড
                usageList.add(map)
            }
        }
        return usageList
    }

    // ৪. ইউজ এক্সেস পারমিশন চেক
    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        return mode == AppOpsManager.MODE_ALLOWED
    }

    // ৫. চার্জিং নোটিফিকেশন (Foreground Service Style)
    private fun showChargingNotification(mA: Int, level: Int) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, "Amply Monitor", NotificationManager.IMPORTANCE_LOW)
            channel.description = "Displays real-time charging current"
            manager.createNotificationChannel(channel)
        }

        val notificationText = "Current Flow: +$mA mA"
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Amply Fast Charging: $level%")
            .setContentText(notificationText)
            .setSmallIcon(android.R.drawable.stat_sys_upload_done)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true) // ইউজার সোয়াইপ করে সরাতে পারবে না
            .setOnlyAlertOnce(true) // বারবার সাউন্ড বা ভাইব্রেশন হবে না
            .build()

        manager.notify(NOTIFICATION_ID, notification)
    }
}