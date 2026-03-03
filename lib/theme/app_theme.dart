// lib/theme/app_theme.dart
// ========================
// Builds the app-wide ThemeData using colors from AppColors.
//
// FONTS:
//   Headings → Cinzel (royal, engraved brass plate feel)
//   Body     → Raleway (ultra clean, modern luxury)
//   Mono     → Space Mono (clean, retro-tech departure board)

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
      textTheme: GoogleFonts.ralewayTextTheme(baseTextTheme),

      // ── App Bar ──
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzel(
          color: AppColors.amber,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
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
          textStyle: GoogleFonts.raleway(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── Heading helper ──
  /// Quick access to Cinzel for headings.
  /// Defaults: 28px, amber, bold.
  static TextStyle heading({
    double fontSize = 28,
    Color color = AppColors.amber,
    FontWeight fontWeight = FontWeight.bold,
    double letterSpacing = 2.0,
  }) {
    return GoogleFonts.cinzel(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }
}
