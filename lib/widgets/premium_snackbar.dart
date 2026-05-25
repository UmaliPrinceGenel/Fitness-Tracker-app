import 'package:flutter/material.dart';

class PremiumSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required String type, // 'success', 'error', 'warning', 'info'
    Duration duration = const Duration(seconds: 3),
  }) {
    Color accentColor;
    IconData icon;
    
    switch (type) {
      case 'success':
        accentColor = const Color(0xFF2ECC71);
        icon = Icons.check_circle_rounded;
        break;
      case 'error':
        accentColor = const Color(0xFFFF4B4B);
        icon = Icons.error_rounded;
        break;
      case 'warning':
        accentColor = const Color(0xFFFF9800);
        icon = Icons.warning_rounded;
        break;
      case 'info':
      default:
        accentColor = const Color(0xFF3EA6FF);
        icon = Icons.info_rounded;
        break;
    }

    final double screenHeight = MediaQuery.of(context).size.height;
    final double topSafeArea = MediaQuery.of(context).padding.top;
    // Elegant top placement below header
    final double topOffset = topSafeArea + 150;

    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: screenHeight - topOffset - 64,
          left: 16,
          right: 16,
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: accentColor.withOpacity(0.06),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Badge
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              // Message
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
