// lib/models/daily_challenge.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — DAILY CHALLENGE MODEL
//  A fresh challenge generated each day to keep users engaged.
// ═══════════════════════════════════════════════════════════════

import 'dart:math';
import '../models/route_model.dart';

// ═══════════════════════════════════════════════════════════════
// CHALLENGE TYPES
// ═══════════════════════════════════════════════════════════════

enum ChallengeType {
  focusDuration,   // "Focus for X minutes today"
  sessionCount,    // "Complete X sessions today"
  specificRoute,   // "Travel the Y route"
  streakKeep,      // "Maintain your streak"
  earlyBird,       // "Complete a session before 9 AM"
  nightOwl,        // "Complete a session after 9 PM"
  marathon,        // "Focus for 60+ minutes total today"
}

// ═══════════════════════════════════════════════════════════════
// DAILY CHALLENGE
// ═══════════════════════════════════════════════════════════════

class DailyChallenge {
  final String id;          // e.g. "2026-03-04"
  final ChallengeType type;
  final String title;
  final String subtitle;
  final String emoji;
  final int targetValue;    // minutes, sessions, etc.
  final int brickReward;
  final String? routeId;    // for specificRoute type

  const DailyChallenge({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.targetValue,
    required this.brickReward,
    this.routeId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.index,
    'title': title,
    'subtitle': subtitle,
    'emoji': emoji,
    'targetValue': targetValue,
    'brickReward': brickReward,
    'routeId': routeId,
  };

  factory DailyChallenge.fromMap(Map<String, dynamic> map) => DailyChallenge(
    id: map['id'] as String,
    type: ChallengeType.values[map['type'] as int],
    title: map['title'] as String,
    subtitle: map['subtitle'] as String,
    emoji: map['emoji'] as String,
    targetValue: map['targetValue'] as int,
    brickReward: map['brickReward'] as int,
    routeId: map['routeId'] as String?,
  );

  /// Generate today's challenge (seeded by date for consistency)
  static DailyChallenge generateForToday() {
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final rng = Random(seed);

    final templates = _allTemplates;
    final chosen = templates[rng.nextInt(templates.length)];
    return chosen.copyWithId(dateKey);
  }

  DailyChallenge copyWithId(String newId) => DailyChallenge(
    id: newId,
    type: type,
    title: title,
    subtitle: subtitle,
    emoji: emoji,
    targetValue: targetValue,
    brickReward: brickReward,
    routeId: routeId,
  );
}

// ═══════════════════════════════════════════════════════════════
// CHALLENGE TEMPLATES
// ═══════════════════════════════════════════════════════════════

final List<DailyChallenge> _allTemplates = [
  // Duration challenges
  const DailyChallenge(
    id: '', type: ChallengeType.focusDuration,
    title: 'Quick Sprint', subtitle: 'Focus for 15 minutes today',
    emoji: '⚡', targetValue: 15, brickReward: 3,
  ),
  const DailyChallenge(
    id: '', type: ChallengeType.focusDuration,
    title: 'Deep Focus', subtitle: 'Focus for 45 minutes today',
    emoji: '🧠', targetValue: 45, brickReward: 8,
  ),
  const DailyChallenge(
    id: '', type: ChallengeType.marathon,
    title: 'Marathon Runner', subtitle: 'Focus for 60+ minutes total today',
    emoji: '🏃', targetValue: 60, brickReward: 12,
  ),

  // Session count challenges
  const DailyChallenge(
    id: '', type: ChallengeType.sessionCount,
    title: 'Double Header', subtitle: 'Complete 2 sessions today',
    emoji: '✌️', targetValue: 2, brickReward: 5,
  ),
  const DailyChallenge(
    id: '', type: ChallengeType.sessionCount,
    title: 'Triple Threat', subtitle: 'Complete 3 sessions today',
    emoji: '🔱', targetValue: 3, brickReward: 10,
  ),

  // Route challenges
  DailyChallenge(
    id: '', type: ChallengeType.specificRoute,
    title: 'Cherry Blossom Express', subtitle: 'Travel Tokyo → Kyoto',
    emoji: '🌸', targetValue: 1, brickReward: 5,
    routeId: RouteModel.tokyoKyoto.id,
  ),
  DailyChallenge(
    id: '', type: ChallengeType.specificRoute,
    title: 'Alpine Adventure', subtitle: 'Travel Zürich → Zermatt',
    emoji: '🏔️', targetValue: 1, brickReward: 5,
    routeId: RouteModel.swissAlps.id,
  ),
  DailyChallenge(
    id: '', type: ChallengeType.specificRoute,
    title: 'Fjord Explorer', subtitle: 'Travel Oslo → Bergen',
    emoji: '🌊', targetValue: 1, brickReward: 5,
    routeId: RouteModel.norwegianFjords.id,
  ),
  DailyChallenge(
    id: '', type: ChallengeType.specificRoute,
    title: 'Desert Crossing', subtitle: 'Travel Casa → Marrakech',
    emoji: '🐪', targetValue: 1, brickReward: 5,
    routeId: 'sahara_express',
  ),

  // Time-of-day challenges
  const DailyChallenge(
    id: '', type: ChallengeType.earlyBird,
    title: 'Early Bird', subtitle: 'Complete a session before 9 AM',
    emoji: '🌅', targetValue: 9, brickReward: 6,
  ),
  const DailyChallenge(
    id: '', type: ChallengeType.nightOwl,
    title: 'Night Owl', subtitle: 'Complete a session after 9 PM',
    emoji: '🦉', targetValue: 21, brickReward: 6,
  ),

  // Streak
  const DailyChallenge(
    id: '', type: ChallengeType.streakKeep,
    title: 'Keep the Fire', subtitle: 'Maintain your focus streak',
    emoji: '🔥', targetValue: 1, brickReward: 4,
  ),
];
