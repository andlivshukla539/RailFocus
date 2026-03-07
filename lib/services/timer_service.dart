// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — TIMER SERVICE
//  Theme: Station Master's Precision Clock
//
//  PROBLEM THIS SOLVES:
//  ─────────────────────────────────────────────────────────────
//  When the user minimizes the app during a 45-minute focus
//  session, the Dart Timer pauses (it's not a real OS timer).
//  When they come back 10 minutes later, the timer shows 44:59
//  instead of 34:59.
//
//  SOLUTION:
//  Store the session end time as an absolute DateTime in
//  SharedPreferences. When the app resumes, calculate remaining
//  seconds from DateTime.now() vs the stored end time.
//  This gives accurate time regardless of how long the app
//  was backgrounded.
//
//  USAGE:
//    final timer = TimerService();
//    await timer.startSession(durationMinutes: 25, routeName: 'Tokyo to Kyoto');
//    int remaining = timer.getRemainingSeconds();  // Always accurate
//    await timer.endSession();
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class TimerService {
  // ── Prefs Keys ─────────────────────────────────────────────
  static const String _keyEndEpoch = 'session_end_epoch';
  static const String _keyRoute = 'session_route_name';
  static const String _keyDuration = 'session_duration_min';
  static const String _keyStarted = 'session_started';
  static const String _keyPausedAt = 'session_paused_at';

  // ── State ──────────────────────────────────────────────────
  DateTime? _endTime;
  DateTime? _pausedAt;
  bool _isRunning = false;
  String _routeName = '';
  int _durationMinutes = 25;

  // ── Getters ────────────────────────────────────────────────
  bool get isRunning => _isRunning;
  bool get isPaused => _pausedAt != null;
  String get routeName => _routeName;
  int get durationMinutes => _durationMinutes;

  /// Returns the number of seconds remaining in the session.
  /// This is ALWAYS accurate because it's based on wall-clock time,
  /// not on a Dart Timer tick count.
  int getRemainingSeconds() {
    if (_endTime == null) return 0;

    if (_pausedAt != null) {
      // If paused, remaining time is frozen at the moment we paused.
      return _endTime!.difference(_pausedAt!).inSeconds.clamp(0, 99999);
    }

    final remaining = _endTime!.difference(DateTime.now()).inSeconds;
    return remaining.clamp(0, 99999);
  }

  /// Returns progress as 0.0 to 1.0.
  double getProgress() {
    final totalSec = _durationMinutes * 60;
    if (totalSec == 0) return 0;
    final elapsed = totalSec - getRemainingSeconds();
    return (elapsed / totalSec).clamp(0.0, 1.0);
  }

  /// Returns true if the timer has expired (remaining <= 0).
  bool isComplete() {
    return _isRunning && getRemainingSeconds() <= 0;
  }

  // ══════════════════════════════════════════════════��═══════
  // START SESSION
  // ══════════════════════════════════════════════════════════

  /// Starts a new session timer.
  ///
  /// Stores the end time in SharedPreferences so it survives
  /// app backgrounding. Also schedules a notification for when
  /// the session should end.
  Future<void> startSession({
    required int durationMinutes,
    required String routeName,
    String routeEmoji = '🚂',
  }) async {
    _durationMinutes = durationMinutes;
    _routeName = routeName;
    _endTime = DateTime.now().add(Duration(minutes: durationMinutes));
    _pausedAt = null;
    _isRunning = true;

    // Persist to SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyEndEpoch, _endTime!.millisecondsSinceEpoch);
    await prefs.setString(_keyRoute, routeName);
    await prefs.setInt(_keyDuration, durationMinutes);
    await prefs.setBool(_keyStarted, true);
    await prefs.remove(_keyPausedAt);

    // Schedule the "You've arrived!" notification.
    await NotificationService.scheduleSessionEnd(
      endTime: _endTime!,
      routeName: routeName,
      emoji: routeEmoji,
    );

    // Show the ongoing live-countdown notification in the status bar.
    await NotificationService.showOngoingTimer(
      remainingMinutes: durationMinutes,
      remainingSeconds: 0,
      routeName: routeName,
      routeEmoji: routeEmoji,
      totalMinutes: durationMinutes,
    );

    debugPrint(
      '⏱️ TimerService: Started $durationMinutes min session'
      ' — ends at $_endTime',
    );
  }

  // ══════════════════════════════════════════════════════════
  // PAUSE / RESUME
  // ══════════════════════════════════════════════════════════

  /// Pauses the session timer.
  /// Stores the remaining time so we can recalculate the end time
  /// when the user resumes.
  Future<void> pause() async {
    if (!_isRunning || _pausedAt != null) return;

    _pausedAt = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPausedAt, _pausedAt!.millisecondsSinceEpoch);

    // Cancel the scheduled notification since we're paused.
    await NotificationService.cancelSessionEnd();
    await NotificationService.cancelOngoingTimer();

    debugPrint('⏱️ TimerService: Paused — ${getRemainingSeconds()}s remaining');
  }

  /// Resumes the session timer after a pause.
  /// Recalculates the end time based on how much time was remaining
  /// when we paused.
  Future<void> resume() async {
    if (!_isRunning || _pausedAt == null) return;

    // Calculate how many seconds were remaining when we paused.
    final remainingWhenPaused = _endTime!.difference(_pausedAt!).inSeconds;

    // Set a new end time from NOW + remaining seconds.
    _endTime = DateTime.now().add(Duration(seconds: remainingWhenPaused));
    _pausedAt = null;

    // Persist the new end time.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyEndEpoch, _endTime!.millisecondsSinceEpoch);
    await prefs.remove(_keyPausedAt);

    // Reschedule the notification with the new end time.
    await NotificationService.scheduleSessionEnd(
      endTime: _endTime!,
      routeName: _routeName,
    );
    await NotificationService.showOngoingTimer(
      remainingMinutes: remainingWhenPaused ~/ 60,
      remainingSeconds: remainingWhenPaused % 60,
      routeName: _routeName,
      totalMinutes: _durationMinutes,
    );

    debugPrint(
      '⏱️ TimerService: Resumed — ${getRemainingSeconds()}s remaining',
    );
  }

  // ══════════════════════════════════════════════════════════
  // END SESSION
  // ══════════════════════════════════════════════════════════

  /// Ends the current session (either completed or emergency stop).
  /// Clears all persisted state and cancels notifications.
  Future<void> endSession() async {
    _isRunning = false;
    _endTime = null;
    _pausedAt = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEndEpoch);
    await prefs.remove(_keyRoute);
    await prefs.remove(_keyDuration);
    await prefs.remove(_keyPausedAt);
    await prefs.setBool(_keyStarted, false);

    await NotificationService.cancelSessionEnd();
    await NotificationService.cancelOngoingTimer();

    debugPrint('⏱️ TimerService: Session ended');
  }

  // ══════════════════════════════════════════════════════════
  // RECOVER FROM BACKGROUND
  // ══════════════════════════════════════════════════════════

  /// Restores session state from SharedPreferences.
  /// Called when the app resumes from background or cold starts
  /// while a session was active.
  ///
  /// Returns true if a session was restored (timer is still running).
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final started = prefs.getBool(_keyStarted) ?? false;

    if (!started) {
      debugPrint('⏱️ TimerService: No active session to restore');
      return false;
    }

    final endEpoch = prefs.getInt(_keyEndEpoch);
    final route = prefs.getString(_keyRoute);
    final duration = prefs.getInt(_keyDuration);
    final pausedEpoch = prefs.getInt(_keyPausedAt);

    if (endEpoch == null || route == null || duration == null) {
      // Corrupted state — clear everything.
      await endSession();
      return false;
    }

    _endTime = DateTime.fromMillisecondsSinceEpoch(endEpoch);
    _routeName = route;
    _durationMinutes = duration;
    _isRunning = true;

    if (pausedEpoch != null) {
      _pausedAt = DateTime.fromMillisecondsSinceEpoch(pausedEpoch);
    }

    final remaining = getRemainingSeconds();

    if (remaining <= 0 && _pausedAt == null) {
      // Session expired while app was in background.
      // The notification should have already fired.
      debugPrint('⏱️ TimerService: Session expired in background');
      return true; // Let the caller handle navigation to arrival
    }

    debugPrint('⏱️ TimerService: Restored session — ${remaining}s remaining');
    return true;
  }
}
