// lib/theme/luxe_theme.dart
// =========================
// The Luxe Rail premium design system.
// All colors, gradients, and text styles live here.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════════
// LUXE COLOR PALETTE
// ══════════════════════════════════════════════════════════════

class LuxeColors {
  LuxeColors._();

  // ── Core Darks ──
  static const Color obsidian = Color(0xFF0A0A0F);
  static const Color velvet = Color(0xFF12121A);
  static const Color charcoal = Color(0xFF1A1A24);
  static const Color slate = Color(0xFF252530);

  // ── Precious Metals ──
  static const Color champagne = Color(0xFFF7E7CE);
  static const Color gold = Color(0xFFD4A574);
  static const Color roseGold = Color(0xFFE8C4B8);
  static const Color brass = Color(0xFF8B6914);
  static const Color copper = Color(0xFFB87333);

  // ── Accent Colors ──
  static const Color ember = Color(0xFFFF6B35);
  static const Color sapphire = Color(0xFF2E4A62);
  static const Color emerald = Color(0xFF2D5A4A);
  static const Color amethyst = Color(0xFF6B4C8A);
  static const Color ruby = Color(0xFF9B2335);

  // ── Aurora Colors ──
  static const Color aurora1 = Color(0xFF00D9FF);
  static const Color aurora2 = Color(0xFF00FF94);
  static const Color aurora3 = Color(0xFFFF00E5);

  // ── Gradients ──
  static const List<Color> sunriseGold = [
    Color(0xFFF7E7CE),
    Color(0xFFD4A574),
    Color(0xFF8B6914),
  ];

  static const List<Color> midnightGlow = [
    Color(0xFF0A0A1A),
    Color(0xFF1A1030),
    Color(0xFF2A1A40),
  ];

  static const List<Color> warmEmber = [
    Color(0xFFFF8A50),
    Color(0xFFFF6B35),
    Color(0xFFE85020),
  ];

  // ── Text Colors ──
  static const Color textPrimary = champagne;
  static const Color textSecondary = Color(0xAAF7E7CE);
  static const Color textMuted = Color(0x66F7E7CE);
}

// ══════════════════════════════════════════════════════════════
// LUXE TEXT STYLES
// ══════════════════════════════════════════════════════════════

class LuxeText {
  LuxeText._();

  /// Cinzel — elegant display headings
  static TextStyle heading({
    double fontSize = 24,
    Color color = LuxeColors.champagne,
    FontWeight fontWeight = FontWeight.w700,
    double letterSpacing = 2.0,
  }) {
    return GoogleFonts.cinzel(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }

  /// Cormorant Garamond — elegant body text
  static TextStyle elegant({
    double fontSize = 16,
    Color color = LuxeColors.champagne,
    FontWeight fontWeight = FontWeight.w400,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
    );
  }

  /// Inter — clean UI labels
  static TextStyle label({
    double fontSize = 12,
    Color color = LuxeColors.textSecondary,
    FontWeight fontWeight = FontWeight.w500,
    double letterSpacing = 1.0,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LUXE DECORATIONS
// ══════════════════════════════════════════════════════════════

class LuxeDecorations {
  LuxeDecorations._();

  /// Glass morphism card
  static BoxDecoration glassCard({
    double borderRadius = 20,
    Color? borderColor,
    double borderOpacity = 0.1,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.02),
        ],
      ),
      border: Border.all(
        color: (borderColor ?? Colors.white).withValues(alpha: borderOpacity),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Solid luxury card
  static BoxDecoration solidCard({
    double borderRadius = 16,
    Color? accentColor,
  }) {
    final accent = accentColor ?? LuxeColors.gold;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [LuxeColors.charcoal, LuxeColors.velvet],
      ),
      border: Border.all(
        color: accent.withValues(alpha: 0.2),
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.1),
          blurRadius: 20,
          spreadRadius: -5,
        ),
      ],
    );
  }

  /// Gold border frame
  static BoxDecoration goldFrame({
    double borderRadius = 20,
    double borderWidth = 2,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: LuxeColors.gold,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: LuxeColors.gold.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }
}