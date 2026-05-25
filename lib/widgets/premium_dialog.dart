import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PremiumDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final IconData? icon;
  final Color? iconColor;

  const PremiumDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = iconColor ?? const Color(0xFF3EA6FF);
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets + const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuad,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.06),
                Colors.white.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              // Icon Badge at Top
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.18),
                        primaryColor.withOpacity(0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.15),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 18),
              ],
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 14,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                  child: content,
                ),
              ),
              const SizedBox(height: 24),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 20.0),
                child: Row(
                  mainAxisAlignment: actions.length == 1
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceEvenly,
                  children: actions.map((act) => Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: act,
                  ))).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class PremiumCancelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const PremiumCancelButton({
    super.key,
    this.label = "Cancel",
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isEnabled ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.04),
          width: 1.0,
        ),
      ),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => onPressed?.call() : null,
        behavior: HitTestBehavior.opaque,
        child: IgnorePointer(
          child: TextButton(
            onPressed: isEnabled ? () {} : null,
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isEnabled ? Colors.white.withOpacity(0.85) : Colors.white.withOpacity(0.3),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumConfirmButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final List<Color>? gradientColors;

  const PremiumConfirmButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    final List<Color> colors = gradientColors ?? [const Color(0xFF3EA6FF), const Color(0xFF00E5FF)];
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isEnabled ? null : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: colors.first.withOpacity(0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => onPressed?.call() : null,
        behavior: HitTestBehavior.opaque,
        child: IgnorePointer(
          child: ElevatedButton(
            onPressed: isEnabled ? () {} : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor: Colors.white38,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.white.withOpacity(0.35),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
