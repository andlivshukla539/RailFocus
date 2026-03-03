// lib/models/achievement_model.dart
// =================================
// Badge/achievement definitions for the Trophy Room.

import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// ACHIEVEMENT CATEGORY
// ══════════════════════════════════════════════════════════════

enum AchievementCategory {
  journey('Journeys', '🚂'),
  streak('Streaks', '🔥'),
  time('Time', '⏱️'),
  route('Routes', '🗺️'),
  special('Special', '✨');

  final String label;
  final String emoji;
  const AchievementCategory(this.label, this.emoji);
}

// ══════════════════════════════════════════════════════════════
// ACHIEVEMENT DEFINITION
// ══════════════════════════════════════════════════════════════

class Achievement {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final Color glowColor;

  /// When this was unlocked (null = still locked)
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.glowColor,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'unlockedAt': unlockedAt?.millisecondsSinceEpoch,
  };

  // ══════════════════════════════════════════════════════════
  // ALL ACHIEVEMENTS
  // ══════════════════════════════════════════════════════════

  static List<Achievement> get all => [
    // ── Journey badges ──
    Achievement(
      id: 'first_journey',
      name: 'First Journey',
      description: 'Complete your first focus session',
      emoji: '🎫',
      category: AchievementCategory.journey,
      glowColor: const Color(0xFFD4A855),
    ),
    Achievement(
      id: 'ten_journeys',
      name: 'Seasoned Traveler',
      description: 'Complete 10 focus sessions',
      emoji: '🧳',
      category: AchievementCategory.journey,
      glowColor: const Color(0xFFB8824A),
    ),
    Achievement(
      id: 'fifty_journeys',
      name: 'Veteran Conductor',
      description: 'Complete 50 focus sessions',
      emoji: '🎩',
      category: AchievementCategory.journey,
      glowColor: const Color(0xFFE8C170),
    ),
    Achievement(
      id: 'century',
      name: 'Century Club',
      description: 'Complete 100 focus sessions',
      emoji: '💯',
      category: AchievementCategory.journey,
      glowColor: const Color(0xFFFFD700),
    ),
    Achievement(
      id: 'five_in_a_row',
      name: 'Focused Mind',
      description: 'Complete 5 sessions without abandoning',
      emoji: '🧠',
      category: AchievementCategory.journey,
      glowColor: const Color(0xFF9B85D4),
    ),

    // ── Streak badges ──
    Achievement(
      id: 'streak_3',
      name: 'Getting Rolling',
      description: 'Maintain a 3-day focus streak',
      emoji: '🔥',
      category: AchievementCategory.streak,
      glowColor: const Color(0xFFFF6B35),
    ),
    Achievement(
      id: 'streak_7',
      name: 'Streak Master',
      description: 'Maintain a 7-day focus streak',
      emoji: '⚡',
      category: AchievementCategory.streak,
      glowColor: const Color(0xFFFF4500),
    ),
    Achievement(
      id: 'streak_30',
      name: 'Unstoppable',
      description: 'Maintain a 30-day focus streak',
      emoji: '🏆',
      category: AchievementCategory.streak,
      glowColor: const Color(0xFFFFD700),
    ),

    // ── Time badges ──
    Achievement(
      id: 'marathon',
      name: 'Marathon Runner',
      description: 'Complete a 90-minute session',
      emoji: '🏃',
      category: AchievementCategory.time,
      glowColor: const Color(0xFF5B9BD5),
    ),
    Achievement(
      id: 'time_10h',
      name: 'Dedicated',
      description: 'Accumulate 10 hours of total focus time',
      emoji: '⏰',
      category: AchievementCategory.time,
      glowColor: const Color(0xFF6D8B74),
    ),
    Achievement(
      id: 'time_24h',
      name: 'Time Lord',
      description: 'Accumulate 24 hours of total focus time',
      emoji: '⌛',
      category: AchievementCategory.time,
      glowColor: const Color(0xFFD4963A),
    ),
    Achievement(
      id: 'time_100h',
      name: 'Grand Master',
      description: 'Accumulate 100 hours of total focus time',
      emoji: '👑',
      category: AchievementCategory.time,
      glowColor: const Color(0xFFFFD700),
    ),
    Achievement(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Complete 5 sessions after 10 PM',
      emoji: '🦉',
      category: AchievementCategory.time,
      glowColor: const Color(0xFF2D1B3D),
    ),
    Achievement(
      id: 'early_bird',
      name: 'Early Bird',
      description: 'Complete 5 sessions before 8 AM',
      emoji: '🌅',
      category: AchievementCategory.time,
      glowColor: const Color(0xFFFF8C42),
    ),

    // ── Route badges ──
    Achievement(
      id: 'explorer',
      name: 'World Explorer',
      description: 'Travel on all available routes',
      emoji: '🌍',
      category: AchievementCategory.route,
      glowColor: const Color(0xFF00D9FF),
    ),

    // ── Special badges ──
    Achievement(
      id: 'perfectionist',
      name: 'Perfectionist',
      description: 'Complete 10 sessions with a goal set',
      emoji: '🎯',
      category: AchievementCategory.special,
      glowColor: const Color(0xFFE91E63),
    ),
  ];
}
