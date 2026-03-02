// lib/theme/app_theme.dart
// ========================
// Builds the app-wide ThemeData using colors from AppColors.
//
// FONTS:
//   Headings → Playfair Display (elegant serif)
//   Body     → Inter (clean, modern sans-serif)
//   Mono     → Roboto Mono (ticket details, codes)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// The dark theme applied to MaterialApp
  static ThemeData get darkTheme {
    // Start with the default dark theme's text sizes/weights
    final TextTheme baseTextTheme = ThemeData.dark().textTheme;

    return ThemeData(
      brightness: Brightness.dark,

      // ── Background ──
      scaffoldBackgroundColor: AppColors.background,

      // ── Color Scheme ──
      colorScheme: const ColorScheme.dark(
        primary: AppColors.amber,
        secondary: AppColors.amberSoft,
        surface: AppColors.background,
        error: AppColors.error,
      ),

      // ── Typography: Inter as the default body font ──
      textTheme: GoogleFonts.interTextTheme(baseTextTheme),

      // ── App Bar ──
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: AppColors.amber,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        // White back/close icons
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ── Elevated Buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── Heading helper ──
  /// Quick access to Playfair Display for headings.
  /// Defaults: 28px, amber, bold.
  static TextStyle heading({
    double fontSize = 28,
    Color color = AppColors.amber,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }
}