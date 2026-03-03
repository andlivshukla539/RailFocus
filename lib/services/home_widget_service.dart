// lib/services/home_widget_service.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — HOME WIDGET SERVICE
//  Provides widget data for the Android home screen widget.
//  Uses shared_preferences to pass data between Flutter and
//  the native widget since home_widget depends on it.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service.dart';

class HomeWidgetService {
  HomeWidgetService._();
  static final instance = HomeWidgetService._();

  final _storage = StorageService();

  /// Update the widget data (call after each session)
  Future<void> updateWidgetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save current stats for the widget to read
      await prefs.setInt('widget_streak', _storage.getStreak());
      await prefs.setDouble('widget_hours', _storage.getTotalHours());
      await prefs.setInt('widget_sessions', _storage.getTotalSessions());
      await prefs.setInt('widget_bricks', _storage.getBricks());
      await prefs.setInt('widget_station_level', _storage.getStationLevel());

      // Today's focus minutes
      await prefs.setInt('widget_today_minutes', _storage.getTodayMinutes());
      await prefs.setInt('widget_today_sessions', _storage.getTodaySessionCount());

      // Last update time
      await prefs.setString('widget_last_update', DateTime.now().toIso8601String());

      debugPrint('📱 HomeWidget: Data updated');
    } catch (e) {
      debugPrint('🔴 HomeWidget update error: $e');
    }
  }

  /// Get summary text for the widget
  static Future<Map<String, dynamic>> getWidgetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'streak': prefs.getInt('widget_streak') ?? 0,
        'hours': prefs.getDouble('widget_hours') ?? 0.0,
        'sessions': prefs.getInt('widget_sessions') ?? 0,
        'bricks': prefs.getInt('widget_bricks') ?? 0,
        'stationLevel': prefs.getInt('widget_station_level') ?? 0,
        'todayMinutes': prefs.getInt('widget_today_minutes') ?? 0,
        'todaySessions': prefs.getInt('widget_today_sessions') ?? 0,
      };
    } catch (e) {
      return {};
    }
  }
}
