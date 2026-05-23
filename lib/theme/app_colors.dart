import 'package:flutter/material.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

/// Centralized helper for theme-aware colors across the app.
/// Use `AppColors.of(context)` to get theme-appropriate colors.
class AppColors {
  final bool isDark;

  AppColors._(this.isDark);

  factory AppColors.of(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return AppColors._(isDark);
  }

  // --- Scaffolds & backgrounds ---
  Color get scaffold => isDark ? Colors.black : const Color(0xFFF5F5F7);
  Color get appBar => isDark ? Colors.black : const Color(0xFFF5F5F7);

  // --- Card surfaces ---
  Color get card => isDark ? const Color(0xFF191919) : Colors.white;
  Color get cardAlt => isDark
      ? Colors.white.withOpacity(0.04)
      : Colors.white;
  Color get cardBorder => isDark
      ? Colors.white.withOpacity(0.08)
      : Colors.black.withOpacity(0.06);

  // --- Text ---
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1B1B1B);
  Color get textSecondary => isDark ? Colors.white70 : const Color(0xFF585858);
  Color get textTertiary => isDark ? Colors.white54 : const Color(0xFF8E8E93);
  Color get textHint => isDark ? Colors.grey[400]! : Colors.grey[600]!;

  // --- Icons ---
  Color get icon => isDark ? Colors.white : const Color(0xFF1B1B1B);
  Color get iconSecondary => isDark ? Colors.white70 : const Color(0xFF585858);

  // --- Overlays & glass ---
  Color get glassBg => isDark
      ? Colors.white.withOpacity(0.06)
      : Colors.black.withOpacity(0.04);
  Color get glassBorder => isDark
      ? Colors.white.withOpacity(0.06)
      : Colors.black.withOpacity(0.06);

  // --- Dividers ---
  Color get divider => isDark
      ? Colors.white.withOpacity(0.08)
      : Colors.black.withOpacity(0.06);

  // --- Shadows ---
  Color get shadow => isDark
      ? Colors.black.withOpacity(0.3)
      : Colors.black.withOpacity(0.06);

  // --- Input fields ---
  Color get inputFill => isDark
      ? Colors.white.withOpacity(0.06)
      : Colors.grey[100]!;
  Color get inputBorder => isDark
      ? Colors.white.withOpacity(0.12)
      : Colors.grey[300]!;

  // --- Search bar ---
  Color get searchBg => isDark
      ? Colors.white.withOpacity(0.08)
      : Colors.grey[200]!;

  // --- Bottom nav ---
  Color get navBar => isDark ? const Color(0xFF0D0D0D) : Colors.white;
  Color get navInactive => isDark ? Colors.white54 : Colors.grey;

  // --- Card gradient (for health metric cards) ---
  LinearGradient get cardGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F1F24), Color(0xFF141416)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F8FA)],
        );
}
