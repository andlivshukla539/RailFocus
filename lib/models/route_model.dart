// lib/models/route_model.dart
// ===========================
// Premium route definitions for Luxe Rail.
// Each route has rich visual theming and atmospheric details.

import 'package:flutter/material.dart';
import '../theme/luxe_theme.dart';

class RouteModel {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final String emoji;
  final Color accentColor;
  final List<Color> landscapeGradient;
  final List<Color> skyGradient;
  final String atmosphere; // rain, snow, clear, foggy, aurora
  final Duration estimatedRealDuration;
  final double unlockHoursRequired; // 0 = always unlocked

  const RouteModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.emoji,
    required this.accentColor,
    required this.landscapeGradient,
    required this.skyGradient,
    required this.atmosphere,
    required this.estimatedRealDuration,
    this.unlockHoursRequired = 0,
  });

  bool isUnlocked(double totalHours) => totalHours >= unlockHoursRequired;

  // ══════════════════════════════════════
  // THE FIVE PREMIUM ROUTES
  // ══════════════════════════════════════

  static const RouteModel tokyoKyoto = RouteModel(
    id: 'tokyo_kyoto',
    name: 'Tokyo to Kyoto',
    tagline: 'Cherry Blossom Express',
    description:
        'Glide through ancient temples and spring gardens as sakura petals dance in the wind.',
    emoji: '🌸',
    accentColor: Color(0xFFFFB7C5),
    landscapeGradient: [
      Color(0xFFFFE5EC),
      Color(0xFFFFB3C6),
      Color(0xFFC9ADA7),
    ],
    skyGradient: [Color(0xFF2D1B3D), Color(0xFFB85C38), Color(0xFFFFB7C5)],
    atmosphere: 'clear',
    estimatedRealDuration: Duration(hours: 2, minutes: 15),
  );

  static const RouteModel swissAlps = RouteModel(
    id: 'swiss_alps',
    name: 'Swiss Alps Express',
    tagline: 'Mountain Majesty',
    description:
        'Ascend through crisp alpine air past snow-capped peaks and glacial valleys.',
    emoji: '🏔️',
    accentColor: Color(0xFF5B9BD5),
    landscapeGradient: [
      Color(0xFF5B9BD5),
      Color(0xFF8FC4E8),
      Color(0xFFFFFFFF),
    ],
    skyGradient: [Color(0xFF1A3A5C), Color(0xFF4A7FA5), Color(0xFF8FC4E8)],
    atmosphere: 'snow',
    estimatedRealDuration: Duration(hours: 4, minutes: 30),
  );

  static const RouteModel scottishHighlands = RouteModel(
    id: 'scottish_highlands',
    name: 'Scottish Highlands',
    tagline: 'Misty Moors',
    description:
        'Traverse ancient castles and rolling heather hills shrouded in mystical fog.',
    emoji: '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
    accentColor: Color(0xFF6D8B74),
    landscapeGradient: [
      Color(0xFF6B8E7F),
      Color(0xFF8AAA91),
      Color(0xFFA8BFA3),
    ],
    skyGradient: [Color(0xFF3A4A4F), Color(0xFF5A6A6F), Color(0xFF8A9A9F)],
    atmosphere: 'foggy',
    estimatedRealDuration: Duration(hours: 3, minutes: 45),
  );

  static const RouteModel darjeelingRailway = RouteModel(
    id: 'darjeeling',
    name: 'Darjeeling Railway',
    tagline: 'Tea Garden Route',
    description:
        'Wind through emerald tea plantations as golden sunlight filters through the leaves.',
    emoji: '🍵',
    accentColor: Color(0xFFD4963A),
    landscapeGradient: [
      Color(0xFFE8A87C),
      Color(0xFFD4A574),
      Color(0xFF6B8E4E),
    ],
    skyGradient: [Color(0xFF4A3020), Color(0xFFD4963A), Color(0xFFE8A87C)],
    atmosphere: 'clear',
    estimatedRealDuration: Duration(hours: 7, minutes: 0),
  );

  static const RouteModel norwegianFjords = RouteModel(
    id: 'norwegian_fjords',
    name: 'Norwegian Fjords',
    tagline: 'Northern Lights Trail',
    description:
        'Journey beneath dancing auroras over crystalline fjords and ancient Viking lands.',
    emoji: '🌊',
    accentColor: Color(0xFF00D9FF),
    landscapeGradient: [
      Color(0xFF3A5A78),
      Color(0xFF5B8FB9),
      Color(0xFF1A2A3A),
    ],
    skyGradient: [Color(0xFF0A0A1A), Color(0xFF1A2040), Color(0xFF00D9FF)],
    atmosphere: 'aurora',
    estimatedRealDuration: Duration(hours: 6, minutes: 30),
  );

  // ══════════════════════════════════════
  // UNLOCKABLE ROUTES (require focus hours)
  // ══════════════════════════════════════

  static const RouteModel transSiberian = RouteModel(
    id: 'trans_siberian',
    name: 'Trans-Siberian',
    tagline: 'The Endless Taiga',
    description:
        'Cross frozen tundra and endless birch forests on the world\'s longest railway.',
    emoji: '❄️',
    accentColor: Color(0xFFE0E8F0),
    landscapeGradient: [
      Color(0xFFD0E0F0),
      Color(0xFFA0B8C8),
      Color(0xFF506878),
    ],
    skyGradient: [Color(0xFF0A1020), Color(0xFF1A2848), Color(0xFF4A6890)],
    atmosphere: 'snow',
    estimatedRealDuration: Duration(hours: 144),
    unlockHoursRequired: 5,
  );

  static const RouteModel orientExpress = RouteModel(
    id: 'orient_express',
    name: 'Orient Express',
    tagline: 'The Golden Age',
    description:
        'Relive the elegance of 1920s luxury travel from Paris to Istanbul.',
    emoji: '🌟',
    accentColor: Color(0xFFDAA520),
    landscapeGradient: [
      Color(0xFFDAA520),
      Color(0xFFB8860B),
      Color(0xFF654321),
    ],
    skyGradient: [Color(0xFF1A0A08), Color(0xFF3A1A10), Color(0xFF8A4A20)],
    atmosphere: 'clear',
    estimatedRealDuration: Duration(hours: 40),
    unlockHoursRequired: 10,
  );

  static const RouteModel indianPacific = RouteModel(
    id: 'indian_pacific',
    name: 'Indian Pacific',
    tagline: 'Coast to Coast',
    description:
        'Traverse the vast Australian outback from Sydney to Perth under endless skies.',
    emoji: '🇳🇺',
    accentColor: Color(0xFFE87040),
    landscapeGradient: [
      Color(0xFFE87040),
      Color(0xFFC85828),
      Color(0xFF884020),
    ],
    skyGradient: [Color(0xFF200808), Color(0xFF501808), Color(0xFFA84818)],
    atmosphere: 'clear',
    estimatedRealDuration: Duration(hours: 65),
    unlockHoursRequired: 20,
  );

  static const List<RouteModel> allRoutes = [
    tokyoKyoto,
    swissAlps,
    scottishHighlands,
    darjeelingRailway,
    norwegianFjords,
    transSiberian,
    orientExpress,
    indianPacific,
  ];

  /// Get route by ID
  static RouteModel? fromId(String id) {
    try {
      return allRoutes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ══════════════════════════════════════════════════════════════
// MOOD OPTIONS
// ══════════════════════════════════════════════════════════════

class MoodOption {
  final String id;
  final String emoji;
  final String label;
  final String description;
  final Color color;

  const MoodOption({
    required this.id,
    required this.emoji,
    required this.label,
    required this.description,
    required this.color,
  });

  static const List<MoodOption> allMoods = [
    MoodOption(
      id: 'focused',
      emoji: '🎯',
      label: 'Focused',
      description: 'Ready to lock in',
      color: LuxeColors.sapphire,
    ),
    MoodOption(
      id: 'calm',
      emoji: '😌',
      label: 'Calm',
      description: 'Peaceful mindset',
      color: LuxeColors.emerald,
    ),
    MoodOption(
      id: 'determined',
      emoji: '💪',
      label: 'Determined',
      description: 'Mission mode',
      color: LuxeColors.ember,
    ),
    MoodOption(
      id: 'creative',
      emoji: '✨',
      label: 'Creative',
      description: 'Ideas flowing',
      color: LuxeColors.amethyst,
    ),
    MoodOption(
      id: 'tired',
      emoji: '😴',
      label: 'Tired',
      description: 'Pushing through',
      color: Color(0xFF5A5A6A),
    ),
  ];
}

// ══════════════════════════════════════════════════════════════
// DURATION OPTIONS
// ══════════════════════════════════════════════════════════════

class DurationOption {
  final int minutes;
  final String label;
  final String ticketClass;
  final Color accentColor;

  const DurationOption({
    required this.minutes,
    required this.label,
    required this.ticketClass,
    required this.accentColor,
  });

  static const List<DurationOption> allDurations = [
    DurationOption(
      minutes: 15,
      label: '15 min',
      ticketClass: 'SPRINT',
      accentColor: LuxeColors.copper,
    ),
    DurationOption(
      minutes: 25,
      label: '25 min',
      ticketClass: 'STANDARD',
      accentColor: LuxeColors.brass,
    ),
    DurationOption(
      minutes: 45,
      label: '45 min',
      ticketClass: 'BUSINESS',
      accentColor: LuxeColors.gold,
    ),
    DurationOption(
      minutes: 60,
      label: '60 min',
      ticketClass: 'FIRST CLASS',
      accentColor: LuxeColors.roseGold,
    ),
    DurationOption(
      minutes: 90,
      label: '90 min',
      ticketClass: 'PRESIDENTIAL',
      accentColor: LuxeColors.champagne,
    ),
  ];
}
