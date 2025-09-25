import 'package:flutter/material.dart';
import 'dart:math' as math;

class SemiCircleProgress extends StatelessWidget {
  final double caloriesPercent;
  final double stepsPercent;
  final double movingPercent;

  const SemiCircleProgress({
    super.key,
    required this.caloriesPercent,
    required this.stepsPercent,
    required this.movingPercent,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(250, 160), // Increased size
      painter: _SemiCirclePainter(
        caloriesPercent: caloriesPercent,
        stepsPercent: stepsPercent,
        movingPercent: movingPercent,
      ),
    );
  }
}

class _SemiCirclePainter extends CustomPainter {
  final double caloriesPercent;
  final double stepsPercent;
  final double movingPercent;

  _SemiCirclePainter({
    required this.caloriesPercent,
    required this.stepsPercent,
    required this.movingPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20); // Adjusted center
    final radius = size.width / 2 - 30; // Increased radius
    final strokeWidth = 30.0;
    final gap =
        5.0; // Gap between progress bars (Decrease this value to reduce space between semi-circles)

    // Convert percentages to radians (180 degrees = π radians)
    final caloriesSweep = math.pi * caloriesPercent / 100;
    final stepsSweep = math.pi * stepsPercent / 100;
    final movingSweep = math.pi * movingPercent / 100;

    // Draw background arcs (darker colors for goals) with straight edges
    final backgroundPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    // Calories background (darker red-orange)
    backgroundPaint.color = Colors.deepOrange.withOpacity(0.3);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // Start at 180 degrees (π radians)
      math.pi, // Full 180 degrees for background
      false,
      backgroundPaint,
    );

    // Steps background (darker yellow-orange) with gap
    backgroundPaint.color = Colors.amber.withOpacity(0.3);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth - gap),
      math.pi, // Start at 180 degrees (π radians)
      math.pi, // Full 180 degrees for background
      false,
      backgroundPaint,
    );

    // Moving background (darker blue) with gap
    backgroundPaint.color = Colors.blue.withOpacity(0.3);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2 * (strokeWidth + gap)),
      math.pi, // Start at 180 degrees (π radians)
      math.pi, // Full 180 degrees for background
      false,
      backgroundPaint,
    );

    // Draw progress arcs (lighter colors for progress) with straight ends
    // Calories progress (lighter red-orange)
    _drawCustomProgressArc(
      canvas,
      center,
      radius,
      math.pi,
      caloriesSweep,
      Colors.deepOrange,
      strokeWidth,
    );

    // Steps progress (lighter yellow-orange) with gap
    _drawCustomProgressArc(
      canvas,
      center,
      radius - strokeWidth - gap,
      math.pi,
      stepsSweep,
      Colors.amber,
      strokeWidth,
    );

    // Moving progress (lighter blue) with gap
    _drawCustomProgressArc(
      canvas,
      center,
      radius - 2 * (strokeWidth + gap),
      math.pi,
      movingSweep,
      Colors.blue,
      strokeWidth,
    );
  }

  void _drawCustomProgressArc(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    Color color,
    double strokeWidth,
  ) {
    if (sweepAngle <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Draw the progress arc with straight ends
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
