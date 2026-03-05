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

  // ── Cache ──────────────────────────────────────────
  String? _cachedTip;
  DateTime? _lastTipTime;

  Map<String, dynamic>? _cachedSmartSuggestion;
  DateTime? _lastSmartSuggestionTime;

  Map<String, dynamic>? _cachedAdaptiveLength;
  DateTime? _lastAdaptiveLengthTime;

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

  // ══════════════════════════════════════
  // SMART SESSION SUGGESTION
  // ══════════════════════════════════════

  /// Analyses peak-hour data and returns a session suggestion if the
  /// current hour is within ±1 hour of the user's peak focus time.
  /// Returns null if no suggestion is warranted right now.
  Future<Map<String, dynamic>?> getSmartSuggestion() async {
    final now = DateTime.now();
    if (_cachedSmartSuggestion != null && _lastSmartSuggestionTime != null && 
        now.difference(_lastSmartSuggestionTime!).inHours < 4) {
      return _cachedSmartSuggestion;
    }

    try {
      final context = _buildUserContext();
      final now = DateTime.now();
      final prompt = '''
$context

Current local time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}

Task: Determine if NOW is a good time for this user to start a focus session based on their peak hour and patterns.
If yes, respond with a JSON object (no markdown):
{"title":"...", "reason":"...", "durationMinutes": 25}
- title: 8 words max, motivational
- reason: 12 words max, personal to their pattern
- durationMinutes: 15, 25, 45, or 60 (based on their history)
If now is NOT a good time, respond with exactly: null
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      if (text == 'null' || text.isEmpty) return null;
      final clean = text.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
      // Simple parse
      final map = <String, dynamic>{};
      final titleMatch = RegExp(r'"title"\s*:\s*"([^"]+)"').firstMatch(clean);
      final reasonMatch = RegExp(r'"reason"\s*:\s*"([^"]+)"').firstMatch(clean);
      final durMatch = RegExp(r'"durationMinutes"\s*:\s*(\d+)').firstMatch(clean);
      if (titleMatch == null) return null;
      map['title'] = titleMatch.group(1)!;
      map['reason'] = reasonMatch?.group(1) ?? 'Your peak focus window is open';
      map['durationMinutes'] = int.tryParse(durMatch?.group(1) ?? '25') ?? 25;
      
      _cachedSmartSuggestion = map;
      _lastSmartSuggestionTime = now;
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
    final now = DateTime.now();
    if (_cachedAdaptiveLength != null && _lastAdaptiveLengthTime != null && 
        now.difference(_lastAdaptiveLengthTime!).inHours < 12) {
      return _cachedAdaptiveLength;
    }

    try {
      final sessions = _storage.getAllSessions().take(10).toList();
      if (sessions.isEmpty) return null;

      final lines = sessions.map((s) =>
        '${s.durationMinutes}min | completed:${s.completed}'
      ).join('\n');

      final prompt = '''
User's recent focus sessions:
$lines

Task: Based on their completion rate and session lengths, what single duration (15, 25, 30, 45, or 60 minutes) should they try next?
Respond with JSON only (no markdown):
{"minutes": 25, "reason": "12 word max explanation"}
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      final clean = text.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
      final minsMatch = RegExp(r'"minutes"\s*:\s*(\d+)').firstMatch(clean);
      final reasonMatch = RegExp(r'"reason"\s*:\s*"([^"]+)"').firstMatch(clean);
      if (minsMatch == null) return null;
      return {
        'minutes': int.tryParse(minsMatch.group(1)!) ?? 25,
        'reason': reasonMatch?.group(1) ?? 'Based on your recent sessions',
      };
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
Create a unique fictional luxury train route inspired by the mood: "$mood".
Respond with JSON only (no markdown, no explanation):
{
  "name": "City A to City B",
  "emoji": "🚄",
  "tagline": "A 12-word poetic description of the journey atmosphere"
}
Rules:
- name must be two fictional or real cities, 4-7 words
- emoji must be a single transport or nature emoji reflecting the theme
- tagline must evoke the atmosphere of this journey  
''';
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      final clean = text.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
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
The user just completed a focus session on "$routeName". Here is their spoken reflection:
"$transcript"

Write ONE single sentence (max 20 words) in first-person that captures the essence of their reflection, starting with "Today I...".
Only return the sentence, no quotes.
''';
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? transcript;
    } catch (e) {
      debugPrint('🔴 AI voice reflection error: $e');
      return transcript;
    }
  }
}

