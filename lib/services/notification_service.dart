// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — NOTIFICATION SERVICE
//  Theme: Grand Station Announcements
//
//  RESPONSIBILITIES:
//  ─────────────────────────────────────────────────────────────
//  • Initialize local notifications plugin
//  • Request permission on Android 13+ (API 33)
//  • Schedule "You've arrived!" notification at session end time
//  • Cancel pending notifications (emergency stop / manual end)
//  • Schedule daily reminder ("Time for your journey?")
//  • Manage notification channels with luxury branding
//
//  USAGE:
//    await NotificationService.init();
//    await NotificationService.scheduleSessionEnd(
//      endTime: DateTime.now().add(Duration(minutes: 25)),
//      routeName: 'Tokyo to Kyoto',
//    );
//    await NotificationService.cancelSessionEnd();
//
//  NOTIFICATION IDS:
//    0 = Session complete
//    1 = Daily reminder
//    2 = Streak at risk
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart'; // Provides Color, debugPrint, etc.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
// NOTIFICATION IDS — Each type gets a unique integer ID.
// Using constants prevents accidental collision.
// ═══════════════════════════════════════════════════════════════

class _Ids {
  static const int sessionComplete = 0;
  static const int dailyReminder = 1;
  static const int streakAtRisk = 2;
  static const int ongoingTimer = 3;
}

// ═══════════════════════════════════════════════════════════════
// PREFS KEYS — SharedPreferences keys for notification settings.
// ═══════════════════════════════════════════════════════════════

class NotifPrefs {
  NotifPrefs._();

  /// Whether notifications are enabled at all.
  static const String enabled = 'notif_enabled';

  /// Whether daily reminder is enabled.
  static const String dailyEnabled = 'notif_daily_enabled';

  /// Hour of daily reminder (0-23).
  static const String dailyHour = 'notif_daily_hour';

  /// Minute of daily reminder (0-59).
  static const String dailyMinute = 'notif_daily_minute';

  /// The epoch millisecond when the current session should end.
  /// Stored so we can recalculate remaining time on app resume.
  static const String sessionEndEpoch = 'session_end_epoch';

  /// Route name for the current session (used in notification text).
  static const String sessionRoute = 'session_route_name';
}

// ═══════════════════════════════════════════════════════════════
// NOTIFICATION SERVICE
// ═══════════════════════════════════════════════════════════════

class NotificationService {
  NotificationService._();

  // The plugin instance — singleton, initialized once.
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Whether the service has been initialized.
  static bool _initialized = false;

  // ══════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════

  /// Must be called once at app startup (in main.dart).
  /// Initializes timezone data and the notification plugin.
  static Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone database — required for scheduling
    // notifications at a specific future DateTime.
    tz_data.initializeTimeZones();

    // Android initialization settings.
    // The @mipmap/ic_launcher is the default app icon — used as
    // the notification small icon. You can replace this with a
    // custom drawable later.
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings.
    // requestAlertPermission etc. are set to false here because
    // we'll request permission explicitly via permission_handler.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin.
    // onDidReceiveNotificationResponse fires when user TAPS a notification.
    await _plugin.initialize(
      settings: initSettings, // <-- FIXED: Added named parameter `settings`
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    debugPrint('🔔 NotificationService: Initialized');
  }

  /// Called when the user taps a notification.
  /// We could navigate to a specific screen here, but for now
  /// the app just opens normally (which is fine).
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 NotificationService: Tapped → ${response.payload}');
    // Future enhancement: parse payload and navigate to arrival/history
  }

  // ══════════════════════════════════════════════════════════
  // PERMISSION
  // ══════════════════════════════════════════════════════════

  /// Requests notification permission.
  /// On Android 12 and below, this is automatically granted.
  /// On Android 13+ (API 33), the user must explicitly allow it.
  /// Returns true if permission was granted.
  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      debugPrint('🔔 NotificationService: Permission GRANTED');
      return true;
    } else {
      debugPrint('🔔 NotificationService: Permission DENIED');
      return false;
    }
  }

  /// Checks if notification permission is currently granted.
  static Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // ══════════════════════════════════════════════════════════
  // SESSION END NOTIFICATION
  // ══════════════════════════════════════════════════════════

  /// Schedules a notification for when the focus session ends.
  ///
  /// [endTime] — exact DateTime when the timer will hit 00:00.
  /// [routeName] — displayed in the notification body.
  /// [emoji] — route emoji for visual flair (optional).
  ///
  /// Also stores the endTime in SharedPreferences so we can
  /// recalculate remaining time when the app resumes from background.
  static Future<void> scheduleSessionEnd({
    required DateTime endTime,
    required String routeName,
    String emoji = '🚂',
  }) async {
    // Check if notifications are enabled in user preferences.
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(NotifPrefs.enabled) ?? true;
    if (!enabled) {
      debugPrint('🔔 NotificationService: Notifications disabled, skipping');
      return;
    }

    // Store the session end time and route for background recovery.
    await prefs.setInt(
      NotifPrefs.sessionEndEpoch,
      endTime.millisecondsSinceEpoch,
    );
    await prefs.setString(NotifPrefs.sessionRoute, routeName);

    // Convert DateTime to TZDateTime (required by the plugin).
    final tzEndTime = tz.TZDateTime.from(endTime, tz.local);

    // Don't schedule if the end time is in the past.
    if (tzEndTime.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('🔔 NotificationService: End time is in the past, skipping');
      return;
    }

    // Android notification channel — luxe branding.
    const androidDetails = AndroidNotificationDetails(
      'session_complete', // Channel ID
      'Journey Arrivals', // Channel name (visible in settings)
      channelDescription: 'Notifies when your focus journey is complete',
      importance: Importance.high,
      priority: Priority.high,
      // Sound — uses default system notification sound.
      // You could add a custom sound file later.
      playSound: true,
      enableVibration: true,
      // Show as heads-up notification (banner at top of screen).
      category: AndroidNotificationCategory.alarm,
      // Full-screen intent makes it more visible.
      fullScreenIntent: true,
      // Auto-dismiss after user sees it.
      autoCancel: true,
      // Custom LED color (gold/brass theme).
      ledColor: Color(0xFFD4A853), // <-- FIXED: Changed to const Color
      ledOnMs: 1000,
      ledOffMs: 500,
      enableLights: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule the notification at the exact end time.
    await _plugin.zonedSchedule(
      id: _Ids.sessionComplete, // <-- FIXED: Named parameters from here down
      title: '$emoji  You\'ve Arrived!',
      body: 'Your journey on $routeName is complete. Well done, traveller.',
      scheduledDate: tzEndTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // This payload could be parsed in _onNotificationTapped
      // to navigate directly to the arrival screen.
      payload: 'session_complete:$routeName',
    );

    debugPrint('🔔 NotificationService: Session end scheduled for $endTime');
  }

  /// Cancels the session-end notification.
  /// Called when:
  ///   • User hits Emergency Stop (session ends early)
  ///   • Timer completes naturally (arrival screen shows instead)
  ///   • User closes the app during a session
  static Future<void> cancelSessionEnd() async {
    await _plugin.cancel(
      id: _Ids.sessionComplete,
    ); // <-- FIXED: Added named parameter `id`

    // Clear stored session data.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(NotifPrefs.sessionEndEpoch);
    await prefs.remove(NotifPrefs.sessionRoute);

    debugPrint('🔔 NotificationService: Session end notification cancelled');
  }

  // ══════════════════════════════════════════════════════════
  // DAILY REMINDER
  // ══════════════════════════════════════════════════════════

  /// Schedules a daily reminder at the user's chosen time.
  /// If a daily reminder is already scheduled, it's replaced.
  ///
  /// [hour] — 0-23 (e.g., 9 = 9 AM, 20 = 8 PM)
  /// [minute] — 0-59
  static Future<void> scheduleDailyReminder({
    int hour = 9,
    int minute = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(NotifPrefs.dailyEnabled) ?? false;
    if (!enabled) {
      await cancelDailyReminder();
      return;
    }

    // Save the reminder time.
    await prefs.setInt(NotifPrefs.dailyHour, hour);
    await prefs.setInt(NotifPrefs.dailyMinute, minute);

    // Calculate the next occurrence of this time.
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow.
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Journey Reminder',
      channelDescription: 'Reminds you to start your daily focus journey',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule repeating daily notification.
    await _plugin.zonedSchedule(
      id: _Ids.dailyReminder, // <-- FIXED: Named parameters
      title: '🚂  Your Journey Awaits',
      body:
          'The platform is ready. Begin today\'s focus journey and keep your streak alive.',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );

    debugPrint('🔔 NotificationService: Daily reminder set for $hour:$minute');
  }

  /// Cancels the daily reminder.
  static Future<void> cancelDailyReminder() async {
    await _plugin.cancel(
      id: _Ids.dailyReminder,
    ); // <-- FIXED: Added named parameter `id`
    debugPrint('🔔 NotificationService: Daily reminder cancelled');
  }

  // ══════════════════════════════════════════════════════════
  // STREAK AT RISK
  // ══════════════════════════════════════════════════════════

  /// Schedules a "streak at risk" notification for 8 PM
  /// if the user hasn't completed a session today.
  ///
  /// Called from HomeScreen when loading stats — if streak > 0
  /// and no session today, schedule the warning.
  static Future<void> scheduleStreakWarning() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(NotifPrefs.enabled) ?? true;
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var warningTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20, // 8 PM
      0,
    );

    // If it's already past 8 PM, don't schedule.
    if (warningTime.isBefore(now)) return;

    const androidDetails = AndroidNotificationDetails(
      'streak_warning',
      'Streak Alerts',
      channelDescription: 'Warns when your focus streak is at risk',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      autoCancel: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id: _Ids.streakAtRisk, // <-- FIXED: Named parameters
      title: '🔥  Streak at Risk!',
      body:
          'You haven\'t boarded a journey today. Complete one before midnight to keep your streak alive!',
      scheduledDate: warningTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'streak_warning',
    );

    debugPrint('🔔 NotificationService: Streak warning set for 8 PM');
  }

  /// Cancels the streak warning (called when user completes a session).
  static Future<void> cancelStreakWarning() async {
    await _plugin.cancel(
      id: _Ids.streakAtRisk,
    ); // <-- FIXED: Added named parameter `id`
  }

  // ══════════════════════════════════════════════════════════
  // INSTANT NOTIFICATION (for testing)
  // ══════════════════════════════════════════════════════════

  /// Shows a notification immediately. Useful for testing.
  static Future<void> showNow({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: 99, // <-- FIXED: Named parameters
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // ══════════════════════════════════════════════════════════
  // UTILITIES
  // ══════════════════════════════════════════════════════════

  /// Cancels ALL pending notifications.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('🔔 NotificationService: All notifications cancelled');
  }

  /// Returns a list of pending notification requests (for debugging).
  static Future<List<PendingNotificationRequest>> getPending() async {
    return await _plugin.pendingNotificationRequests();
  }

  // ══════════════════════════════════════════════════════════
  // ONGOING TIMER NOTIFICATION (Android Live Focus Ticker)
  // ══════════════════════════════════════════════════════════

  /// Shows a persistent notification on Android that displays
  /// a Golden Ticket–themed live countdown during a focus session.
  ///
  /// Call this at session start, then call it again every minute
  /// to update the remaining time display.
  ///
  /// [remainingMinutes] — whole minutes remaining (e.g. 24)
  /// [remainingSeconds] — seconds portion (e.g. 37)
  /// [routeName] — e.g. "Tokyo to Kyoto"
  /// [routeEmoji] — e.g. "🚄"
  /// [totalMinutes] — total session duration for the progress bar
  static Future<void> showOngoingTimer({
    required int remainingMinutes,
    required int remainingSeconds,
    required String routeName,
    String routeEmoji = '🚂',
    int totalMinutes = 25,
  }) async {
    final elapsed = (totalMinutes * 60) -
        (remainingMinutes * 60 + remainingSeconds);
    final total = totalMinutes * 60;
    final progress = (elapsed / total).clamp(0.0, 1.0);
    final maxProgress = 100;
    final currentProgress = (progress * maxProgress).round();

    final timeStr =
        '${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';

    final androidDetails = AndroidNotificationDetails(
      'focus_timer',
      'Focus Timer',
      channelDescription: 'Live countdown during a focus session',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: maxProgress,
      progress: currentProgress,
      // Themed ticker text mimicking a departure board
      ticker: '$routeEmoji $routeName ·  $timeStr remaining',
      styleInformation: BigTextStyleInformation(
        '$routeEmoji  $routeName\n🕐  $timeStr remaining',
        summaryText: 'RailFocus — Focus Session Active',
      ),
      ledColor: const Color(0xFFD4A853),
      ledOnMs: 1000,
      ledOffMs: 500,
      enableLights: true,
      playSound: false,
      enableVibration: false,
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: _Ids.ongoingTimer,
      title: '🎫  FIRST CLASS — Active Journey',
      body: '$routeEmoji  $routeName  ·  $timeStr',
      notificationDetails: details,
      payload: 'ongoing_timer',
    );
  }

  /// Dismisses the ongoing focus timer notification.
  /// Call when the session ends or the user stops early.
  static Future<void> cancelOngoingTimer() async {
    await _plugin.cancel(id: _Ids.ongoingTimer);
    debugPrint('🔔 NotificationService: Ongoing timer notification cancelled');
  }
}
