import 'package:flutter/material.dart';
import 'dart:math' as math;

class SemiCircleProgress extends StatefulWidget {
  final double caloriesPercent;
  final double stepsPercent;
  final double movingPercent;
  final String caloriesValue;
  final String caloriesGoal;
  final String stepsValue;
  final String stepsGoal;
  final String movingValue;
  final String movingGoal;

  const SemiCircleProgress({
    super.key,
    required this.caloriesPercent,
    required this.stepsPercent,
    required this.movingPercent,
    this.caloriesValue = "",
    this.caloriesGoal = "",
    this.stepsValue = "",
    this.stepsGoal = "",
    this.movingValue = "",
    this.movingGoal = "",
  });

  @override
  State<SemiCircleProgress> createState() => _SemiCircleProgressState();
}

class _SemiCircleProgressState extends State<SemiCircleProgress> {
  String? _selectedSection;
  Offset? _tooltipPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (TapUpDetails details) {
        RenderBox renderBox = context.findRenderObject() as RenderBox;
        Offset localPosition = renderBox.globalToLocal(details.globalPosition);
        _handleTap(localPosition);
      },
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(250, 160), // Increased size
            painter: _SemiCirclePainter(
              caloriesPercent: widget.caloriesPercent,
              stepsPercent: widget.stepsPercent,
              movingPercent: widget.movingPercent,
              selectedSection: _selectedSection,
            ),
          ),
          if (_selectedSection != null && _tooltipPosition != null)
            Positioned(
              left: _tooltipPosition!.dx,
              top: _tooltipPosition!.dy,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.white38),
                ),
                child: Text(
                  _getTooltipText(),
                  style: const TextStyle(color: Colors.white, fontSize: 12.0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleTap(Offset localPosition) {
    final size = const Size(250, 160);
    final center = Offset(size.width / 2, size.height - 20);
    final radius = size.width / 2 - 30;
    final strokeWidth = 30.0;
    final gap = 5.0;

    // Calculate distance from center
    final distanceFromCenter = (localPosition - center).distance;

    // Check which arc was tapped based on distance from center
    if (distanceFromCenter >= radius - strokeWidth &&
        distanceFromCenter <= radius) {
      // Calories arc
      setState(() {
        _selectedSection = "calories";
        _tooltipPosition = Offset(localPosition.dx - 30, localPosition.dy - 50);
      });
    } else if (distanceFromCenter >= radius - strokeWidth - gap - strokeWidth &&
        distanceFromCenter <= radius - gap) {
      // Steps arc
      setState(() {
        _selectedSection = "steps";
        _tooltipPosition = Offset(localPosition.dx - 30, localPosition.dy - 50);
      });
    } else if (distanceFromCenter >=
            radius - 2 * (strokeWidth + gap) - strokeWidth &&
        distanceFromCenter <= radius - 2 * (strokeWidth + gap)) {
      // Moving arc
      setState(() {
        _selectedSection = "moving";
        _tooltipPosition = Offset(localPosition.dx - 30, localPosition.dy - 50);
      });
    } else {
      // Tapped outside the arcs
      setState(() {
        _selectedSection = null;
        _tooltipPosition = null;
      });
    }

    // Hide tooltip after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          if (_selectedSection != null) {
            _selectedSection = null;
            _tooltipPosition = null;
          }
        });
      }
    });
  }

  String _getTooltipText() {
    switch (_selectedSection) {
      case "calories":
        return "${widget.caloriesValue}${widget.caloriesGoal.isNotEmpty ? widget.caloriesGoal : ''}";
      case "steps":
        return "${widget.stepsValue}${widget.stepsGoal.isNotEmpty ? widget.stepsGoal : ''}";
      case "moving":
        return "${widget.movingValue}${widget.movingGoal.isNotEmpty ? widget.movingGoal : ''}";
      default:
        return "";
    }
  }
}

class _SemiCirclePainter extends CustomPainter {
  final double caloriesPercent;
  final double stepsPercent;
  final double movingPercent;
  final String? selectedSection;

  _SemiCirclePainter({
    required this.caloriesPercent,
    required this.stepsPercent,
    required this.movingPercent,
    this.selectedSection,
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
      selectedSection == "calories"
          ? Colors.orange
          : Colors.deepOrange, // Highlight selected section
      strokeWidth,
    );

    // Steps progress (lighter yellow-orange) with gap
    _drawCustomProgressArc(
      canvas,
      center,
      radius - strokeWidth - gap,
      math.pi,
      stepsSweep,
      selectedSection == "steps"
          ? Colors.yellow
          : Colors.amber, // Highlight selected section
      strokeWidth,
    );

    // Moving progress (lighter blue) with gap
    _drawCustomProgressArc(
      canvas,
      center,
      radius - 2 * (strokeWidth + gap),
      math.pi,
      movingSweep,
      selectedSection == "moving"
          ? Colors.lightBlue
          : Colors.blue, // Highlight selected section
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
