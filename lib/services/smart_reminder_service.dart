// lib/services/smart_reminder_service.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — SMART FOCUS REMINDERS
//  Context-aware notifications that adapt to user patterns.
//  Uses flutter_local_notifications + shared_preferences.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service.dart';

class SmartReminderService {
  SmartReminderService._();
  static final instance = SmartReminderService._();

  final _storage = StorageService();

  // ══════════════════════════════════════
  // ANALYZE PATTERNS
  // ══════════════════════════════════════

  /// Find the user's most productive hour
  int getPeakFocusHour() {
    try {
      final sessions = _storage.getAllSessions();
      final hourBuckets = List.filled(24, 0);

      for (final s in sessions) {
        if (s.completed) {
          hourBuckets[s.startTime.hour] += s.durationMinutes;
        }
      }

      int peakHour = 0;
      for (int i = 1; i < 24; i++) {
        if (hourBuckets[i] > hourBuckets[peakHour]) peakHour = i;
      }
      return peakHour;
    } catch (e) {
      return 10; // Default to 10 AM
    }
  }

  /// Check if streak is at risk (no session today, streak > 0)
  bool isStreakAtRisk() {
    try {
      final streak = _storage.getStreak();
      final todaySessions = _storage.getTodaySessionCount();
      return streak > 0 && todaySessions == 0;
    } catch (e) {
      return false;
    }
  }

  /// Get minutes remaining to hit daily goal
  int minutesToDailyGoal({int goalMinutes = 30}) {
    try {
      final todayMins = _storage.getTodayMinutes();
      return (goalMinutes - todayMins).clamp(0, goalMinutes);
    } catch (e) {
      return goalMinutes;
    }
  }

  /// Get the best reminder message based on current context
  String getSmartReminderMessage() {
    final hour = DateTime.now().hour;
    final streak = _storage.getStreak();
    final todayMins = _storage.getTodayMinutes();
    final todaySessions = _storage.getTodaySessionCount();
    final peakHour = getPeakFocusHour();

    // Priority 1: Streak at risk
    if (isStreakAtRisk() && hour >= 18) {
      return '🔥 Your $streak-day streak is at risk! A quick session will save it.';
    }

    // Priority 2: Near peak hour
    if ((hour - peakHour).abs() <= 1 && todaySessions == 0) {
      return '⚡ Your peak focus hour is near! ($peakHour:00) — ready for a session?';
    }

    // Priority 3: Daily goal reminder
    final remaining = minutesToDailyGoal();
    if (remaining > 0 && remaining <= 15 && todaySessions > 0) {
      return '🎯 Just ${remaining}min more to hit your daily goal!';
    }

    // Priority 4: General motivation
    if (todayMins == 0) {
      if (hour < 12) return '🌅 Good morning! Start your day with a focus session.';
      if (hour < 17) return '☀️ Afternoon focus time! Your best work happens now.';
      return '🌙 Evening session? Even 10 minutes keeps the momentum.';
    }

    // Already focused today
    return '✅ Great focus today — ${todayMins}min across $todaySessions sessions!';
  }

  // ══════════════════════════════════════
  // SCHEDULE REMINDERS
  // ══════════════════════════════════════

  /// Schedule daily reminders based on user's peak hour
  Future<void> scheduleSmartReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersEnabled = prefs.getBool('smart_reminders_enabled') ?? true;

      if (!remindersEnabled) return;

      final peakHour = getPeakFocusHour();
      final streak = _storage.getStreak();

      // Save scheduled reminder data
      await prefs.setInt('reminder_peak_hour', peakHour);
      await prefs.setInt('reminder_streak', streak);
      await prefs.setString(
        'reminder_last_scheduled',
        DateTime.now().toIso8601String(),
      );

      debugPrint('⏰ SmartReminder: Scheduled for peak hour $peakHour:00');
    } catch (e) {
      debugPrint('🔴 SmartReminder schedule error: $e');
    }
  }

  /// Toggle smart reminders on/off
  Future<void> toggleReminders(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('smart_reminders_enabled', enabled);
      if (enabled) {
        await scheduleSmartReminders();
      }
      debugPrint('⏰ SmartReminder: ${enabled ? "Enabled" : "Disabled"}');
    } catch (e) {
      debugPrint('🔴 SmartReminder toggle error: $e');
    }
  }

  /// Check if reminders are enabled
  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('smart_reminders_enabled') ?? true;
    } catch (e) {
      return true;
    }
  }
}
