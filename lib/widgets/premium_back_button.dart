import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color iconColor;

  const PremiumBackButton({
    super.key,
    this.onPressed,
    this.icon = Icons.arrow_back,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      widthFactor: 1.0,
      heightFactor: 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(icon, color: iconColor, size: 20),
              onPressed: onPressed ?? () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
