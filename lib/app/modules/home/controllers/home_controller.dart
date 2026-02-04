import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class HomeController extends GetxController {
  static const platform = MethodChannel('com.amply.app.amply_app/battery');
  final _box = GetStorage();

  // Battery Obs
  var batteryLevel = 0.obs;
  var voltage = 0.obs;
  var temperature = 0.0.obs;
  var currentMA = 0.obs;
  var maxMA = (-9999).obs;
  var minMA = (9999).obs;
  var healthStatus = "Good".obs;
  var chargingSource = "Unknown".obs;
  var isCharging = false.obs;
  var technology = "Li-ion".obs;
  var remainingTimeText = "Calculating...".obs;

  // System & Analytics
  var totalRam = "0".obs;
  var availRam = "0".obs;
  var totalStorage = 0.obs;
  var freeStorage = 0.obs;
  var deviceName = "Unknown".obs;
  var androidVersion = "".obs;
  var bluetoothStatus = "Unknown".obs;
  var appUsageList = <dynamic>[].obs;
  var batteryHistory = <dynamic>[].obs;

  Timer? _timer;
  bool _isFirstRecord = true;

  var isUsagePermissionGranted = true.obs;

  @override
  void onInit() {
    super.onInit();
    batteryHistory.assignAll(_box.read('history') ?? []);
    fetchDeviceInfo();
    fetchAppUsage();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchBatteryData();
      if (isCharging.value) {
        platform.invokeMethod('updateNotification', {"mA": currentMA.value, "level": batteryLevel.value});
      } else {
        platform.invokeMethod('cancelNotification');
      }
    });

    // ৫ মিনিট অন্তর হিস্ট্রি সেভ
    Timer.periodic(const Duration(minutes: 5), (t) => _saveHistory());
  }

  Future<void> fetchBatteryData() async {
    try {
      final Map<dynamic, dynamic> r = await platform.invokeMethod('getBatteryHardwareInfo');
      batteryLevel.value = r['level'];
      voltage.value = r['voltage'];
      temperature.value = r['temperature'];
      currentMA.value = r['currentNow'];
      isCharging.value = r['status'] == 2;
      technology.value = r['technology'];

      if (_isFirstRecord) {
        maxMA.value = currentMA.value;
        minMA.value = currentMA.value;
        _isFirstRecord = false;
      } else {
        if (currentMA.value > maxMA.value) maxMA.value = currentMA.value;
        if (currentMA.value != 0 && currentMA.value < minMA.value) minMA.value = currentMA.value;
      }

      if (isCharging.value) {
        int remMs = r['remainingTime'];
        if (remMs > 0) {
          int m = (remMs / 60000).round();
          remainingTimeText.value = m >= 60 ? "${m ~/ 60}h ${m % 60}m" : "${m}m";
        } else if (currentMA.value > 10) {
          int estMin = (((100 - batteryLevel.value) / 100 * 5000) / currentMA.value.abs() * 60).round();
          remainingTimeText.value = "~ $estMin m (Est.)";
        }
      }

      switch (r['plugged']) {
        case 1: chargingSource.value = "AC Charger"; break;
        case 2: chargingSource.value = "USB Port"; break;
        default: chargingSource.value = "Battery";
      }
    } catch (e) { print(e); }
  }

  Future<void> fetchDeviceInfo() async {
    final Map<dynamic, dynamic> info = await platform.invokeMethod('getDeviceInfo');
    deviceName.value = "${info['brand']} ${info['model']}";
    androidVersion.value = info['androidVer'];
    totalRam.value = info['totalRam'];
    availRam.value = info['availRam'];
    totalStorage.value = info['totalStorage'];
    freeStorage.value = info['freeStorage'];
    bluetoothStatus.value = info['bluetooth'];
  }

  Future<void> fetchAppUsage() async {
    try {
      final List<dynamic> stats = await platform.invokeMethod('getAppUsage');
      appUsageList.assignAll(stats);
      isUsagePermissionGranted.value = true;
    } on PlatformException catch (e) {
      if (e.code == "PERMISSION_DENIED") {
        isUsagePermissionGranted.value = false;
        print("Usage access not granted");
      }
    }
  }

  void openUsageSettings() {
    platform.invokeMethod('openUsageSettings');
  }


  void _saveHistory() {
    final log = {"time": DateTime.now().toString().substring(11, 16), "level": batteryLevel.value};
    batteryHistory.insert(0, log);
    if (batteryHistory.length > 20) batteryHistory.removeLast();
    _box.write('history', batteryHistory.toList());
  }

  @override
  void onClose() { _timer?.cancel(); super.onClose(); }
}