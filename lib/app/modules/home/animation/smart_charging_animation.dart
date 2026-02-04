import 'dart:math';
import 'package:flutter/material.dart';

class SmartChargingAnimation extends StatefulWidget {
  final double level;
  final bool isCharging;

  const SmartChargingAnimation({super.key, required this.level, required this.isCharging});

  @override
  State<SmartChargingAnimation> createState() => _SmartChargingAnimationState();
}

class _SmartChargingAnimationState extends State<SmartChargingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isCharging)
              Container(
                height: 180, width: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.2 + (0.1 * sin(_controller.value * 2 * pi))),
                      blurRadius: 20, spreadRadius: 10,
                    )
                  ],
                ),
              ),
            Container(
              height: 150, width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: widget.isCharging ? Colors.greenAccent : Colors.white24, width: 2),
              ),
              child: ClipOval(
                child: CustomPaint(
                  painter: WavePainter(animationValue: _controller.value, level: widget.level, isCharging: widget.isCharging),
                ),
              ),
            ),
            Text("${(widget.level * 100).toInt()}%", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue, level;
  final bool isCharging;
  WavePainter({required this.animationValue, required this.level, required this.isCharging});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = isCharging ? Colors.greenAccent.withOpacity(0.5) : Colors.blueAccent.withOpacity(0.3);
    Path path = Path();
    double yOffset = size.height * (1 - level);
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(i, yOffset + 7 * sin((i / size.width * 2 * pi) + (animationValue * 2 * pi)));
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}