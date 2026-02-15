import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class NoisePainter extends CustomPainter {
  final double opacity;
  final double density;

  NoisePainter({this.opacity = 0.03, this.density = 0.6});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1.0;
    final random = Random(42); // Sabit seed ile hep aynı dokuyu ver (performans için)
    
    // Ekranın %0.5'i kadar nokta
    final count = (size.width * size.height * 0.005 * density).toInt();

    final points = <Offset>[];
    for (int i = 0; i < count; i++) {
      points.add(Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ));
    }

    paint.color = Colors.black.withValues(alpha: opacity);
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
