// lib/theme/app_colors.dart
// =========================
// The single source of truth for every color in RailFocus.
//
// PALETTE PHILOSOPHY:
//   Background → near-black with warm undertones
//   Accent     → rich gold (D4AF37) like brass instruments
//   Text       → warm whites and greys, never pure cold white
//   Routes     → each real-world route has a signature color

import 'package:flutter/material.dart';

class AppColors {
  // Private constructor — this class is just a namespace
  // for static color constants.
  AppColors._();

  // ══════════════════════════════════════
  // BACKGROUNDS & SURFACES
  // ══════════════════════════════════════

  /// Main scaffold background — near black
  static const Color background = Color(0xFF121212);

  /// Card / container background — one step lighter
  static const Color card = Color(0xFF1A1A1A);

  /// Gauge face / instrument surface — warm dark brown-black
  static const Color surface = Color(0xFF1E1A14);

  /// Surface with a slight blue tint — used for cool-toned cards
  static const Color surfaceCool = Color(0xFF161A22);

  /// Subtle borders and dividers
  static const Color border = Color(0xFF333333);

  // ══════════════════════════════════════
  // GOLD / AMBER ACCENT FAMILY
  // ══════════════════════════════════════

  /// Hero gold — buttons, gauge rings, primary accents
  /// Matches classic brass instrument color
  static const Color amber = Color(0xFFD4AF37);

  /// Softer / lighter gold — text highlights, labels
  static const Color amberSoft = Color(0xFFF0C860);

  /// Dimmed gold — used for dashed lines, subtle marks
  static const Color amberDim = Color(0xFF8A7329);

  // ══════════════════════════════════════
  // TEXT COLORS (warm white family)
  // ══════════════════════════════════════

  /// Primary text — almost white with warmth
  static const Color textPrimary = Color(0xFFF5F5F5);

  /// Secondary text — medium grey for labels
  static const Color textSecondary = Color(0xFFCCCCCC);

  /// Tertiary text — dim grey for hints, disabled
  static const Color textTertiary = Color(0xFF666666);

  // ══════════════════════════════════════
  // SEMANTIC COLORS
  // ══════════════════════════════════════

  /// Error / emergency stop — warm red
  static const Color error = Color(0xFFE63946);

  /// Success / completed — soft green
  static const Color success = Color(0xFF66BB6A);

  /// Informational — muted blue
  static const Color info = Color(0xFF457B9D);

  // ══════════════════════════════════════
  // ROUTE SIGNATURE COLORS
  // Each scenic route has a unique accent color
  // used on ticket cards and route selection UI.
  // ══════════════════════════════════════

  /// Tokyo to Kyoto — cherry blossom pink
  static const Color routeTokyo = Color(0xFFE8A0B0);

  /// Swiss Alps Express — alpine blue
  static const Color routeSwiss = Color(0xFF457B9D);

  /// Scottish Highlands — heather green
  static const Color routeScotland = Color(0xFF6D8B74);

  /// Darjeeling Railway — warm spice orange
  static const Color routeDarjeeling = Color(0xFFD4963A);

  /// Norwegian Fjords — cold ocean blue
  static const Color routeNorway = Color(0xFF5B8FB9);
}
