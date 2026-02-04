import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class AppUsageView extends StatelessWidget {
  const AppUsageView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    // ভিউ ওপেন করার সময় ডাটা রিফ্রেশ করা
    controller.fetchAppUsage();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(title: const Text("App Usage Statistics")),
      body: Obx(() {
        if (!controller.isUsagePermissionGranted.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, color: Colors.orangeAccent, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    "Usage Access Required",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "To see which apps are consuming battery, please grant 'Usage Access' permission from settings.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => controller.openUsageSettings(),
                    child: const Text("Grant Permission"),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.appUsageList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: controller.appUsageList.length,
          itemBuilder: (context, index) {
            final app = controller.appUsageList[index];
            String packageName = app['package'].toString();
            String appName = packageName.split('.').last.toUpperCase();
            double minutes = app['time'] / 60;

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.android, color: Colors.white),
              ),
              title: Text(appName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(packageName, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              trailing: Text(
                "${minutes.toStringAsFixed(1)} min",
                style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      }),
    );
  }
}