// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../controllers/home_controller.dart';
//
// class AppUsageView extends StatelessWidget {
//   final controller = Get.find<HomeController>();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0E21),
//       appBar: AppBar(title: const Text("App Usage Statistics")),
//       body: Obx(() => ListView.builder(
//         itemCount: controller.appUsageList.length,
//         itemBuilder: (context, index) {
//           final app = controller.appUsageList[index];
//           return ListTile(
//             title: Text(app['packageName'].split('.').last.toUpperCase(), style: const TextStyle(color: Colors.white)),
//             subtitle: Text("Time: ${(app['totalTime'] / 60).toStringAsFixed(1)} minutes", style: const TextStyle(color: Colors.white54)),
//             leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.android, size: 16)),
//           );
//         },
//       )),
//     );
//   }
// }
