import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  static const platform = MethodChannel('com.amply.app.amply_app/battery');

  // Battery
  var batteryLevel = 0.obs;
  var voltage = 0.obs;
  var temperature = 0.0.obs;
  var currentMA = 0.obs;
  var maxMA = (-9999).obs;
  var minMA = (9999).obs;
  var healthStatus = "Checking...".obs;
  var chargingSource = "Unknown".obs;
  var isCharging = false.obs;
  var technology = "Unknown".obs;
  var remainingTimeText = "Calculating...".obs;

  // Device & Resources
  var deviceModel = "".obs;
  var deviceBrand = "".obs;
  var androidVersion = "".obs;
  var totalStorage = 0.obs;
  var freeStorage = 0.obs;
  var totalRam = "0".obs;
  var availRam = "0".obs;
  var bluetoothStatus = "Unknown".obs;

  // Theme
  var isDarkMode = true.obs;
  Timer? _timer;
  bool _isFirstRecord = true;

  @override
  void onInit() {
    super.onInit();
    fetchDeviceInfo();
    fetchBatteryData();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => fetchBatteryData());
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeTheme(isDarkMode.value ? ThemeData.dark() : ThemeData.light());
  }

  Future<void> fetchDeviceInfo() async {
    try {
      final Map<dynamic, dynamic> info = await platform.invokeMethod('getDeviceInfo');
      deviceModel.value = info['model'];
      deviceBrand.value = info['brand'];
      androidVersion.value = info['androidVer'];
      totalStorage.value = info['totalStorage'];
      freeStorage.value = info['freeStorage'];
      totalRam.value = info['totalRam'];
      availRam.value = info['availRam'];
      bluetoothStatus.value = info['bluetooth'];
    } catch (e) { print(e); }
  }

  Future<void> fetchBatteryData() async {
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod('getBatteryHardwareInfo');
      batteryLevel.value = result['level'];
      voltage.value = result['voltage'];
      temperature.value = result['temperature'];
      currentMA.value = result['currentNow'];
      isCharging.value = result['status'] == 2;
      technology.value = result['technology'] ?? "Li-ion";

      if (_isFirstRecord) {
        maxMA.value = currentMA.value;
        minMA.value = currentMA.value;
        _isFirstRecord = false;
      } else {
        if (currentMA.value > maxMA.value) maxMA.value = currentMA.value;
        if (currentMA.value < minMA.value) minMA.value = currentMA.value;
      }

      // Time Estimation
      if (isCharging.value) {
        int remMs = result['remainingTime'];
        if (remMs > 0) {
          remainingTimeText.value = _formatMinutes((remMs / 60000).round());
        } else if (currentMA.value > 10) {
          double remPercent = (100 - batteryLevel.value) / 100;
          int estMin = ((remPercent * 5000) / currentMA.value.abs() * 60).round();
          remainingTimeText.value = "~ ${_formatMinutes(estMin)} (Est.)";
        } else { remainingTimeText.value = "Slow Charging"; }
      } else { remainingTimeText.value = "Discharging"; }

      _updateHealthStatus(result['health']);
      switch (result['plugged']) {
        case 1: chargingSource.value = "AC Charger"; break;
        case 2: chargingSource.value = "USB Port"; break;
        default: chargingSource.value = "Battery";
      }
    } on PlatformException catch (e) { print(e); }
  }

  void _updateHealthStatus(int h) {
    switch (h) {
      case 2: healthStatus.value = "Good"; break;
      case 3: healthStatus.value = "Overheat"; break;
      default: healthStatus.value = "Unknown";
    }
  }

  String _formatMinutes(int min) => min >= 60 ? "${min ~/ 60}h ${min % 60}m" : "${min}m";

  @override
  void onClose() { _timer?.cancel(); super.onClose(); }
}