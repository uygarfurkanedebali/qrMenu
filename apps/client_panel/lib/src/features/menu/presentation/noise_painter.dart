import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class NoisePainter extends CustomPainter {
  final double opacity;
  final Color color;

  NoisePainter({
    this.opacity = 0.05,
    this.color = const Color(0xFF000000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random();
    
    // We draw small points to simulate noise
    // For performance, instead of drawing millions of points, we can draw fewer larger points or use a shader.
    // However, for a simple paper effect, drawing points on a slightly lower resolution and scaling or just drawing enough points works.
    // A better approach for Flutter is often to use an image pattern, but we want procedural.
    // Let's try drawing a lot of small rects/points. 
    
    // Optimization: Draw noise on a smaller area and tile it? 
    // Or just fill the screen with random noise. 
    // Listing 10,000 points might be heavy every frame if animating, but this is static.
    // Actually, CustomPainter repaints when shouldRepaint returns true.
    
    paint.color = color.withValues(alpha: opacity);
    paint.style = PaintingStyle.fill;
    
    // Draw noise
    // Density: cover about 10-20% of pixels?
    // Let's do a simple loop.
    
    const double density = 0.2; // 20% coverage
    const double grainSize = 1.0;
    
    // It's too slow to draw individual pixels for the whole screen in Dart loop.
    // Better approach: Use a specific blend mode with a saved noise image asset?
    // But requirement was "Procedural noise using CustomPainter (NoisePainter) instead of an image asset."
    // Okay. To make it performant, we can draw fewer, larger grains, or use `drawPoints`.
    
    final List<Offset> points = [];
    final int count = (size.width * size.height * 0.005).toInt().clamp(0, 10000); 
    // Limit to 10k points for performance. 0.005 is 0.5% coverage. 
    // Adjust logic:
    
    for (int i = 0; i < count; i++) {
        final double x = random.nextDouble() * size.width;
        final double y = random.nextDouble() * size.height;
        points.add(Offset(x, y));
    }
    
    paint.strokeWidth = grainSize;
    paint.strokeCap = StrokeCap.square;
    
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
