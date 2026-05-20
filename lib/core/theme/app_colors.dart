// app_colors.dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  static Color background = const Color(0xFF000000);
  static Color surface = const Color(0xFF050505);
  static Color surfaceHigh = const Color(0xFF0A0A0A);
  static Color accent = const Color(0xFF0285FF);
  static Color accentLight = const Color(0xFFE0F0FF);
  static Color textPrimary = const Color(0xFFE8EAFF);
  static Color textSecondary = const Color(0x66E8EAFF);
  static Color textMuted = const Color(0x4DE8EAFF);
  static Color border = const Color(0x14FFFFFF);
  static Color borderHigh = const Color(0x1AFFFFFF);
  static Color danger = const Color(0xFFFF6B6B);
  static Color success = const Color(0xFF4ADE80);
  static Color glassFill = const Color(0x0DFFFFFF);
  static Color glassDockFill = const Color(0x0FFFFFFF);
  static Color glassAccent = const Color(0x1F0285FF);
  static Color glassAccentHigh = const Color(0x330285FF);

  static void applyTheme(ThemeMode mode, [Brightness? platformBrightness]) {
    final bool isLight = mode == ThemeMode.light || (mode == ThemeMode.system && platformBrightness == Brightness.light);
    
    if (isLight) {
      background = const Color(0xFFF5F7FF);
      surface = const Color(0xFFFFFFFF);
      surfaceHigh = const Color(0xFFE8EAFF);
      textPrimary = const Color(0xFF1A1A28);
      textSecondary = const Color(0xFF5B617A);
      textMuted = const Color(0xFF8E94A8);
      border = const Color(0xFFD1D5E8);
      borderHigh = const Color(0xFFBCC2D9);
      glassFill = const Color(0x0D000000);
      glassDockFill = const Color(0x1A000000);
    } else {
      // Default Dark
      background = const Color(0xFF000000);
      surface = const Color(0xFF050505);
      surfaceHigh = const Color(0xFF0A0A0A);
      textPrimary = const Color(0xFFE8EAFF);
      textSecondary = const Color(0x66E8EAFF);
      textMuted = const Color(0x4DE8EAFF);
      border = const Color(0x14FFFFFF);
      borderHigh = const Color(0x1AFFFFFF);
      glassFill = const Color(0x0DFFFFFF);
      glassDockFill = const Color(0x0FFFFFFF);
    }
  }

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0070E0), Color(0xFF0285FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
