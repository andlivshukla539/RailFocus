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
      final int totalMinutes = _statsBox.get(
        'totalMinutes',
        defaultValue: 0,
      ) as int;
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
        final int prevMinutes = _statsBox.get(
          'totalMinutes',
          defaultValue: 0,
        ) as int;
        await _statsBox.put(
          'totalMinutes',
          prevMinutes + session.durationMinutes,
        );

        // Update streak
        await _updateStreak();

        // Update unique routes count
        await _updateRouteCount(session.routeName);
      }
    } catch (e) {
      debugPrint('⚠️ Storage error in saveSession: $e');
    }
  }

  /// Recalculates the streak based on session dates.
  /// A streak increments when the user has a completed session
  /// today AND had one yesterday (or this is day one).
  Future<void> _updateStreak() async {
    final sessions = getAllSessions()
        .where((s) => s.completed)
        .toList();

    if (sessions.isEmpty) {
      await _statsBox.put('streak', 0);
      return;
    }

    int streak = 1;
    // Start from today and walk backwards
    DateTime checkDate = DateTime.now();

    // Check if there's a session today
    bool hasToday = sessions.any(
          (s) => _isSameDay(s.startTime, checkDate),
    );

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
      bool hasPrevDay = sessions.any(
            (s) => _isSameDay(s.startTime, prevDay),
      );
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
    final allRoutes = getAllSessions()
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
}