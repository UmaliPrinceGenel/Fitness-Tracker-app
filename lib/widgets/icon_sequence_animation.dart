import 'package:flutter/material.dart';

class IconSequenceAnimation extends StatefulWidget {
  final TextStyle? style;

  const IconSequenceAnimation({super.key, this.style});

  @override
  State<IconSequenceAnimation> createState() => _IconSequenceAnimationState();
}

class _IconSequenceAnimationState extends State<IconSequenceAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconsOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _scaleTransition;

  @override
  void initState() {
    super.initState();

    // Total animation duration
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Icons opacity animation
    _iconsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    // Text opacity animation (starts after icons have been visible for 1 second)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeInOut),
      ),
    );

    // Scale transition for smooth change
    _scaleTransition = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeInOut),
      ),
    );

    // Start animation after a delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        _controller.forward();
      });
    });
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
        return SizedBox(
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Icons - visible for first second, then fade out
              Opacity(
                opacity: _iconsOpacity.value * (1.0 - _textOpacity.value),
                child: Transform.scale(
                  scale: _scaleTransition.value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: const Color(0xFF888888),
                        size: 20,
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        Icons.directions_run,
                        color: const Color(0xFF888888),
                        size: 20,
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        Icons.calendar_today,
                        color: const Color(0xFF888888),
                        size: 20,
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        Icons.access_time,
                        color: const Color(0xFF888888),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Text - fades in after icons
              Opacity(
                opacity: _textOpacity.value,
                child: Transform.scale(
                  scale: _scaleTransition.value,
                  child: const Text(
                    "Rockies Fitness Gym Tracker",
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
