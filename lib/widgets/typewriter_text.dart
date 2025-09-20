import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final Duration duration;
  final TextStyle? style;
  final Duration cursorBlinkSpeed;

  const TypewriterText({
    super.key,
    required this.text,
    this.duration = const Duration(milliseconds: 2000),
    this.style,
    this.cursorBlinkSpeed = const Duration(milliseconds: 500),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with TickerProviderStateMixin {
  late AnimationController _typingController;
  late AnimationController _cursorController;
  late Animation<int> _typingAnimation;
  late Animation<double> _cursorAnimation;

  @override
  void initState() {
    super.initState();

    // Controller for typing animation
    _typingController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Controller for cursor blinking
    _cursorController = AnimationController(
      duration: widget.cursorBlinkSpeed,
      vsync: this,
    )..repeat(reverse: true);

    // Animation to track text index
    _typingAnimation = IntTween(
      begin: 0,
      end: widget.text.length,
    ).animate(CurvedAnimation(parent: _typingController, curve: Curves.easeIn));

    // Animation for cursor blinking
    _cursorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_cursorController);

    // Start typing animation after a delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _typingController.forward();
      });
    });
  }

  @override
  void dispose() {
    _typingController.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_typingController, _cursorController]),
      builder: (context, child) {
        final textIndex = _typingAnimation.value;
        final showCursor = _cursorAnimation.value > 0.5;
        final visibleText = widget.text.substring(0, textIndex);
        final cursor = showCursor && textIndex < widget.text.length ? '|' : '';

        return Text(
          visibleText + cursor,
          style: widget.style ?? const TextStyle(),
        );
      },
    );
  }
}
