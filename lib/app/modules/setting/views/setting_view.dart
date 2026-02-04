import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../data/service/theme_service.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/setting_controller.dart';

class SettingView extends GetView<SettingController> {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          // Real Theme Switcher
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text("Dark Theme"),
            trailing: Switch(
              value: ThemeService().isDarkMode,
              onChanged: (val) {
                ThemeService().switchTheme();
                (context as Element).markNeedsBuild(); // UI রিফ্রেশ
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text("App Tutorial"),
            onTap: () => Get.to(() => const TutorialView()),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Accuracy Info"),
            subtitle: Text("Data fetched directly from Kernel APIs"),
          ),
        ],
      ),
    );
  }
}

class TutorialView extends StatelessWidget {
  const TutorialView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tutorial")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            "How Amply Works?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            "1. Real-time mA: Positive values mean charging. Negative means battery consumption.",
          ),
          SizedBox(height: 10),
          Text(
            "2. Wave Animation: The height of the water represents your battery level.",
          ),
          SizedBox(height: 10),
          Text(
            "3. Smart Estimation: We calculate time to full based on current charging speed.",
          ),
        ],
      ),
    );
  }
}
