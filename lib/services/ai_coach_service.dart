// lib/services/ai_coach_service.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — AI FOCUS COACH
//  Powered by Google Gemini. Analyzes focus patterns and
//  provides personalized coaching insights.
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_keys.dart';
import 'storage_service.dart';

class AiCoachService {
  AiCoachService._();
  static final instance = AiCoachService._();

  final _storage = StorageService();

  GenerativeModel? _model;
  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: ApiKeys.geminiApiKey,
      generationConfig: GenerationConfig(
        maxOutputTokens: 300,
        temperature: 0.8,
      ),
    );
    return _model!;
  }

  // ── Mutex & Rate Limiting ────────────────────────────
  bool _isRequestInProgress = false;
  DateTime? _lastApiCall;
  static const Duration _rateLimit = Duration(seconds: 3);

  /// Checks if we've waited long enough since the last AI call
  bool _canCallApi() {
    if (_lastApiCall == null) return true;
    return DateTime.now().difference(_lastApiCall!) > _rateLimit;
  }

  /// Global centralized wrapper for all Gemini requests.
  /// Prevents parallel execution, enforces rate limits, handles errors gracefully.
  Future<String?> _safeGenerate(String prompt) async {
    if (!_canCallApi() || _isRequestInProgress) {
      debugPrint('⚠️ AI call blocked: rate limit or mutex active.');
      return null;
    }

    _isRequestInProgress = true;

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      _lastApiCall = DateTime.now();
      return response.text;
    } catch (e) {
      debugPrint("🔴 AI API error: $e");
      return null;
    } finally {
      _isRequestInProgress = false;
    }
  }

  // ── Cache Settings ───────────────────────────────────

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
USER STATS:
Streak: $streak
Total Hours: ${totalHours.toStringAsFixed(1)}
Sessions: $totalSessions
Today: ${todayMinutes}m ($todaySessions sessions)
Bricks: $bricks
Station: $stationLevel/10
Avg Session: ${avgMinutes}m
Peak Hour: ${peakHour}:00
Peak Day: ${dayNames[peakDay]}
Fav Route: $favRoute ($favMins m)
Recent Moods: ${recentMoods.isEmpty ? 'none' : recentMoods.join(', ')}
''';
  }

  // ══════════════════════════════════════
  // AI COACH — HOME SCREEN TIP
  // ══════════════════════════════════════

  /// Generate a personalized coaching tip for the home screen.
  Future<String> getDailyCoachTip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTimeStr = prefs.getString('ai_daily_tip_time');
      if (lastTimeStr != null) {
        final lastTime = DateTime.parse(lastTimeStr);
        if (DateTime.now().difference(lastTime).inHours < 6) {
          final cached = prefs.getString('ai_daily_tip');
          if (cached != null) return cached;
        }
      }

      final context = _buildUserContext();
      final now = DateTime.now();
      final hour = now.hour;
      final timeOfDay = hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : 'evening';

      final prompt = '''
You are a warm focus coach in RailFocus, a train app.
Give ONE short coaching tip (max 2 sentences) for the home screen based on the user stats below.
Rules:
- Make it personal using their stats
- Occasionally use train metaphors
- Max 1 emoji
- Current time: $timeOfDay
- Max 30 words

$context
''';

      final text = await _safeGenerate(prompt);
      if (text == null) return _fallbackTip();
      
      final result = text.trim();
      await prefs.setString('ai_daily_tip', result);
      await prefs.setString('ai_daily_tip_time', DateTime.now().toIso8601String());
      
      return result;
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

      final prompt = '''
You are a conductor in RailFocus congratulating a user.
Session done:
Duration: ${durationMinutes}m
Route: $routeName
Mood: ${mood ?? '-'}
Goal: ${goal ?? '-'}

$context

Write a 2-sentence warm congratulations. Reference their achievement.
Use a train metaphor. Max 1 emoji. Max 35 words.
''';

      final text = await _safeGenerate(prompt);
      if (text == null) return _fallbackPostSession(durationMinutes);
      return text.trim();
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
      final prefs = await SharedPreferences.getInstance();
      final lastTimeStr = prefs.getString('ai_analytics_time');
      if (lastTimeStr != null) {
        final lastTime = DateTime.parse(lastTimeStr);
        if (DateTime.now().difference(lastTime).inHours < 1) {
          final cached = prefs.getStringList('ai_analytics');
          if (cached != null && cached.isNotEmpty) return cached;
        }
      }

      final context = _buildUserContext();

      final prompt = '''
You are an analytics AI for RailFocus. Analyze this user data and return EXACTLY 4 one-line insights.
Rules:
- 1 insight per line
- Start each with an emoji
- Use exact data to be specific
- Types: 1 strength, 1 pattern, 1 tip, 1 motivation
- Max 15 words per line
- No markdown bullets

$context
''';

      final rawText = await _safeGenerate(prompt);
      if (rawText == null) return _fallbackInsights();

      final text = rawText.trim();
      final lines = text
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .take(4)
          .toList();

      if (lines.isEmpty) return _fallbackInsights();

      // Cache the result
      await prefs.setStringList('ai_analytics', lines);
      await prefs.setString('ai_analytics_time', DateTime.now().toIso8601String());

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
      final prefs = await SharedPreferences.getInstance();
      final lastTimeStr = prefs.getString('ai_weekly_report_time');
      if (lastTimeStr != null) {
        final lastTime = DateTime.parse(lastTimeStr);
        if (DateTime.now().difference(lastTime).inHours < 24) {
          final cached = prefs.getString('ai_weekly_report');
          if (cached != null) return cached;
        }
      }

      final context = _buildUserContext();

      final prompt = '''
You are a focus coach in RailFocus writing a weekly report based on stats below.

$context

Write a 4-sentence summary:
1. What went well (use numbers)
2. A pattern you noticed
3. 1 suggestion for next week
4. Encouraging train metaphor closing line

Max 2 emojis. Max 70 words total.
''';

      final resultText = await _safeGenerate(prompt);
      if (resultText == null) return 'Keep focusing — your journey continues! 🚂';
      
      final result = resultText.trim();

      // Cache the result
      await prefs.setString('ai_weekly_report', result);
      await prefs.setString('ai_weekly_report_time', DateTime.now().toIso8601String());

      return result;
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

  // ══════════════════════════════════════
  // SMART SESSION SUGGESTION
  // ══════════════════════════════════════

  /// Analyses peak-hour data and returns a session suggestion if the
  /// current hour is within ±1 hour of the user's peak focus time.
  /// Returns null if no suggestion is warranted right now.
  Future<Map<String, dynamic>?> getSmartSuggestion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTimeStr = prefs.getString('ai_smart_suggestion_time');
      final now = DateTime.now();
      
      if (lastTimeStr != null) {
        final lastTime = DateTime.parse(lastTimeStr);
        if (now.difference(lastTime).inHours < 4) {
          final cachedStr = prefs.getString('ai_smart_suggestion');
          if (cachedStr != null) {
             return jsonDecode(cachedStr) as Map<String, dynamic>;
          }
        }
      }

      final context = _buildUserContext();
      final prompt = '''
$context
Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}

Task: Is NOW a good time to focus based on their peak hour?
If yes, return exact JSON: {"title":"short title", "reason":"short reason", "durationMinutes": 25}
- durationMinutes must be 15, 25, 45, or 60
If not a good time, return ONLY: null
''';

      final rawText = await _safeGenerate(prompt);
      if (rawText == null || rawText == 'null' || rawText.isEmpty) return null;
      final clean = rawText.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
      // Simple parse
      final map = <String, dynamic>{};
      final titleMatch = RegExp(r'"title"\s*:\s*"([^"]+)"').firstMatch(clean);
      final reasonMatch = RegExp(r'"reason"\s*:\s*"([^"]+)"').firstMatch(clean);
      final durMatch = RegExp(r'"durationMinutes"\s*:\s*(\d+)').firstMatch(clean);
      if (titleMatch == null) return null;
      map['title'] = titleMatch.group(1)!;
      map['reason'] = reasonMatch?.group(1) ?? 'Your peak focus window is open';
      map['durationMinutes'] = int.tryParse(durMatch?.group(1) ?? '25') ?? 25;
      
      await prefs.setString('ai_smart_suggestion', jsonEncode(map));
      await prefs.setString('ai_smart_suggestion_time', now.toIso8601String());
      
      return map;
    } catch (e) {
      debugPrint('🔴 AI smart suggestion error: $e');
      return null;
    }
  }

  // ══════════════════════════════════════
  // ADAPTIVE SESSION LENGTH
  // ══════════════════════════════════════

  /// Looks at the last 10 completed sessions and suggests an optimal
  /// session length. Returns {minutes, reason} or null on error.
  Future<Map<String, dynamic>?> getAdaptiveSessionLength() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTimeStr = prefs.getString('ai_adaptive_length_time');
      final now = DateTime.now();
      
      if (lastTimeStr != null) {
        final lastTime = DateTime.parse(lastTimeStr);
        if (now.difference(lastTime).inHours < 12) {
          final cachedStr = prefs.getString('ai_adaptive_length');
          if (cachedStr != null) {
             return jsonDecode(cachedStr) as Map<String, dynamic>;
          }
        }
      }

      final sessions = _storage.getAllSessions().take(10).toList();
      if (sessions.isEmpty) return null;

      final lines = sessions.map((s) =>
        '${s.durationMinutes}min | completed:${s.completed}'
      ).join('\n');

      final prompt = '''
Recent sessions:
$lines

Task: Based on their completion rate, what duration (15, 25, 30, 45, 60m) should they try next?
Return JSON only:
{"minutes": 25, "reason": "short explanation"}
''';

      final rawText = await _safeGenerate(prompt);
      if (rawText == null || rawText.isEmpty) return null;
      final clean = rawText.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
      final minsMatch = RegExp(r'"minutes"\s*:\s*(\d+)').firstMatch(clean);
      final reasonMatch = RegExp(r'"reason"\s*:\s*"([^"]+)"').firstMatch(clean);
      if (minsMatch == null) return null;
      
      final map = {
        'minutes': int.tryParse(minsMatch.group(1)!) ?? 25,
        'reason': reasonMatch?.group(1) ?? 'Based on your recent sessions',
      };
      
      await prefs.setString('ai_adaptive_length', jsonEncode(map));
      await prefs.setString('ai_adaptive_length_time', now.toIso8601String());
      
      return map;
    } catch (e) {
      debugPrint('🔴 AI adaptive length error: $e');
      return null;
    }
  }

  // ══════════════════════════════════════
  // AI ROUTE GENERATOR
  // ══════════════════════════════════════

  /// Generates a fictional luxury train route based on the user's mood.
  /// Returns {name, emoji, tagline} or null on error.
  Future<Map<String, dynamic>?> generateRoute(String mood) async {
    try {
      final prompt = '''
Create a fictional luxury train route inspired by mood: "$mood".
Return JSON ONLY:
{"name": "City A to City B", "emoji": "🚄", "tagline": "short poetic description"}
''';
      final rawText = await _safeGenerate(prompt);
      if (rawText == null || rawText.isEmpty) return null;
      final clean = rawText.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
      final nameMatch = RegExp(r'"name"\s*:\s*"([^"]+)"').firstMatch(clean);
      final emojiMatch = RegExp(r'"emoji"\s*:\s*"([^"]+)"').firstMatch(clean);
      final tagMatch = RegExp(r'"tagline"\s*:\s*"([^"]+)"').firstMatch(clean);
      if (nameMatch == null) return null;
      return {
        'name': nameMatch.group(1)!,
        'emoji': emojiMatch?.group(1) ?? '✨',
        'tagline': tagMatch?.group(1) ?? 'A journey beyond imagination',
      };
    } catch (e) {
      debugPrint('🔴 AI route generator error: $e');
      return null;
    }
  }

  // ══════════════════════════════════════
  // VOICE REFLECTION SUMMARISER
  // ══════════════════════════════════════

  /// Takes a raw voice transcript and returns a single polished
  /// reflection sentence to save alongside the session.
  Future<String> getVoiceReflection(String transcript, String routeName) async {
    try {
      final prompt = '''
Route: "$routeName"
Spoken reflection: "$transcript"

Write ONE 15-word max sentence in first-person summarizing this, starting with "Today I...".
Return ONLY the sentence, no quotes.
''';
      final text = await _safeGenerate(prompt);
      if (text == null) return transcript;
      return text.trim();
    } catch (e) {
      debugPrint('🔴 AI voice reflection error: $e');
      return transcript;
    }
  }
}

