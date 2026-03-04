// lib/services/ai_coach_service.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — AI FOCUS COACH
//  Powered by Google Gemini. Analyzes focus patterns and
//  provides personalized coaching insights.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/api_keys.dart';
import 'storage_service.dart';

class AiCoachService {
  AiCoachService._();
  static final instance = AiCoachService._();

  final _storage = StorageService();

  GenerativeModel? _model;
  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: ApiKeys.geminiApiKey,
      generationConfig: GenerationConfig(
        maxOutputTokens: 300,
        temperature: 0.8,
      ),
    );
    return _model!;
  }

  // ══════════════════════════════════════
  // BUILD CONTEXT (user data summary)
  // ══════════════════════════════════════

  String _buildUserContext() {
    final streak = _storage.getStreak();
    final totalHours = _storage.getTotalHours();
    final totalSessions = _storage.getTotalSessions();
    final bricks = _storage.getBricks();
    final stationLevel = _storage.getStationLevel();
    final todayMinutes = _storage.getTodayMinutes();
    final todaySessions = _storage.getTodaySessionCount();

    final sessions = _storage.getAllSessions().take(20).toList();

    // Compute per-hour distribution
    final hourBuckets = List.filled(24, 0);
    final dayBuckets = List.filled(7, 0); // Mon=0 .. Sun=6
    final routeMinutes = <String, int>{};

    for (final s in sessions) {
      if (!s.completed) continue;
      hourBuckets[s.startTime.hour] += s.durationMinutes;
      dayBuckets[(s.startTime.weekday - 1) % 7] += s.durationMinutes;
      routeMinutes[s.routeName] =
          (routeMinutes[s.routeName] ?? 0) + s.durationMinutes;
    }

    // Find peak hour
    int peakHour = 0;
    for (int i = 1; i < 24; i++) {
      if (hourBuckets[i] > hourBuckets[peakHour]) peakHour = i;
    }

    // Find peak day
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    int peakDay = 0;
    for (int i = 1; i < 7; i++) {
      if (dayBuckets[i] > dayBuckets[peakDay]) peakDay = i;
    }

    // Favorite route
    String favRoute = 'none';
    int favMins = 0;
    routeMinutes.forEach((route, mins) {
      if (mins > favMins) {
        favRoute = route;
        favMins = mins;
      }
    });

    // Average session length
    final completedSessions = sessions.where((s) => s.completed).toList();
    final avgMinutes = completedSessions.isEmpty
        ? 0
        : completedSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes) ~/
            completedSessions.length;

    // Recent moods
    final recentMoods = completedSessions
        .take(5)
        .where((s) => s.mood != null && s.mood!.isNotEmpty)
        .map((s) => s.mood!)
        .toList();

    return '''
USER FOCUS DATA:
- Current streak: $streak days
- Total focus hours: ${totalHours.toStringAsFixed(1)}h
- Total sessions: $totalSessions
- Today: ${todayMinutes}min across $todaySessions sessions
- Bricks earned: $bricks
- Station level: $stationLevel/10
- Average session: ${avgMinutes}min
- Peak focus hour: ${peakHour}:00
- Peak focus day: ${dayNames[peakDay]}
- Favorite route: $favRoute ($favMins min total)
- Recent moods: ${recentMoods.isEmpty ? 'none set' : recentMoods.join(', ')}
''';
  }

  // ══════════════════════════════════════
  // AI COACH — HOME SCREEN TIP
  // ══════════════════════════════════════

  /// Generate a personalized coaching tip for the home screen.
  Future<String> getDailyCoachTip() async {
    try {
      final context = _buildUserContext();
      final now = DateTime.now();
      final hour = now.hour;
      final timeOfDay = hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : 'evening';

      final prompt = '''
You are a warm, motivating focus coach inside a train-themed productivity app called RailFocus.
The user sees this on their home screen. Give ONE short, personalized coaching tip (2-3 sentences max).

Rules:
- Use the data to make it personal (reference their streak, patterns, peak hours, etc.)
- Be encouraging but specific, not generic
- Use a train/journey metaphor occasionally
- Use 1-2 emojis max
- Current time: $timeOfDay
- Keep it under 40 words

$context
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? _fallbackTip();
    } catch (e) {
      debugPrint('🔴 AI Coach error: $e');
      return _fallbackTip();
    }
  }

  // ══════════════════════════════════════
  // AI INSIGHT — POST SESSION
  // ══════════════════════════════════════

  /// Generate a personalized message after completing a focus session.
  Future<String> getPostSessionInsight({
    required int durationMinutes,
    required String routeName,
    String? mood,
    String? goal,
  }) async {
    try {
      final context = _buildUserContext();
      final now = DateTime.now();
      final hour = now.hour;

      final prompt = '''
You are a warm conductor congratulating a passenger who just completed a focus journey in RailFocus.

Session just completed:
- Duration: ${durationMinutes} minutes
- Route: $routeName
- Time: ${hour}:${now.minute.toString().padLeft(2, '0')}
- Mood: ${mood ?? 'not set'}
- Goal: ${goal ?? 'not set'}

$context

Write a personalized, warm congratulations (2-3 sentences max). Reference their specific achievement.
Use train/journey metaphors. Use 1-2 emojis. Keep under 40 words.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? _fallbackPostSession(durationMinutes);
    } catch (e) {
      debugPrint('🔴 AI post-session error: $e');
      return _fallbackPostSession(durationMinutes);
    }
  }

  // ══════════════════════════════════════
  // AI INSIGHTS — ANALYTICS
  // ══════════════════════════════════════

  /// Generate analytics insights for the Insights Dashboard.
  Future<List<String>> getAnalyticsInsights() async {
    try {
      final context = _buildUserContext();

      final prompt = '''
You are an analytics AI for a focus/productivity app called RailFocus.
Analyze the user's data and provide exactly 4 one-line insights.

Rules:
- Each insight should be on its own line
- Start each with a relevant emoji
- Be specific using their data (numbers, patterns, comparisons)
- Include: 1 strength, 1 pattern, 1 suggestion, 1 motivation
- Keep each under 20 words
- No bullet points, just emoji + text

$context
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      final lines = text
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .take(4)
          .toList();

      if (lines.isEmpty) return _fallbackInsights();
      return lines;
    } catch (e) {
      debugPrint('🔴 AI analytics error: $e');
      return _fallbackInsights();
    }
  }

  // ══════════════════════════════════════
  // AI WEEKLY REPORT
  // ══════════════════════════════════════

  /// Generate a motivational weekly summary.
  Future<String> getWeeklyReport() async {
    try {
      final context = _buildUserContext();

      final prompt = '''
You are a focus coach writing a short weekly report card for a user of RailFocus (a train-themed focus app).

$context

Write a 4-5 sentence weekly summary. Include:
1. What they did well (with specific numbers)
2. A pattern you noticed
3. One concrete suggestion for next week
4. An encouraging closing line with a train metaphor

Use 2-3 emojis total. Keep the whole thing under 80 words.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'Keep focusing — your journey continues! 🚂';
    } catch (e) {
      debugPrint('🔴 AI weekly report error: $e');
      return 'Keep focusing — your journey continues! 🚂';
    }
  }

  // ══════════════════════════════════════
  // FALLBACKS (offline / error)
  // ══════════════════════════════════════

  String _fallbackTip() {
    final streak = _storage.getStreak();
    if (streak > 0) {
      return '🔥 $streak-day streak! Keep the momentum going — one session at a time.';
    }
    return '🚂 Ready to begin your focus journey? Every great trip starts with a single step.';
  }

  String _fallbackPostSession(int minutes) {
    return '🎉 $minutes minutes of deep focus — well done! Your station is growing.';
  }

  List<String> _fallbackInsights() {
    final streak = _storage.getStreak();
    final hours = _storage.getTotalHours();
    return [
      '🔥 Current streak: $streak days',
      '⏰ Total focus: ${hours.toStringAsFixed(1)} hours',
      '💡 Try focusing at the same time each day for better habits',
      '🚂 Every session brings you closer to Grand Terminus!',
    ];
  }
}
