// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// import '../controllers/home_controller.dart';
// import 'package:get/get.dart';
//
// class BatteryHistoryView extends StatelessWidget {
//   final controller = Get.find<HomeController>();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0E21),
//       appBar: AppBar(title: const Text("Battery History")),
//       body: Obx(() => ListView.builder(
//         itemCount: controller.batteryHistory.length,
//         itemBuilder: (context, index) {
//           final log = controller.batteryHistory[index];
//           return ListTile(
//             leading: const Icon(Icons.access_time, color: Colors.orangeAccent),
//             title: Text("Battery at ${log['level']}%", style: const TextStyle(color: Colors.white)),
//             subtitle: Text("Time: ${log['time']}", style: const TextStyle(color: Colors.white54)),
//           );
//         },
//       )),
//     );
//   }
// }