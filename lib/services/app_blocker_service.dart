// lib/services/app_blocker_service.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — APP BLOCKER SERVICE
//  Manages a list of apps to block during focus sessions.
//  Uses SharedPreferences to persist the blocklist.
//
//  NOTE: Actual app blocking on Android requires an
//  AccessibilityService or DevicePolicyManager, which
//  requires user-granted permissions. This service provides
//  the Dart-side blocklist management + native method channel
//  hooks ready for the Android side.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBlockerService {
  AppBlockerService._();
  static final instance = AppBlockerService._();

  static const _channel = MethodChannel('com.example.railfocus/appblocker');
  static const _prefsKey = 'blocked_apps';

  List<String> _blockedApps = [];
  bool _isBlocking = false;

  List<String> get blockedApps => List.unmodifiable(_blockedApps);
  bool get isBlocking => _isBlocking;

  /// Load the blocked apps list from SharedPreferences
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _blockedApps = prefs.getStringList(_prefsKey) ?? _defaultBlockedApps;
      debugPrint('🚫 AppBlocker: Loaded ${_blockedApps.length} blocked apps');
    } catch (e) {
      debugPrint('🔴 AppBlocker load error: $e');
      _blockedApps = _defaultBlockedApps;
    }
  }

  /// Save the blocked apps list
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _blockedApps);
    } catch (e) {
      debugPrint('🔴 AppBlocker save error: $e');
    }
  }

  /// Add an app to the blocklist
  Future<void> addApp(String packageName) async {
    if (!_blockedApps.contains(packageName)) {
      _blockedApps.add(packageName);
      await _save();
    }
  }

  /// Remove an app from the blocklist
  Future<void> removeApp(String packageName) async {
    _blockedApps.remove(packageName);
    await _save();
  }

  /// Toggle an app in the blocklist
  Future<void> toggleApp(String packageName) async {
    if (_blockedApps.contains(packageName)) {
      await removeApp(packageName);
    } else {
      await addApp(packageName);
    }
  }

  /// Start blocking (call when focus session starts)
  Future<void> startBlocking() async {
    _isBlocking = true;
    try {
      await _channel.invokeMethod('startBlocking', {
        'apps': _blockedApps,
      });
      debugPrint('🚫 AppBlocker: Blocking started');
    } catch (e) {
      // MethodChannel not set up yet — native side needed
      debugPrint('🔴 AppBlocker: Native channel not available: $e');
    }
  }

  /// Stop blocking (call when focus session ends)
  Future<void> stopBlocking() async {
    _isBlocking = false;
    try {
      await _channel.invokeMethod('stopBlocking');
      debugPrint('✅ AppBlocker: Blocking stopped');
    } catch (e) {
      debugPrint('🔴 AppBlocker: Native channel not available: $e');
    }
  }

  /// Default apps most people want to block
  static const _defaultBlockedApps = [
    'com.instagram.android',
    'com.google.android.youtube',
    'com.twitter.android',
    'com.facebook.katana',
    'com.zhiliaoapp.musically', // TikTok
    'com.snapchat.android',
    'com.reddit.frontpage',
    'com.whatsapp',
  ];

  /// Commonly blocked apps with display names
  static const commonApps = [
    {'name': 'Instagram', 'package': 'com.instagram.android', 'emoji': '📷'},
    {'name': 'YouTube', 'package': 'com.google.android.youtube', 'emoji': '📺'},
    {'name': 'X (Twitter)', 'package': 'com.twitter.android', 'emoji': '🐦'},
    {'name': 'Facebook', 'package': 'com.facebook.katana', 'emoji': '👤'},
    {'name': 'TikTok', 'package': 'com.zhiliaoapp.musically', 'emoji': '🎵'},
    {'name': 'Snapchat', 'package': 'com.snapchat.android', 'emoji': '👻'},
    {'name': 'Reddit', 'package': 'com.reddit.frontpage', 'emoji': '🤖'},
    {'name': 'WhatsApp', 'package': 'com.whatsapp', 'emoji': '💬'},
    {'name': 'Telegram', 'package': 'org.telegram.messenger', 'emoji': '✈️'},
    {'name': 'Discord', 'package': 'com.discord', 'emoji': '🎮'},
    {'name': 'Pinterest', 'package': 'com.pinterest', 'emoji': '📌'},
    {'name': 'LinkedIn', 'package': 'com.linkedin.android', 'emoji': '💼'},
  ];
}
