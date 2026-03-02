// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — WAKELOCK SERVICE
//  Keeps the screen on during focus sessions so users can
//  watch the landscape animation without the phone sleeping.
//
//  USAGE:
//    WakelockService.enable();   // Focus session starts
//    WakelockService.disable();  // Session ends / app closes
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WakelockService {
  WakelockService._();

  /// SharedPreferences key for user preference.
  static const String _prefKey = 'wakelock_enabled';

  /// Enable wakelock — screen stays on.
  /// Only activates if the user hasn't disabled it in settings.
  static Future<void> enable() async {
    final prefs = await SharedPreferences.getInstance();
    final userEnabled = prefs.getBool(_prefKey) ?? true; // On by default

    if (userEnabled) {
      await WakelockPlus.enable();
      debugPrint('🔆 WakelockService: Screen will stay ON');
    }
  }

  /// Disable wakelock — screen can sleep normally.
  static Future<void> disable() async {
    await WakelockPlus.disable();
    debugPrint('🔆 WakelockService: Screen lock restored');
  }

  /// Check if wakelock is currently active.
  static Future<bool> isEnabled() async {
    return await WakelockPlus.enabled;
  }

  /// Set user preference for wakelock.
  static Future<void> setPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);

    if (!enabled) {
      await disable();
    }
  }

  /// Get user preference for wakelock.
  static Future<bool> getPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }
}
