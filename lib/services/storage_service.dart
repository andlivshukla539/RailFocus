// lib/services/storage_service.dart
// ==================================
// Wraps all Hive read/write operations behind clean methods.
//
// BOXES USED:
//   'stats'    → key-value pairs: streak, totalMinutes,
//                totalSessions, routesTraveled, lastSessionDate
//   'sessions' → list of Maps, each representing a JourneySession
//
// USAGE:
//   final storage = StorageService();
//   int streak = storage.getStreak();
//   List<JourneySession> all = storage.getAllSessions();

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/session_model.dart';
import 'firestore_sync_service.dart';
import 'home_widget_service.dart';

class StorageService {
  // ── Box Accessors ──────────────────────────────────────
  // These retrieve the already-opened boxes (opened in main.dart).
  // Hive.box() throws if the box isn't open, which is fine —
  // it means we forgot to open it at startup, a real bug.

  /// The stats box stores simple key-value pairs
  Box get _statsBox => Hive.box('stats');

  /// The sessions box stores a list of session Maps
  Box get _sessionsBox => Hive.box('sessions');

  // ══════════════════════════════════════
  // READ METHODS
  // ══════════════════════════════════════

  /// Current consecutive-day streak.
  /// Returns 0 on first launch (key doesn't exist yet).
  int getStreak() {
    try {
      return _statsBox.get('streak', defaultValue: 0) as int;
    } catch (e) {
      debugPrint('⚠️ Storage error in getStreak: $e');
      return 0;
    }
  }

  /// Total lifetime focus time in fractional hours.
  /// Stored as minutes internally, converted to hours here.
  double getTotalHours() {
    try {
      final int totalMinutes =
          _statsBox.get('totalMinutes', defaultValue: 0) as int;
      // Convert to hours with one decimal place precision
      return totalMinutes / 60.0;
    } catch (e) {
      debugPrint('⚠️ Storage error in getTotalHours: $e');
      return 0.0;
    }
  }

  /// Total number of completed sessions
  int getTotalSessions() {
    try {
      return _statsBox.get('totalSessions', defaultValue: 0) as int;
    } catch (e) {
      debugPrint('⚠️ Storage error in getTotalSessions: $e');
      return 0;
    }
  }

  /// Number of unique routes the user has traveled
  int getRoutesTraveled() {
    try {
      return _statsBox.get('routesTraveled', defaultValue: 0) as int;
    } catch (e) {
      debugPrint('⚠️ Storage error in getRoutesTraveled: $e');
      return 0;
    }
  }

  /// All past sessions, newest first.
  /// Each entry in the box is a Map that we convert to JourneySession.
  List<JourneySession> getAllSessions() {
    try {
      final List<JourneySession> sessions = [];

      // Iterate through every entry in the sessions box
      for (int i = 0; i < _sessionsBox.length; i++) {
        try {
          // Retrieve the raw Map stored at index i
          final raw = _sessionsBox.getAt(i);
          if (raw != null) {
            sessions.add(JourneySession.fromMap(raw as Map));
          }
        } catch (e) {
          // Skip malformed entries — defensive coding
          debugPrint('Skipped malformed session at index $i: $e');
        }
      }

      // Sort newest first so the most recent journey appears first
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sessions;
    } catch (e) {
      debugPrint('⚠️ Storage error in getAllSessions: $e');
      return [];
    }
  }

  // ══════════════════════════════════════
  // WRITE METHODS (used by future screens)
  // ══════════════════════════════════════

  /// Saves a completed (or abandoned) session to the sessions box
  /// and updates aggregate stats.
  Future<void> saveSession(JourneySession session) async {
    try {
      // Add the session Map to the sessions box
      await _sessionsBox.add(session.toMap());

      // Update aggregate stats
      if (session.completed) {
        // Increment total completed sessions
        final int prevSessions = getTotalSessions();
        await _statsBox.put('totalSessions', prevSessions + 1);

        // Add minutes to total
        final int prevMinutes =
            _statsBox.get('totalMinutes', defaultValue: 0) as int;
        await _statsBox.put(
          'totalMinutes',
          prevMinutes + session.durationMinutes,
        );

        // Update streak
        await _updateStreak();

        // Update unique routes count
        await _updateRouteCount(session.routeName);

        // Award bricks (1 per 5 minutes of focus)
        final bricksEarned = (session.durationMinutes / 5).ceil();
        await addBricks(bricksEarned);

        // Backup to Firestore (fire-and-forget)
        FirestoreSyncService.instance.fullBackup();

        // Update Android home widget data
        HomeWidgetService.instance.updateWidgetData();
      }
    } catch (e) {
      debugPrint('⚠️ Storage error in saveSession: $e');
    }
  }

  /// Recalculates the streak based on session dates.
  /// A streak increments when the user has a completed session
  /// today AND had one yesterday (or this is day one).
  Future<void> _updateStreak() async {
    final sessions = getAllSessions().where((s) => s.completed).toList();

    if (sessions.isEmpty) {
      await _statsBox.put('streak', 0);
      return;
    }

    int streak = 1;
    // Start from today and walk backwards
    DateTime checkDate = DateTime.now();

    // Check if there's a session today
    bool hasToday = sessions.any((s) => _isSameDay(s.startTime, checkDate));

    if (!hasToday) {
      // Check yesterday — user might not have opened app yet today
      checkDate = checkDate.subtract(const Duration(days: 1));
      bool hasYesterday = sessions.any(
        (s) => _isSameDay(s.startTime, checkDate),
      );
      if (!hasYesterday) {
        await _statsBox.put('streak', 0);
        return;
      }
    }

    // Walk backwards counting consecutive days
    for (int i = 1; i < 365; i++) {
      final prevDay = checkDate.subtract(Duration(days: i));
      bool hasPrevDay = sessions.any((s) => _isSameDay(s.startTime, prevDay));
      if (hasPrevDay) {
        streak++;
      } else {
        break;
      }
    }

    await _statsBox.put('streak', streak);
  }

  /// Checks if two DateTimes fall on the same calendar day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Recalculates how many unique route names exist across all sessions
  Future<void> _updateRouteCount(String routeName) async {
    final allRoutes =
        getAllSessions()
            .where((s) => s.completed)
            .map((s) => s.routeName)
            .toSet(); // Set removes duplicates
    await _statsBox.put('routesTraveled', allRoutes.length);
  }

  // ══════════════════════════════════════
  // DELETE METHODS
  // ══════════════════════════════════════

  /// Deletes a single session by ID.
  void deleteSession(String id) {
    try {
      final box = Hive.box('sessions');
      final sessions = getAllSessions();
      sessions.removeWhere((s) => s.id == id);

      // Clear and re-save all sessions
      box.clear();
      for (int i = 0; i < sessions.length; i++) {
        box.put(i.toString(), sessions[i].toMap());
      }

      // Recalculate stats
      _recalculateStats();
    } catch (e) {
      debugPrint('⚠️ Storage error in deleteSession: $e');
    }
  }

  /// Clears ALL data — sessions, stats, everything.
  void clearAll() {
    try {
      Hive.box('sessions').clear();
      final statsBox = Hive.box('stats');
      statsBox.put('totalSessions', 0);
      statsBox.put('totalMinutes', 0);
      statsBox.put('streak', 0);
      statsBox.put('lastSessionDate', null);
    } catch (e) {
      debugPrint('⚠️ Storage error in clearAll: $e');
    }
  }

  /// Recalculates total sessions, hours, and streak from raw session data.
  void _recalculateStats() {
    final sessions = getAllSessions();
    final statsBox = Hive.box('stats');

    int totalMinutes = 0;
    for (final s in sessions) {
      totalMinutes += s.durationMinutes;
    }

    statsBox.put('totalSessions', sessions.length);
    statsBox.put('totalMinutes', totalMinutes);

    // Recalculate streak
    if (sessions.isEmpty) {
      statsBox.put('streak', 0);
      return;
    }

    // Sort by date descending
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    int streak = 0;
    DateTime? lastDate;

    for (final s in sessions) {
      final sessionDate = DateTime(
        s.startTime.year,
        s.startTime.month,
        s.startTime.day,
      );

      if (lastDate == null) {
        // First session — check if it's today or yesterday
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final diff = todayDate.difference(sessionDate).inDays;

        if (diff <= 1) {
          streak = 1;
          lastDate = sessionDate;
        } else {
          break; // Most recent session is too old
        }
      } else {
        final diff = lastDate.difference(sessionDate).inDays;
        if (diff == 1) {
          streak++;
          lastDate = sessionDate;
        } else if (diff == 0) {
          continue; // Same day, skip
        } else {
          break; // Gap in streak
        }
      }
    }

    statsBox.put('streak', streak);
  }

  // ══════════════════════════════════════
  // ANALYTICS METHODS (for stats screen)
  // ══════════════════════════════════════

  /// Best all-time streak
  int getBestStreak() {
    try {
      return _statsBox.get('bestStreak', defaultValue: 0) as int;
    } catch (e) {
      debugPrint('⚠️ Storage error in getBestStreak: $e');
      return 0;
    }
  }

  /// Update best streak if current is higher
  Future<void> updateBestStreak() async {
    try {
      final current = getStreak();
      final best = getBestStreak();
      if (current > best) {
        await _statsBox.put('bestStreak', current);
      }
    } catch (e) {
      debugPrint('⚠️ Storage error in updateBestStreak: $e');
    }
  }

  /// Daily focus minutes for the last N days (for heatmap / bar chart).
  /// Returns a map of date-string ('yyyy-MM-dd') → total minutes.
  Map<String, int> getDailyFocusMap({int days = 30}) {
    try {
      final sessions = getAllSessions().where((s) => s.completed).toList();
      final now = DateTime.now();
      final Map<String, int> map = {};

      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        map[key] = 0;
      }

      for (final s in sessions) {
        final key =
            '${s.startTime.year}-${s.startTime.month.toString().padLeft(2, '0')}-${s.startTime.day.toString().padLeft(2, '0')}';
        if (map.containsKey(key)) {
          map[key] = map[key]! + s.durationMinutes;
        }
      }

      return map;
    } catch (e) {
      debugPrint('⚠️ Storage error in getDailyFocusMap: $e');
      return {};
    }
  }

  /// Weekly stats: returns a list of 7 daily totals (Mon=0, Sun=6).
  List<double> getWeeklyStats() {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final sessions = getAllSessions().where((s) => s.completed).toList();
      final List<double> data = List.filled(7, 0);

      for (final s in sessions) {
        final diff =
            s.startTime
                .difference(
                  DateTime(weekStart.year, weekStart.month, weekStart.day),
                )
                .inDays;
        if (diff >= 0 && diff < 7) {
          data[diff] += s.durationMinutes.toDouble();
        }
      }
      return data;
    } catch (e) {
      debugPrint('⚠️ Storage error in getWeeklyStats: $e');
      return List.filled(7, 0);
    }
  }

  /// Monthly stats: returns up to 30 daily totals.
  List<double> getMonthlyStats() {
    try {
      final now = DateTime.now();
      final sessions = getAllSessions().where((s) => s.completed).toList();
      final List<double> data = List.filled(30, 0);

      for (final s in sessions) {
        final diff = now.difference(s.startTime).inDays;
        if (diff >= 0 && diff < 30) {
          data[29 - diff] += s.durationMinutes.toDouble();
        }
      }
      return data;
    } catch (e) {
      debugPrint('⚠️ Storage error in getMonthlyStats: $e');
      return List.filled(30, 0);
    }
  }

  /// Focus time per route (for pie chart).
  /// Returns a map of routeName → total minutes.
  Map<String, int> getSessionsByRoute() {
    try {
      final sessions = getAllSessions().where((s) => s.completed);
      final Map<String, int> map = {};
      for (final s in sessions) {
        map[s.routeName] = (map[s.routeName] ?? 0) + s.durationMinutes;
      }
      return map;
    } catch (e) {
      debugPrint('⚠️ Storage error in getSessionsByRoute: $e');
      return {};
    }
  }

  /// Sessions by time of day for analytics.
  /// Returns a map: 'morning' | 'afternoon' | 'evening' | 'night' → count
  Map<String, int> getSessionsByTimeOfDay() {
    try {
      final sessions = getAllSessions().where((s) => s.completed);
      final map = {'morning': 0, 'afternoon': 0, 'evening': 0, 'night': 0};
      for (final s in sessions) {
        final h = s.startTime.hour;
        if (h >= 5 && h < 12) {
          map['morning'] = map['morning']! + 1;
        } else if (h >= 12 && h < 17) {
          map['afternoon'] = map['afternoon']! + 1;
        } else if (h >= 17 && h < 21) {
          map['evening'] = map['evening']! + 1;
        } else {
          map['night'] = map['night']! + 1;
        }
      }
      return map;
    } catch (e) {
      debugPrint('⚠️ Storage error in getSessionsByTimeOfDay: $e');
      return {'morning': 0, 'afternoon': 0, 'evening': 0, 'night': 0};
    }
  }

  /// Most productive hour of day (0-23)
  int getMostProductiveHour() {
    try {
      final sessions = getAllSessions().where((s) => s.completed);
      final List<int> hourCounts = List.filled(24, 0);
      for (final s in sessions) {
        hourCounts[s.startTime.hour] += s.durationMinutes;
      }
      int maxHour = 0;
      for (int i = 1; i < 24; i++) {
        if (hourCounts[i] > hourCounts[maxHour]) maxHour = i;
      }
      return maxHour;
    } catch (e) {
      return 9; // default
    }
  }

  /// Completion rate (percentage of completed vs total sessions)
  double getCompletionRate() {
    try {
      final all = getAllSessions();
      if (all.isEmpty) return 0.0;
      final completed = all.where((s) => s.completed).length;
      return (completed / all.length) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  // ══════════════════════════════════════
  // STREAK FREEZE
  // ══════════════════════════════════════

  /// Number of streak freezes available
  int getStreakFreezeCount() {
    try {
      return _statsBox.get('streakFreezes', defaultValue: 0) as int;
    } catch (e) {
      return 0;
    }
  }

  // ══════════════════════════════════════
  // STATION BUILDING
  // ══════════════════════════════════════

  /// Total bricks collected for station building
  int getBricks() {
    try {
      return _statsBox.get('bricks', defaultValue: 0) as int;
    } catch (e) {
      debugPrint('⚠️ Storage error in getBricks: $e');
      return 0;
    }
  }

  /// Add bricks (earned from focus sessions)
  Future<void> addBricks(int count) async {
    try {
      final current = getBricks();
      await _statsBox.put('bricks', current + count);
    } catch (e) {
      debugPrint('⚠️ Storage error in addBricks: $e');
    }
  }

  /// Get current station level (0–10 based on total bricks)
  int getStationLevel() {
    final bricks = getBricks();
    if (bricks >= 500) return 10;
    if (bricks >= 350) return 9;
    if (bricks >= 250) return 8;
    if (bricks >= 180) return 7;
    if (bricks >= 120) return 6;
    if (bricks >= 80) return 5;
    if (bricks >= 50) return 4;
    if (bricks >= 30) return 3;
    if (bricks >= 15) return 2;
    if (bricks >= 5) return 1;
    return 0;
  }

  /// Bricks needed for the next level
  int bricksForNextLevel() {
    const thresholds = [5, 15, 30, 50, 80, 120, 180, 250, 350, 500];
    final level = getStationLevel();
    if (level >= 10) return 0;
    return thresholds[level];
  }

  /// Add a streak freeze (earned via achievements or settings)
  Future<void> addStreakFreeze() async {
    try {
      final current = getStreakFreezeCount();
      await _statsBox.put('streakFreezes', current + 1);
    } catch (e) {
      debugPrint('⚠️ Storage error in addStreakFreeze: $e');
    }
  }

  /// Use a streak freeze to protect streak
  Future<bool> useStreakFreeze() async {
    try {
      final count = getStreakFreezeCount();
      if (count <= 0) return false;
      await _statsBox.put('streakFreezes', count - 1);
      await _statsBox.put(
        'lastStreakFreezeDate',
        DateTime.now().millisecondsSinceEpoch,
      );
      return true;
    } catch (e) {
      debugPrint('⚠️ Storage error in useStreakFreeze: $e');
      return false;
    }
  }

  // ══════════════════════════════════════
  // DATA EXPORT
  // ══════════════════════════════════════

  /// Generate CSV content from all sessions
  String exportDataAsCsv() {
    try {
      final sessions = getAllSessions();
      final buffer = StringBuffer();

      // Header
      buffer.writeln(
        'ID,Route,Duration (min),Start Time,Completed,Mood,Goal,Note,Tags,Category',
      );

      for (final s in sessions) {
        final tags = s.tags?.join(';') ?? '';
        final escapedGoal = (s.goal ?? '').replaceAll(',', ';');
        final escapedNote = (s.note ?? '').replaceAll(',', ';');
        buffer.writeln(
          '${s.id},'
          '${s.routeName},'
          '${s.durationMinutes},'
          '${s.startTime.toIso8601String()},'
          '${s.completed},'
          '${s.mood ?? ''},'
          '$escapedGoal,'
          '$escapedNote,'
          '$tags,'
          '${s.category ?? ''}',
        );
      }
      return buffer.toString();
    } catch (e) {
      debugPrint('⚠️ Storage error in exportDataAsCsv: $e');
      return '';
    }
  }

  // ══════════════════════════════════════
  // DAILY CHALLENGES
  // ══════════════════════════════════════

  /// Check if today's challenge has been completed
  bool isChallengeCompleted(String challengeId) {
    try {
      return _statsBox.get('challenge_done_$challengeId', defaultValue: false) as bool;
    } catch (e) {
      return false;
    }
  }

  /// Mark a challenge as completed
  Future<void> completeDailyChallenge(String challengeId, int brickReward) async {
    try {
      if (isChallengeCompleted(challengeId)) return; // Already done
      await _statsBox.put('challenge_done_$challengeId', true);
      await addBricks(brickReward);
    } catch (e) {
      debugPrint('⚠️ Storage error in completeDailyChallenge: $e');
    }
  }

  /// Get today's focus minutes
  int getTodayMinutes() {
    try {
      final now = DateTime.now();
      final sessions = getAllSessions().where((s) =>
        s.completed &&
        s.startTime.year == now.year &&
        s.startTime.month == now.month &&
        s.startTime.day == now.day
      );
      int total = 0;
      for (final s in sessions) {
        total += s.durationMinutes;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  /// Get today's session count
  int getTodaySessionCount() {
    try {
      final now = DateTime.now();
      return getAllSessions().where((s) =>
        s.completed &&
        s.startTime.year == now.year &&
        s.startTime.month == now.month &&
        s.startTime.day == now.day
      ).length;
    } catch (e) {
      return 0;
    }
  }

  /// Check if user focused on a specific route today
  bool hasRouteToday(String routeName) {
    try {
      final now = DateTime.now();
      return getAllSessions().any((s) =>
        s.completed &&
        s.routeName == routeName &&
        s.startTime.year == now.year &&
        s.startTime.month == now.month &&
        s.startTime.day == now.day
      );
    } catch (e) {
      return false;
    }
  }

  /// Check if user completed a session before a given hour
  bool hasSessionBeforeHour(int hour) {
    try {
      final now = DateTime.now();
      return getAllSessions().any((s) =>
        s.completed &&
        s.startTime.year == now.year &&
        s.startTime.month == now.month &&
        s.startTime.day == now.day &&
        s.startTime.hour < hour
      );
    } catch (e) {
      return false;
    }
  }

  /// Check if user completed a session after a given hour
  bool hasSessionAfterHour(int hour) {
    try {
      final now = DateTime.now();
      return getAllSessions().any((s) =>
        s.completed &&
        s.startTime.year == now.year &&
        s.startTime.month == now.month &&
        s.startTime.day == now.day &&
        s.startTime.hour >= hour
      );
    } catch (e) {
      return false;
    }
  }

  /// Get focus minutes per day for last 35 days (for streak calendar)
  Map<String, int> getFocusDataLast35Days() {
    try {
      final now = DateTime.now();
      final result = <String, int>{};
      final sessions = getAllSessions();

      for (int i = 0; i < 35; i++) {
        final day = now.subtract(Duration(days: 34 - i));
        final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        int total = 0;
        for (final s in sessions) {
          if (s.completed &&
              s.startTime.year == day.year &&
              s.startTime.month == day.month &&
              s.startTime.day == day.day) {
            total += s.durationMinutes;
          }
        }
        result[key] = total;
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  // ══════════════════════════════════════
  // FOCUS PROJECTS
  // ══════════════════════════════════════

  Box get _projectsBox => Hive.box('projects');

  /// Returns all saved projects.
  List<Map<String, dynamic>> getProjects() {
    try {
      return _projectsBox.values
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Storage error getProjects: $e');
      return [];
    }
  }

  /// Saves (or updates) a project by its id.
  void saveProject(Map<String, dynamic> projectMap) {
    try {
      _projectsBox.put(projectMap['id'], projectMap);
    } catch (e) {
      debugPrint('⚠️ Storage error saveProject: $e');
    }
  }

  /// Deletes a project by id.
  void deleteProject(String id) {
    try {
      _projectsBox.delete(id);
    } catch (e) {
      debugPrint('⚠️ Storage error deleteProject: $e');
    }
  }

  /// Returns total completed minutes grouped by projectId for the
  /// last [days] days. Used in the Insights project breakdown chart.
  Map<String, int> getProjectMinutes({int days = 30}) {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final result = <String, int>{};
      for (final s in getAllSessions()) {
        if (!s.completed) continue;
        if (s.startTime.isBefore(cutoff)) continue;
        final pid = s.category ?? 'uncategorized';
        result[pid] = (result[pid] ?? 0) + s.durationMinutes;
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  // ══════════════════════════════════════
  // VOICE REFLECTION
  // ══════════════════════════════════════

  /// Saves a reflection text for an existing session (identified by id).
  void saveReflection(String sessionId, String reflection) {
    try {
      final box = _sessionsBox;
      for (int i = 0; i < box.length; i++) {
        final raw = Map<String, dynamic>.from(box.getAt(i) as Map);
        if (raw['id'] == sessionId) {
          raw['reflection'] = reflection;
          box.putAt(i, raw);
          return;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Storage error saveReflection: $e');
    }
  }
}

