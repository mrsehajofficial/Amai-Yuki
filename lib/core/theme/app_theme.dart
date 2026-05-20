// app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _createTheme(Brightness.light);
  static ThemeData get dark => _createTheme(Brightness.dark);

  static ThemeData _createTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final TextTheme baseTextTheme = isDark 
        ? ThemeData.dark().textTheme 
        : ThemeData.light().textTheme;
    
    final TextTheme interBase = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accent,
      colorScheme: isDark 
          ? ColorScheme.dark(
              primary: AppColors.accent,
              secondary: AppColors.accentLight,
              surface: AppColors.surface,
              error: AppColors.danger,
            )
          : ColorScheme.light(
              primary: AppColors.accent,
              secondary: AppColors.accentLight,
              surface: AppColors.surface,
              error: AppColors.danger,
            ),
      textTheme: interBase.copyWith(
        displayLarge: interBase.displayLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displayMedium: interBase.displayMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: interBase.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleMedium: interBase.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleSmall: interBase.titleSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: interBase.bodyLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w400, height: 1.6),
        bodyMedium: interBase.bodyMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall: interBase.bodySmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w300),
        labelLarge: interBase.labelLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        labelMedium: interBase.labelMedium?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500, letterSpacing: 1.5),
        labelSmall: interBase.labelSmall?.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w300),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0x0DFFFFFF) : const Color(0x0D000000),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontWeight: FontWeight.w400, fontSize: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderHigh, width: 1)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.danger, width: 1)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, 
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceHigh,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
    );
  }
}
