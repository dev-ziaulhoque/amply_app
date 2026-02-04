import 'package:amply_app/app/modules/setting/views/setting_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../animation/smart_charging_animation.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text(
          "Amply Lab Pro",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Get.to(() => const SettingView()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Obx(
          () => Column(
            children: [
              _buildLargeCard(),
              const SizedBox(height: 20),
              if (controller.isCharging.value) _buildTimeBadge(),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildInfoBox(
                    "Voltage",
                    "${controller.voltage} mV",
                    Icons.bolt,
                    Colors.orange,
                  ),
                  _buildInfoBox(
                    "Temp",
                    "${controller.temperature}°C",
                    Icons.thermostat,
                    Colors.red,
                  ),
                  _buildInfoBox(
                    "Health",
                    controller.healthStatus.value,
                    Icons.favorite,
                    Colors.green,
                  ),
                  _buildInfoBox(
                    "Source",
                    controller.chargingSource.value,
                    Icons.power,
                    Colors.blue,
                  ),
                ],
              ),

              _section("Memory & Storage"),
              _buildResourceCard(
                "RAM Usage",
                controller.totalRam.value,
                controller.availRam.value,
                Colors.purpleAccent,
              ),
              const SizedBox(height: 15),
              _buildResourceCard(
                "Storage Usage",
                "${controller.totalStorage.value}GB",
                "${controller.freeStorage.value}GB",
                Colors.blueAccent,
              ),

              _section("System Info"),
              _buildContainer([
                _row(
                  "Device",
                  "${controller.deviceBrand} ${controller.deviceModel}",
                ),
                _row("Android", "Version ${controller.androidVersion}"),
                _row("Bluetooth", controller.bluetoothStatus.value),
                _row("Tech", controller.technology.value),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          SmartChargingAnimation(
            level: controller.batteryLevel.value / 100.0,
            isCharging: controller.isCharging.value,
          ),
          const SizedBox(height: 15),
          Text(
            controller.isCharging.value ? "CHARGING" : "DISCHARGING",
            style: TextStyle(
              color: controller.isCharging.value
                  ? Colors.greenAccent
                  : Colors.orangeAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Divider(color: Colors.white10, height: 30),
          Text(
            "${controller.currentMA.value > 0 ? '+' : ''}${controller.currentMA} mA",
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "Min: ${controller.minMA} mA",
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
              Text(
                "Max: ${controller.maxMA} mA",
                style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(
    String title,
    String totalStr,
    String availStr,
    Color color,
  ) {
    double total = double.tryParse(totalStr.replaceAll("GB", "")) ?? 0;
    double avail = double.tryParse(availStr.replaceAll("GB", "")) ?? 0;
    double progress = total > 0 ? (total - avail) / total : 0;
    return _buildContainer([
      _row(title, "$avail / $total"),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: progress.clamp(0, 1),
        color: color,
        backgroundColor: Colors.white10,
      ),
    ]);
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        t,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
  Widget _buildContainer(List<Widget> c) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(children: c),
  );
  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: Colors.white38)),
        Text(v, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
  Widget _buildInfoBox(String t, String v, IconData i, Color c) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(i, color: c),
        const SizedBox(height: 5),
        Text(t, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        Text(
          v,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
  Widget _buildTimeBadge() => Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.greenAccent.withOpacity(0.1),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.bolt, color: Colors.greenAccent),
        const SizedBox(width: 8),
        Text(
          "FULL IN: ${controller.remainingTimeText}",
          style: const TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
