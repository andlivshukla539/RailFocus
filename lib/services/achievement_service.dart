// lib/services/achievement_service.dart
// ======================================
// Tracks and unlocks achievements based on session data.

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/achievement_model.dart';
import 'storage_service.dart';

class AchievementService {
  static const _boxName = 'achievements';
  static Box? _box;

  /// Initialize the achievements box
  static Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
    } catch (e) {
      debugPrint('⚠️ AchievementService.init error: $e');
    }
  }

  /// Get all achievements with their unlock status
  List<Achievement> getAll() {
    final achievements = Achievement.all;
    for (final a in achievements) {
      final stored = _box?.get(a.id);
      if (stored != null) {
        a.unlockedAt = DateTime.fromMillisecondsSinceEpoch(stored as int);
      }
    }
    return achievements;
  }

  /// Get only unlocked achievements
  List<Achievement> getUnlocked() {
    return getAll().where((a) => a.isUnlocked).toList();
  }

  /// Get count of unlocked achievements
  int getUnlockedCount() {
    int count = 0;
    for (final a in Achievement.all) {
      if (_box?.get(a.id) != null) count++;
    }
    return count;
  }

  /// Check all conditions and unlock any new achievements.
  /// Returns list of newly unlocked achievements.
  Future<List<Achievement>> checkAndUnlock(StorageService storage) async {
    final newly = <Achievement>[];

    try {
      final sessions = storage.getAllSessions();
      final completed = sessions.where((s) => s.completed).toList();
      final totalSessions = completed.length;
      final totalHours = storage.getTotalHours();
      final streak = storage.getStreak();
      final routeCount = storage.getRoutesTraveled();

      // ── Journey badges ──
      _tryUnlock('first_journey', totalSessions >= 1, newly);
      _tryUnlock('ten_journeys', totalSessions >= 10, newly);
      _tryUnlock('fifty_journeys', totalSessions >= 50, newly);
      _tryUnlock('century', totalSessions >= 100, newly);

      // Focused Mind: 5 completed in a row (no abandons between)
      if (sessions.length >= 5) {
        int consecutive = 0;
        for (final s in sessions) {
          if (s.completed) {
            consecutive++;
            if (consecutive >= 5) break;
          } else {
            consecutive = 0;
          }
        }
        _tryUnlock('five_in_a_row', consecutive >= 5, newly);
      }

      // ── Streak badges ──
      _tryUnlock('streak_3', streak >= 3, newly);
      _tryUnlock('streak_7', streak >= 7, newly);
      _tryUnlock('streak_30', streak >= 30, newly);

      // ── Time badges ──
      final has90 = completed.any((s) => s.durationMinutes >= 90);
      _tryUnlock('marathon', has90, newly);
      _tryUnlock('time_10h', totalHours >= 10, newly);
      _tryUnlock('time_24h', totalHours >= 24, newly);
      _tryUnlock('time_100h', totalHours >= 100, newly);

      // Night Owl: 5 sessions started after 10 PM
      final nightSessions =
          completed
              .where((s) => s.startTime.hour >= 22 || s.startTime.hour < 4)
              .length;
      _tryUnlock('night_owl', nightSessions >= 5, newly);

      // Early Bird: 5 sessions started before 8 AM
      final morningSessions =
          completed
              .where((s) => s.startTime.hour >= 4 && s.startTime.hour < 8)
              .length;
      _tryUnlock('early_bird', morningSessions >= 5, newly);

      // ── Route badges ──
      // allRoutes has 5 base + new ones, check if user tried at least 5
      _tryUnlock('explorer', routeCount >= 5, newly);

      // ── Special badges ──
      final goalSessions =
          completed.where((s) => s.goal != null && s.goal!.isNotEmpty).length;
      _tryUnlock('perfectionist', goalSessions >= 10, newly);
    } catch (e) {
      debugPrint('⚠️ AchievementService.checkAndUnlock error: $e');
    }

    return newly;
  }

  void _tryUnlock(String id, bool condition, List<Achievement> newly) {
    if (!condition) return;
    if (_box?.get(id) != null) return; // Already unlocked

    final now = DateTime.now().millisecondsSinceEpoch;
    _box?.put(id, now);

    // Find the achievement definition to return
    try {
      final achievement = Achievement.all.firstWhere((a) => a.id == id);
      achievement.unlockedAt = DateTime.fromMillisecondsSinceEpoch(now);
      newly.add(achievement);
      debugPrint('🏆 Achievement unlocked: ${achievement.name}');
    } catch (_) {}
  }

  /// Clear all achievement data
  Future<void> clearAll() async {
    try {
      await _box?.clear();
    } catch (e) {
      debugPrint('⚠️ AchievementService.clearAll error: $e');
    }
  }
}
