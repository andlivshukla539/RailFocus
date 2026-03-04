// lib/screens/home_screen.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — HOME SCREEN  (Revamped)
//  Theme: "Orient Express Departure Hall"
//  Art-deco station, brass details, archway diorama, flip-board
//  stats, and a pull-lever CTA that feels tactile and alive.
//
//  Animation philosophy:
//    • One slow ambient breath on the scene window (8 s)
//    • Stars and train only when scene demands (< 80 fps budget)
//    • UI transitions: easeInOutQuart, staggered reveals
//    • No floating particles outside the diorama
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/session_model.dart';
import '../models/route_model.dart';
import '../router/app_router.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../widgets/route_unlock_dialog.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_counter.dart';
import '../widgets/station_widget.dart';
import '../widgets/daily_challenge_card.dart';
import '../models/daily_challenge.dart';
import '../services/cabin_service.dart';
import 'cabin_selection_screen.dart';
import '../widgets/streak_calendar.dart';
import '../widgets/level_up_overlay.dart';
import '../services/ai_coach_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
// PALETTE
// ═══════════════════════════════════════════════════════════════

class _P {
  // Background
  static const ink = Color(0xFF07090F);
  static const panel = Color(0xFF131620);
  static const raised = Color(0xFF1A1E2C);
  // Gold / Brass
  static const brass = Color(0xFFD4A853);
  static const brassLt = Color(0xFFF0CC7A);
  static const brassDk = Color(0xFF8A6930);
  static const cream = Color(0xFFF5EDDB);
  // Text
  static const t2 = Color(0xFF9A8E78);
  // Scene accents by hour
  static const auroraC = Color(0xFF00D9D0);
  static const sunriseC = Color(0xFFFF7A3A);
  static const morningC = Color(0xFF5CA8D8);
  static const afternoonC = Color(0xFF4090C0);
  static const sunsetC = Color(0xFFE85030);
  static const twilightC = Color(0xFF7050C0);
  static const midnightC = Color(0xFF2030A0);
}

// ═══════════════════════════════════════════════════════════════
// SCENE THEME
// ═══════════════════════════════════════════════════════════════

enum SceneTheme {
  aurora,
  sunrise,
  morning,
  afternoon,
  sunset,
  twilight,
  midnight;

  static SceneTheme now() {
    final h = DateTime.now().hour;
    if (h < 5) return aurora;
    if (h < 8) return sunrise;
    if (h < 12) return morning;
    if (h < 17) return afternoon;
    if (h < 20) return sunset;
    if (h < 22) return twilight;
    return midnight;
  }

  String get label {
    switch (this) {
      case SceneTheme.aurora:
        return 'Northern Lights Express';
      case SceneTheme.sunrise:
        return 'Dawn Departure';
      case SceneTheme.morning:
        return 'Morning Express';
      case SceneTheme.afternoon:
        return 'Afternoon Limited';
      case SceneTheme.sunset:
        return 'Golden Hour Route';
      case SceneTheme.twilight:
        return 'Twilight Voyage';
      case SceneTheme.midnight:
        return 'Midnight Express';
    }
  }

  Color get accent {
    switch (this) {
      case SceneTheme.aurora:
        return _P.auroraC;
      case SceneTheme.sunrise:
        return _P.sunriseC;
      case SceneTheme.morning:
        return _P.morningC;
      case SceneTheme.afternoon:
        return _P.afternoonC;
      case SceneTheme.sunset:
        return _P.sunsetC;
      case SceneTheme.twilight:
        return _P.twilightC;
      case SceneTheme.midnight:
        return _P.midnightC;
    }
  }

  List<Color> get sky {
    switch (this) {
      case aurora:
        return const [Color(0xFF060B14), Color(0xFF0B1828), Color(0xFF132040)];
      case sunrise:
        return const [
          Color(0xFF180808),
          Color(0xFF501820),
          Color(0xFFAA3820),
          Color(0xFFE07040),
        ];
      case morning:
        return const [Color(0xFF1A3050), Color(0xFF3A6890), Color(0xFF70A8D0)];
      case afternoon:
        return const [Color(0xFF182840), Color(0xFF2860A0), Color(0xFF4888C8)];
      case sunset:
        return const [
          Color(0xFF180808),
          Color(0xFF601810),
          Color(0xFFD83820),
          Color(0xFFE07040),
        ];
      case twilight:
        return const [
          Color(0xFF080618),
          Color(0xFF201040),
          Color(0xFF482870),
          Color(0xFF603090),
        ];
      case midnight:
        return const [Color(0xFF040408), Color(0xFF080818), Color(0xFF0C1028)];
    }
  }

  bool get stars =>
      this == SceneTheme.aurora || this == midnight || this == twilight;
  bool get isAurora => this == SceneTheme.aurora;
  bool get sun => this == morning || this == afternoon;
  bool get moon => this == midnight || this == twilight;
  bool get clouds => this == morning || this == afternoon || this == sunset;
  bool get fireflies => this == twilight || this == midnight;
  bool get lanterns => this == midnight || this == SceneTheme.aurora;
  bool get shooters =>
      this == midnight || this == SceneTheme.aurora || this == twilight;
}

// ═══════════════════════════════════════════════════════════════
// FOCUS MOOD — Reactive scenery based on user's focus patterns
// ═══════════════════════════════════════════════════════════════

enum FocusMood {
  onFire,      // streak >= 3 AND focused today
  productive,  // focused today (1+ sessions)
  warmingUp,   // has sessions but none today
  idle;        // no sessions at all

  String get label {
    switch (this) {
      case FocusMood.onFire:
        return '🔥 On Fire — Keep the streak alive!';
      case FocusMood.productive:
        return '✨ Productive day — Great work!';
      case FocusMood.warmingUp:
        return '🌤️ Warming up — Start a session?';
      case FocusMood.idle:
        return '🌧️ Idle — Your train awaits...';
    }
  }

  Color get glowColor {
    switch (this) {
      case FocusMood.onFire:
        return const Color(0xFFFFD700); // golden
      case FocusMood.productive:
        return const Color(0xFF4CAF50); // green
      case FocusMood.warmingUp:
        return const Color(0xFFFF9800); // amber
      case FocusMood.idle:
        return const Color(0xFF5A6A7A); // grey-blue
    }
  }

  double get glowIntensity {
    switch (this) {
      case FocusMood.onFire: return 0.25;
      case FocusMood.productive: return 0.15;
      case FocusMood.warmingUp: return 0.08;
      case FocusMood.idle: return 0.04;
    }
  }

  bool get showRain => this == FocusMood.idle;
  bool get showGoldenGlow => this == FocusMood.onFire;
  bool get showSparkles => this == FocusMood.productive || this == FocusMood.onFire;
}

// ═══════════════════════════════════════════════════════════════
// HOME SCREEN
// ═══════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _storage = StorageService();

  int _streak = 0;
  double _totalHours = 0;
  List<JourneySession> _sessions = [];

  // Animation controllers — lean set
  late AnimationController _breath; // 8 s scene breath
  late AnimationController _train; // 12 s train crossing
  late AnimationController _stars; // 30 s star twinkle (slow)
  late AnimationController _aurora; // 6 s aurora wave
  late AnimationController _counter; // 1.2 s stat reveal
  late AnimationController _pulse; // 2 s logo pulse

  late SceneTheme _scene;
  int _todayMinutes = 0;
  int _bricks = 0;
  int _stationLevel = 0;
  int _bricksForNext = 5;
  DailyChallenge _dailyChallenge = DailyChallenge.generateForToday();
  bool _challengeCompleted = false;
  double _challengeProgress = 0.0;
  Map<String, int> _focusData = {};
  bool _showLevelUp = false;
  int _prevStationLevel = -1;
  String _aiTip = '';
  String _passengerName = '';

  FocusMood get _focusMood {
    final today = DateTime.now();
    final hasSessionToday = _sessions.any(
      (s) => s.startTime.year == today.year &&
             s.startTime.month == today.month &&
             s.startTime.day == today.day,
    );
    if (hasSessionToday && _streak >= 3) return FocusMood.onFire;
    if (hasSessionToday) return FocusMood.productive;
    if (_totalHours > 0) return FocusMood.warmingUp;
    return FocusMood.idle;
  }

  double _calcChallengeProgress() {
    if (_challengeCompleted) return 1.0;
    final c = _dailyChallenge;
    switch (c.type) {
      case ChallengeType.focusDuration:
      case ChallengeType.marathon:
        final mins = _storage.getTodayMinutes();
        final p = mins / c.targetValue;
        if (p >= 1.0) _autoCompleteChallenge();
        return p.clamp(0.0, 1.0);
      case ChallengeType.sessionCount:
        final count = _storage.getTodaySessionCount();
        final p = count / c.targetValue;
        if (p >= 1.0) _autoCompleteChallenge();
        return p.clamp(0.0, 1.0);
      case ChallengeType.specificRoute:
        final route = RouteModel.fromId(c.routeId ?? '');
        final done = route != null && _storage.hasRouteToday(route.name);
        if (done) _autoCompleteChallenge();
        return done ? 1.0 : 0.0;
      case ChallengeType.earlyBird:
        final done = _storage.hasSessionBeforeHour(c.targetValue);
        if (done) _autoCompleteChallenge();
        return done ? 1.0 : 0.0;
      case ChallengeType.nightOwl:
        final done = _storage.hasSessionAfterHour(c.targetValue);
        if (done) _autoCompleteChallenge();
        return done ? 1.0 : 0.0;
      case ChallengeType.streakKeep:
        final done = _streak >= c.targetValue;
        if (done) _autoCompleteChallenge();
        return done ? 1.0 : 0.0;
    }
  }

  void _autoCompleteChallenge() {
    if (_challengeCompleted) return;
    _storage.completeDailyChallenge(_dailyChallenge.id, _dailyChallenge.brickReward);
    _challengeCompleted = true;
    // Refresh brick count
    _bricks = _storage.getBricks();
    _stationLevel = _storage.getStationLevel();
    _bricksForNext = _storage.bricksForNextLevel();
  }

  String get _greeting {
    final user = AuthService.instance.currentUser;
    if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
      final firstName = user.displayName!.split(' ').first;
      return 'Hi, $firstName 👋';
    }
    if (_passengerName.isNotEmpty) return 'Hi, $_passengerName 👋';
    return 'Welcome, Traveller';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scene = SceneTheme.now();

    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _train = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _stars = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _aurora = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _counter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breath.dispose();
    _train.dispose();
    _stars.dispose();
    _aurora.dispose();
    _counter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  void _load() {
    if (!mounted) return;
    try {
      setState(() {
        _streak = _storage.getStreak();
        _totalHours = _storage.getTotalHours();
        _sessions = _storage.getAllSessions().take(5).toList();
        _scene = SceneTheme.now();
        _bricks = _storage.getBricks();
        _stationLevel = _storage.getStationLevel();
        _bricksForNext = _storage.bricksForNextLevel();
        _dailyChallenge = DailyChallenge.generateForToday();
        _challengeCompleted = _storage.isChallengeCompleted(_dailyChallenge.id);
        _challengeProgress = _calcChallengeProgress();
        _focusData = _storage.getFocusDataLast35Days();

        // Detect level-up
        final newLevel = _stationLevel;
        if (_prevStationLevel >= 0 && newLevel > _prevStationLevel) {
          _showLevelUp = true;
        }
        _prevStationLevel = newLevel;
      });
      _counter.forward(from: 0);

      // Load AI coach tip (async, non-blocking)
      AiCoachService.instance.getDailyCoachTip().then((tip) {
        if (mounted) setState(() => _aiTip = tip);
      });

      // Load passenger name set during onboarding (async, non-blocking)
      SharedPreferences.getInstance().then((prefs) {
        final name = prefs.getString('passenger_name') ?? '';
        if (mounted && name.isNotEmpty) setState(() => _passengerName = name);
      });

      // Phase 8: Schedule streak warning if needed
      if (_streak > 0) {
        // Check if user has a session TODAY
        final today = DateTime.now();
        final hasSessionToday = _sessions.any(
          (s) =>
              s.startTime.year == today.year &&
              s.startTime.month == today.month &&
              s.startTime.day == today.day,
        );

        if (!hasSessionToday) {
          // User has a streak but no session today — warn at 8 PM
          NotificationService.scheduleStreakWarning();
        } else {
          // User already completed a session today — cancel any warning
          NotificationService.cancelStreakWarning();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Home data load error: $e');
    }

    // Check for newly unlocked routes
    _checkRouteUnlocks();
  }

  void _checkRouteUnlocks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenKey = 'seen_unlock_hours';
      final lastSeen = prefs.getDouble(seenKey) ?? 0.0;

      // Find routes that are now unlocked but weren't before
      final newUnlocks =
          RouteModel.allRoutes.where((r) {
            try {
              return r.unlockHoursRequired > 0 &&
                  r.isUnlocked(_totalHours) &&
                  !r.isUnlocked(lastSeen);
            } catch (_) {
              return false;
            }
          }).toList();

      await prefs.setDouble(seenKey, _totalHours);

      if (newUnlocks.isNotEmpty && mounted) {
        // Small delay for screen to settle
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          RouteUnlockDialog.show(context, newUnlocks.first);
        }
      }
    } catch (e) {
      debugPrint('Route unlock check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _P.ink,
        body: Stack(
          children: [
            // ── Very subtle bg gradient that breathes ──────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _breath,
                builder:
                    (_, __) => Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.4),
                          radius: 1.2,
                          colors: [
                            _scene.accent.withValues(
                              alpha: 0.04 + _breath.value * 0.03,
                            ),
                            _P.ink,
                          ],
                        ),
                      ),
                    ),
              ),
            ),

            // ── Main content ───────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // DIORAMA WINDOW
                          _SceneDiorama(
                                scene: _scene,
                                breath: _breath,
                                train: _train,
                                stars: _stars,
                                aurora: _aurora,
                              )
                              .animate(delay: 150.ms)
                              .fadeIn(duration: 800.ms)
                              .scale(
                                begin: const Offset(0.94, 0.94),
                                curve: Curves.easeOutCubic,
                              ),

                          const SizedBox(height: 28),

                          // STATS DEPARTURE BOARD
                          _DepartureBoardStats(
                                streak: _streak,
                                hours: _totalHours,
                                counter: _counter,
                                accent: _scene.accent,
                              )
                              .animate(delay: 400.ms)
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.08, end: 0),

                          const SizedBox(height: 24),

                          // STATION BUILDING
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: StationWidget(
                              bricks: _bricks,
                              level: _stationLevel,
                              bricksForNext: _bricksForNext,
                            ),
                          )
                              .animate(delay: 500.ms)
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.08, end: 0),

                          const SizedBox(height: 24),

                          // DAILY CHALLENGE
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: DailyChallengeCard(
                              challenge: _dailyChallenge,
                              isCompleted: _challengeCompleted,
                              progress: _challengeProgress,
                            ),
                          )
                              .animate(delay: 520.ms)
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.08, end: 0),

                          const SizedBox(height: 14),

                          // STREAK CALENDAR
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: StreakCalendar(focusData: _focusData),
                          )
                              .animate(delay: 540.ms)
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.08, end: 0),

                          // SECTION DIVIDER
                          _ArtDecoDivider(
                            accent: _scene.accent,
                          ).animate(delay: 550.ms).fadeIn(duration: 500.ms),

                          const SizedBox(height: 20),

                          // AI COACH TIP
                          if (_aiTip.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.push(AppRouter.insights);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF1A1535), Color(0xFF131620)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFF9B85D4).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('🤖', style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'AI COACH',
                                              style: GoogleFonts.spaceMono(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF9B85D4),
                                                letterSpacing: 2,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _aiTip,
                                              style: GoogleFonts.cormorantGaramond(
                                                fontSize: 14,
                                                color: _P.cream.withValues(alpha: 0.85),
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 12,
                                        color: const Color(0xFF9B85D4).withValues(alpha: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                                .animate(delay: 560.ms)
                                .fadeIn(duration: 600.ms)
                                .slideY(begin: 0.08, end: 0),

                          const SizedBox(height: 14),

                          // JOURNEY CARDS
                          SizedBox(
                            height: 160,
                            child:
                                _sessions.isEmpty
                                    ? _EmptyJourneys()
                                    : _JourneyCarousel(sessions: _sessions),
                          ).animate(delay: 650.ms).fadeIn(duration: 500.ms),

                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),

                  // IGNITION LEVER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: _BrassLever(
                          accent: _scene.accent,
                          pulse: _pulse,
                          onIgnite: () {
                            AudioService().playImportantClick();
                            HapticFeedback.heavyImpact();
                            context.push(AppRouter.booking);
                          },
                        )
                        .animate(delay: 750.ms)
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.4, end: 0, curve: Curves.easeOutBack),
                  ),
                ],
              ),
            ),

            // ── Edge vignette ──────────────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Colors.transparent,
                        _P.ink.withValues(alpha: 0.5),
                      ],
                      stops: const [0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // ── Level-up celebration ────────────────────────────
            if (_showLevelUp)
              Positioned.fill(
                child: LevelUpOverlay(
                  newLevel: _stationLevel,
                  stationName: stationNameForLevel(_stationLevel),
                  stationEmoji: stationEmojiForLevel(_stationLevel),
                  onDismiss: () => setState(() => _showLevelUp = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: Row(
            children: [
              // Logo mark
              AnimatedBuilder(
                animation: _pulse,
                builder:
                    (_, __) => Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_P.brassLt, _P.brass, _P.brassDk],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _P.brass.withValues(
                              alpha: 0.25 + _pulse.value * 0.2,
                            ),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.train_rounded,
                        color: _P.ink,
                        size: 22,
                      ),
                    ),
              ),

              const SizedBox(width: 10),

              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _P.cream,
                        letterSpacing: 4,
                      ),
                    ),
                    Text(
                      _focusMood.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: _focusMood.glowColor.withValues(alpha: 0.85),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              // Streak badge
              if (_streak > 0)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push(AppRouter.stats);
                  },
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder:
                        (_, __) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(0xFF281008),
                            border: Border.all(
                              color: const Color(
                                0xFFFF6B35,
                              ).withValues(alpha: 0.3 + _pulse.value * 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF6B35,
                                ).withValues(alpha: 0.1 + _pulse.value * 0.08),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 3),
                              Text(
                                '$_streak',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFF6B35),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),

              const SizedBox(width: 4),

              // Achievements button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(AppRouter.achievements);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _P.raised,
                    border: Border.all(color: _P.brass.withValues(alpha: 0.18)),
                  ),
                  child: const Center(
                    child: Text('🏆', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ),

              // Passport button removed and moved to Achievements Screen

              const SizedBox(width: 4),


              // History button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(AppRouter.history);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _P.raised,
                    border: Border.all(color: _P.brass.withValues(alpha: 0.18)),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: _P.cream,
                    size: 15,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Settings button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(AppRouter.settings);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _P.raised,
                    border: Border.all(color: _P.brass.withValues(alpha: 0.18)),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: _P.cream,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate(delay: 50.ms)
        .fadeIn(duration: 450.ms)
        .slideY(begin: -0.2, end: 0);
  }
}

// ═══════════════════════════════════════════════════════════════
// SCENE DIORAMA — THE HERO WIDGET
// ═══════════════════════════════════════════════════════════════

class _SceneDiorama extends StatefulWidget {
  final SceneTheme scene;
  final Animation<double> breath, train, stars, aurora;

  const _SceneDiorama({
    required this.scene,
    required this.breath,
    required this.train,
    required this.stars,
    required this.aurora,
  });

  @override
  State<_SceneDiorama> createState() => _SceneDioramaState();
}

class _SceneDioramaState extends State<_SceneDiorama> {
  Offset _touch = Offset.zero;
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final w = sw - 48;
    final h = (w * 0.78).clamp(220.0, 360.0);
    final arc = w * 0.48;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onPanStart: (d) {
          setState(() {
            _active = true;
            _touch = d.localPosition;
          });
          HapticFeedback.lightImpact();
        },
        onPanUpdate: (d) {
          setState(() => _touch = d.localPosition);
        },
        onPanEnd: (_) {
          setState(() => _active = false);
        },
        onTapDown: (d) {
          HapticFeedback.selectionClick();
        },
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              // ── OUTER BRASS FRAME GLOW ──────────────────────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: widget.breath,
                  builder:
                      (_, __) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(arc),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _P.brass.withValues(
                                alpha: 0.18 + widget.breath.value * 0.1,
                              ),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: widget.scene.accent.withValues(
                                alpha: 0.08 + widget.breath.value * 0.06,
                              ),
                              blurRadius: 60,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                ),
              ),

              // ── OUTER BRASS BORDER ──────────────────────────
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(arc),
                    ),
                    border: Border.all(color: _P.brass, width: 3),
                  ),
                ),
              ),

              // ── INNER FILIGREE BORDER ───────────────────────
              Positioned(
                top: 5,
                left: 5,
                right: 5,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(arc - 5),
                    ),
                    border: Border.all(
                      color: _P.brass.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // ── CLIPPED SCENE ───────────────────────────────
              Positioned(
                top: 7,
                left: 7,
                right: 7,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(arc - 7),
                  ),
                  child: _SceneContent(
                    scene: widget.scene,
                    breath: widget.breath,
                    train: widget.train,
                    stars: widget.stars,
                    aurora: widget.aurora,
                    parallaxTouch: _touch,
                    isActive: _active,
                    containerWidth: w,
                    containerHeight: h,
                  ),
                ),
              ),

              // ── CORNER BRASS ORNAMENTS ──────────────────────
              ..._corners(w, h, arc),

              // ── BOTTOM BRASS PLATE ──────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BrassPlate(scene: widget.scene),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _corners(double w, double h, double arc) {
    return [
      // Bottom-left
      Positioned(bottom: 0, left: 0, child: _BrassCorner(flip: false)),
      // Bottom-right
      Positioned(bottom: 0, right: 0, child: _BrassCorner(flip: true)),
    ];
  }
}

// ═══════════════════════════════════════════════════════════════
// SCENE CONTENT — Contains all scene layers with proper Stack
// ═══════════════════════════════════════════════════════════════

class _SceneContent extends StatelessWidget {
  final SceneTheme scene;
  final Animation<double> breath, train, stars, aurora;
  final Offset parallaxTouch;
  final bool isActive;
  final double containerWidth, containerHeight;

  const _SceneContent({
    required this.scene,
    required this.breath,
    required this.train,
    required this.stars,
    required this.aurora,
    required this.parallaxTouch,
    required this.isActive,
    required this.containerWidth,
    required this.containerHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([breath, train, stars, aurora]),
      builder: (_, __) {
        final parallax =
            isActive
                ? Offset(
                  (parallaxTouch.dx - containerWidth / 2) / 80,
                  (parallaxTouch.dy - containerHeight / 2) / 80,
                )
                : Offset(
                  math.sin(breath.value * math.pi * 2) * 12,
                  math.cos(breath.value * math.pi) * 3,
                );

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            // Sky
            _SkyLayer(sky: scene.sky),

            // Celestial bodies
            if (scene.stars)
              CustomPaint(
                painter: _StarsPainter(t: stars.value, parallax: parallax),
              ),
            if (scene.isAurora)
              CustomPaint(painter: _AuroraPainter(t: aurora.value)),
            if (scene.shooters)
              CustomPaint(painter: _ShootersPainter(t: train.value)),
            if (scene.sun)
              _SunBody(breathValue: breath.value, parallax: parallax),
            if (scene.moon)
              _MoonBody(breathValue: breath.value, parallax: parallax),
            if (scene.clouds)
              CustomPaint(painter: _CloudsPainter(t: breath.value)),

            // Mountains (3 parallax layers)
            _MountainStack(parallax: parallax, scene: scene),

            // Tracks
            CustomPaint(painter: _TracksPainter()),

            // Train — uses internal Stack
            _TrainLayer(t: train.value),

            // Ground + grass
            _GroundLayer(t: breath.value),

            // Fireflies
            if (scene.fireflies)
              CustomPaint(painter: _FirefliesPainter(t: aurora.value)),
            if (scene.lanterns)
              CustomPaint(painter: _LanternsPainter(t: train.value)),

            // Location title overlay
            _LocationOverlay(scene: scene, breath: breath.value),

            // Glass reflection
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.09),
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.03),
                      ],
                      stops: const [0, 0.3, 1],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BrassCorner extends StatelessWidget {
  final bool flip;
  const _BrassCorner({required this.flip});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flip ? -1 : 1,
      child: SizedBox(
        width: 28,
        height: 28,
        child: CustomPaint(painter: _CornerOrnamentPainter()),
      ),
    );
  }
}

class _CornerOrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p =
        Paint()
          ..color = _P.brass
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(2, s.height - 2), const Offset(2, 8), p);
    canvas.drawLine(
      Offset(2, s.height - 2),
      Offset(s.width - 2, s.height - 2),
      p,
    );
    canvas.drawCircle(const Offset(2, 2), 3, Paint()..color = _P.brass);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _BrassPlate extends StatelessWidget {
  final SceneTheme scene;
  const _BrassPlate({required this.scene});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_P.brassDk, _P.brass, _P.brassLt, _P.brass, _P.brassDk],
          stops: [0, 0.2, 0.5, 0.8, 1],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _plateRivet(),
          const SizedBox(width: 12),
          Text(
            scene.label.toUpperCase(),
            style: GoogleFonts.cormorantGaramond(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _P.ink,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(width: 12),
          _plateRivet(),
        ],
      ),
    );
  }

  Widget _plateRivet() => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _P.brassDk,
      boxShadow: [
        BoxShadow(color: _P.brassLt.withValues(alpha: 0.6), blurRadius: 3),
      ],
    ),
  );
}

// ─── Scene sub-widgets ────────────────────────────────────────

class _SkyLayer extends StatelessWidget {
  final List<Color> sky;
  const _SkyLayer({required this.sky});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: sky,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// CELESTIAL BODIES
// ═══════════════════════════════════════════════════════════════

class _SunBody extends StatelessWidget {
  final double breathValue;
  final Offset parallax;
  const _SunBody({required this.breathValue, required this.parallax});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 28 + parallax.dy,
      right: 60 + parallax.dx,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFFFF8D0), Color(0xFFFFDD50), Color(0xFFFF9020)],
            stops: [0, 0.5, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFFFCC30,
              ).withValues(alpha: 0.4 + breathValue * 0.25),
              blurRadius: 40,
              spreadRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoonBody extends StatelessWidget {
  final double breathValue;
  final Offset parallax;
  const _MoonBody({required this.breathValue, required this.parallax});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 24 + parallax.dy,
      right: 55 + parallax.dx,
      child: Stack(
        children: [
          // Glow
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(
                    alpha: 0.15 + breathValue * 0.1,
                  ),
                  blurRadius: 40,
                  spreadRadius: 12,
                ),
              ],
            ),
          ),
          // Body
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFFF0F0F0),
                  Color(0xFFD8D8D8),
                  Color(0xFFB8B8B8),
                ],
              ),
            ),
            child: CustomPaint(painter: _MoonCraterPainter()),
          ),
        ],
      ),
    );
  }
}

class _MountainStack extends StatelessWidget {
  final Offset parallax;
  final SceneTheme scene;
  const _MountainStack({required this.parallax, required this.scene});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Far — faintest
        Positioned(
          bottom: 0,
          left: parallax.dx * 1.5,
          right: -parallax.dx * 1.5,
          child: CustomPaint(
            size: const Size(double.infinity, 220),
            painter: _MountainPainter(
              alpha: 0.18,
              seed: 1,
              snowCapped: true,
              baseColor: Colors.black,
            ),
          ),
        ),
        // Mid
        Positioned(
          bottom: 0,
          left: parallax.dx * 3,
          right: -parallax.dx * 3,
          child: CustomPaint(
            size: const Size(double.infinity, 160),
            painter: _MountainPainter(
              alpha: 0.45,
              seed: 2,
              snowCapped: false,
              baseColor: Colors.black,
            ),
          ),
        ),
        // Near — darkest
        Positioned(
          bottom: 0,
          left: parallax.dx * 5,
          right: -parallax.dx * 5,
          child: CustomPaint(
            size: const Size(double.infinity, 100),
            painter: _MountainPainter(
              alpha: 0.78,
              seed: 3,
              snowCapped: false,
              baseColor: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TRAIN LAYER — FIXED: Uses internal Stack for Positioned
// ═══════════════════════════════════════════════════════════════

class _TrainLayer extends StatelessWidget {
  final double t;
  const _TrainLayer({required this.t});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trainWidth = 160.0; // Total width of train sprite
        final x = -trainWidth + (constraints.maxWidth + trainWidth + 40) * t;
        final bob = math.sin(t * math.pi * 18) * 1.2;
        final bottomOffset = constraints.maxHeight * 0.18 + bob;

        // Use SizedBox + Stack so Positioned has correct parent
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: bottomOffset,
                left: x,
                child: const _TrainSprite(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TRAIN SPRITE — FIXED: Locomotive now faces RIGHT (direction of travel)
// ═══════════════════════════════════════════════════════════════

class _TrainSprite extends StatelessWidget {
  const _TrainSprite();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Carriages at the BACK (left side, trailing)
        _Carriage(dark: true),
        const SizedBox(width: 2),
        _Carriage(dark: false),
        const SizedBox(width: 2),
        // Locomotive at the FRONT (right side, leading)
        const _Loco(),
      ],
    );
  }
}

class _Loco extends StatelessWidget {
  const _Loco();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main body
          Positioned(
            bottom: 5,
            left: 0,
            child: Container(
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF404040), Color(0xFF1A1A1A)],
                ),
              ),
              child: Stack(
                children: [
                  // Cabin window - on LEFT (back of locomotive)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A2010),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: _P.brass.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 7,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFCC70,
                            ).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Boiler detail
                  Positioned(
                    top: 8,
                    right: 18,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2A2A2A),
                        border: Border.all(
                          color: _P.brass.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  // Headlight - on RIGHT (front of locomotive)
                  Positioned(
                    top: 10,
                    right: 3,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFEE88),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFEE88,
                            ).withValues(alpha: 0.7),
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Brass trim
                  Positioned(
                    bottom: 2,
                    left: 4,
                    right: 4,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: _P.brass.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Chimney - on RIGHT (front of locomotive)
          Positioned(
            top: 0,
            right: 14,
            child: Container(
              width: 10,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                border: Border.all(color: _P.brass.withValues(alpha: 0.35)),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            ),
          ),
          // Smoke puffs
          Positioned(
            top: -6,
            right: 12,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned(
            top: -12,
            right: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: -16,
            right: 14,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Cow catcher / front guard - on RIGHT
          Positioned(
            bottom: 3,
            right: -3,
            child: Container(
              width: 8,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(4),
                  topRight: Radius.circular(2),
                ),
                border: Border.all(color: _P.brass.withValues(alpha: 0.25)),
              ),
            ),
          ),
          // Wheels
          Positioned(bottom: 0, left: 8, child: _Wheel(size: 10)),
          Positioned(bottom: 0, left: 24, child: _Wheel(size: 10)),
          Positioned(bottom: 0, right: 10, child: _Wheel(size: 10)),
        ],
      ),
    );
  }
}

class _Carriage extends StatelessWidget {
  final bool dark;
  const _Carriage({required this.dark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main body
          Positioned(
            bottom: 5,
            left: 0,
            child: Container(
              width: 46,
              height: 26,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors:
                      dark
                          ? [const Color(0xFF4A3018), const Color(0xFF2A1808)]
                          : [const Color(0xFF3A3A3A), const Color(0xFF1A1A1A)],
                ),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _P.brass.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (_) => Container(
                    width: 6,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDD80).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(1),
                      border: Border.all(
                        color: _P.brass.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Roof
          Positioned(
            bottom: 28,
            left: 2,
            right: 2,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF3A2818) : const Color(0xFF2A2A2A),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            ),
          ),
          // Connector on right side (towards locomotive)
          Positioned(
            bottom: 12,
            right: -3,
            child: Container(
              width: 6,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Connector on left side (towards next carriage)
          Positioned(
            bottom: 12,
            left: -3,
            child: Container(
              width: 6,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Wheels
          Positioned(bottom: 0, left: 6, child: _Wheel(size: 9)),
          Positioned(bottom: 0, right: 6, child: _Wheel(size: 9)),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  final double size;
  const _Wheel({this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF5A5A5A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.35,
          height: size * 0.35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF707070),
            border: Border.all(color: const Color(0xFF505050), width: 0.5),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GROUND LAYER
// ═══════════════════════════════════════════════════════════════

class _GroundLayer extends StatelessWidget {
  final double t;
  const _GroundLayer({required this.t});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 36,
        child: CustomPaint(painter: _GroundPainter(t: t)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LOCATION OVERLAY
// ═══════════════════════════════════════════════════════════════

class _LocationOverlay extends StatelessWidget {
  final SceneTheme scene;
  final double breath;
  const _LocationOverlay({required this.scene, required this.breath});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 44,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _divLine(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'NOW APPROACHING',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 8,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 3,
                  ),
                ),
              ),
              _divLine(),
            ],
          ),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback:
                (b) => LinearGradient(
                  colors: [Colors.white, scene.accent, Colors.white],
                  stops: [
                    (breath - 0.35).clamp(0.0, 1.0),
                    breath.clamp(0.0, 1.0),
                    (breath + 0.35).clamp(0.0, 1.0),
                  ],
                ).createShader(b),
            child: Text(
              scene.label.toUpperCase(),
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 2.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divLine() => Container(
    width: 28,
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// DEPARTURE BOARD STATS
// ═══════════════════════════════════════════════════════════════

class _DepartureBoardStats extends StatelessWidget {
  final int streak;
  final double hours;
  final Animation<double> counter;
  final Color accent;

  const _DepartureBoardStats({
    required this.streak,
    required this.hours,
    required this.counter,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        borderRadius: 18,
        blur: 16,
        tint: const Color(0x18D4A853),
        borderColor: _P.brass.withValues(alpha: 0.22),
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Board header
            Container(
              height: 38,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
                gradient: LinearGradient(
                  colors: [
                    _P.brassDk,
                    _P.brass,
                    _P.brassLt,
                    _P.brass,
                    _P.brassDk,
                  ],
                  stops: [0, 0.2, 0.5, 0.8, 1],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.confirmation_number_outlined,
                    size: 13,
                    color: _P.ink,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'JOURNEY RECORD',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _P.ink,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),

            // Stats row
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'STREAK',
                      value: streak,
                      unit: 'days',
                      icon: Icons.local_fire_department_rounded,
                      accent: const Color(0xFFFF6030),
                      counter: counter,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 70,
                    color: _P.brass.withValues(alpha: 0.12),
                  ),
                  Expanded(
                    child: _StatTile(
                      label: 'FOCUSED',
                      value: hours.round(),
                      unit: 'hours',
                      icon: Icons.hourglass_bottom_rounded,
                      accent: accent,
                      counter: counter,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, unit;
  final int value;
  final IconData icon;
  final Color accent;
  final Animation<double> counter;

  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accent,
    required this.counter,
  });

  @override
  Widget build(BuildContext context) {
    // Entrance layout builds with alpha slider, then counts up:
    return AnimatedBuilder(
      animation: counter,
      builder: (_, __) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedCounter(
                  value: value.toDouble(),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutCirc,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: _P.cream,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 13,
                    color: _P.t2,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: accent),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ART DECO DIVIDER
// ═══════════════════════════════════════════════════════════════

class _ArtDecoDivider extends StatelessWidget {
  final Color accent;
  const _ArtDecoDivider({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _line(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _diamond(),
                const SizedBox(width: 8),
                Text(
                  'JOURNEYS',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _P.brass,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 8),
                _diamond(),
              ],
            ),
          ),
          _line(),
        ],
      ),
    );
  }

  Widget _line() => Expanded(
    child: Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _P.brass.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
      ),
    ),
  );

  Widget _diamond() => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(
      color: _P.brass,
      borderRadius: BorderRadius.circular(1),
      boxShadow: [
        BoxShadow(color: _P.brass.withValues(alpha: 0.5), blurRadius: 6),
      ],
    ),
    transform: Matrix4.rotationZ(math.pi / 4),
  );
}

// ═══════════════════════════════════════════════════════════════
// JOURNEY CAROUSEL
// ═══════════════════════════════════════════════════════════════

class _JourneyCarousel extends StatelessWidget {
  final List<JourneySession> sessions;
  const _JourneyCarousel({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: sessions.length,
      itemBuilder: (_, i) {
        return _TicketCard(session: sessions[i], index: i)
            .animate(delay: Duration(milliseconds: i * 80))
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final JourneySession session;
  final int index;
  const _TicketCard({required this.session, required this.index});

  static const _accents = [
    Color(0xFF2A4060),
    Color(0xFF402A10),
    Color(0xFF2A1A50),
    Color(0xFF1A3A28),
    Color(0xFF3A1A20),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = _accents[index % _accents.length];

    return Container(
      width: 240,
      height: 150,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          // Card body with notch clip
          ClipPath(
            clipper: const _TicketClipper(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bg.withValues(alpha: 0.9),
                    bg.withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Hatch pattern
                  Positioned.fill(child: CustomPaint(painter: _HatchPainter())),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.routeName
                                      .split(' ')
                                      .first
                                      .toUpperCase(),
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _P.cream,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _P.brass.withValues(alpha: 0.4),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'FIRST CLASS',
                                    style: GoogleFonts.cormorantGaramond(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: _P.brass,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.spa_outlined,
                              color: _P.brass.withValues(alpha: 0.5),
                              size: 20,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _detail('DURATION', session.formattedDuration),
                            _detail(
                              'SEAT',
                              '${(session.startTime.day % 9) + 1}${String.fromCharCode(65 + session.startTime.minute % 5)}',
                              end: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Gold left stripe
          Positioned(
            left: 0,
            top: 12,
            bottom: 12,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_P.brassLt, _P.brass, _P.brassDk],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String l, String v, {bool end = false}) {
    return Column(
      crossAxisAlignment:
          end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          l,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 8,
            color: _P.t2,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          v,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _P.cream,
          ),
        ),
      ],
    );
  }
}

class _EmptyJourneys extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _P.panel,
          border: Border.all(color: _P.brass.withValues(alpha: 0.15)),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_outlined,
              color: _P.brass.withValues(alpha: 0.5),
              size: 26,
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your journey awaits',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 16,
                    color: _P.cream,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  'Pull the lever to begin',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 11,
                    color: _P.t2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 600.ms).fadeIn().scale(begin: const Offset(0.92, 0.92));
  }
}

// ═══════════════════════════════════════════════════════════════
// BRASS LEVER CTA
// ═══════════════════════════════════════════════════════════════
class _BrassLever extends StatefulWidget {
  final Color accent;
  final Animation<double> pulse;
  final VoidCallback onIgnite;

  const _BrassLever({
    required this.accent,
    required this.pulse,
    required this.onIgnite,
  });

  @override
  State<_BrassLever> createState() => _BrassLeverState();
}

class _BrassLeverState extends State<_BrassLever>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _pullN = ValueNotifier(0.0);
  bool _fired = false;
  late AnimationController _reset;

  @override
  void initState() {
    super.initState();
    _reset = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _reset.addListener(() {
      _pullN.value = _pullN.value * (1 - _reset.value);
    });
  }

  @override
  void dispose() {
    _reset.dispose();
    _pullN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const h = 72.0;
    const knobW = 120.0;

    return AnimatedBuilder(
      animation: widget.pulse,
      builder:
          (_, child) => Container(
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(h / 2),
              color: _P.panel,
              border: Border.all(
                color: _P.brass.withValues(
                  alpha: 0.18 + widget.pulse.value * 0.12,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: const Offset(0, 6),
                  blurRadius: 18,
                ),
                // Pulsing glow ring
                BoxShadow(
                  color: widget.accent.withValues(
                    alpha: 0.08 + widget.pulse.value * 0.12,
                  ),
                  blurRadius: (24 + widget.pulse.value * 12).clamp(0.0, 999.0),
                  spreadRadius: -2 + widget.pulse.value * 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: child,
          ),
      child: LayoutBuilder(
        builder: (_, c) {
          final track = c.maxWidth - knobW;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Progress fill — only repaints on pull change
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(h / 2),
                  child: ValueListenableBuilder<double>(
                    valueListenable: _pullN,
                    builder:
                        (_, pull, __) => Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: c.maxWidth * pull,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.accent.withValues(alpha: 0.15),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                  ),
                ),
              ),

              // Hint text
              Positioned(
                right: 20,
                child: ValueListenableBuilder<double>(
                  valueListenable: _pullN,
                  builder:
                      (_, pull, child) => AnimatedOpacity(
                        opacity: pull < 0.2 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        child: child,
                      ),
                  child: Row(
                    children: [
                      Text(
                        'PULL TO IGNITE',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _P.t2,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: _P.brass.withValues(alpha: 0.5),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              // Knob — draggable, isolated repaint
              ValueListenableBuilder<double>(
                valueListenable: _pullN,
                builder:
                    (_, pull, __) => Positioned(
                      left: pull * track,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (d) {
                          if (_fired) return;
                          final newPull = (_pullN.value + d.delta.dx / track)
                              .clamp(0.0, 1.0);
                          _pullN.value = newPull;

                          if (newPull > 0.5 && newPull < 0.52) {
                            HapticFeedback.lightImpact();
                          }
                          if (newPull > 0.78 && newPull < 0.80) {
                            HapticFeedback.mediumImpact();
                          }
                          if (newPull >= 0.96) {
                            _fired = true;
                            HapticFeedback.heavyImpact();
                            widget.onIgnite();
                            Future.delayed(
                              const Duration(milliseconds: 900),
                              () {
                                if (mounted) {
                                  _fired = false;
                                  _reset.forward(from: 0);
                                }
                              },
                            );
                          }
                        },
                        onHorizontalDragEnd: (_) {
                          if (!_fired) {
                            _reset.forward(from: 0);
                          }
                        },
                        child: RepaintBoundary(
                          child: _Knob(
                            pull: pull,
                            fired: _fired,
                            accent: widget.accent,
                          ),
                        ),
                      ),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Knob extends StatelessWidget {
  final double pull;
  final bool fired;
  final Color accent;
  const _Knob({required this.pull, required this.fired, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_P.brassLt, _P.brass, _P.brassDk],
          stops: [0, 0.45, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
          BoxShadow(
            color: _P.brass.withValues(alpha: pull * 0.45),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Grip
          Container(
            width: 44,
            height: 52,
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3E2810), Color(0xFF1E1008)],
              ),
              border: Border.all(color: _P.brassDk.withValues(alpha: 0.6)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                5,
                (_) => Container(
                  width: 20,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: _P.brassDk.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  fired ? Icons.check_circle_rounded : Icons.train_rounded,
                  color: _P.ink,
                  size: 18,
                ),
                const SizedBox(height: 3),
                Text(
                  fired ? 'IGNITED!' : 'BEGIN',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _P.ink,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════

class _StarsPainter extends CustomPainter {
  final double t;
  final Offset parallax;
  _StarsPainter({required this.t, required this.parallax});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final p = Paint();
    for (int i = 0; i < 90; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = rng.nextDouble() * size.height * 0.65;
      final depth = rng.nextDouble();
      final x = bx + parallax.dx * (1 + depth * 2);
      final y = by + parallax.dy * (1 + depth * 2);
      final phase = rng.nextDouble() * math.pi * 2;
      final tw = (math.sin(t * math.pi * 2 * 0.6 + phase) + 1) / 2;
      final alpha = 0.25 + rng.nextDouble() * 0.45 + tw * 0.2;
      final r = 0.6 + rng.nextDouble() * 1.4;
      p.color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), r, p);
      if (depth > 0.8) {
        final glow =
            Paint()
              ..color = Colors.white.withValues(alpha: tw * 0.25)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset(x, y), 5, glow);
      }
    }
  }

  @override
  bool shouldRepaint(_StarsPainter o) => o.t != t || o.parallax != parallax;
}

class _AuroraPainter extends CustomPainter {
  final double t;
  _AuroraPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (int w = 0; w < 3; w++) {
      final path = Path();
      final yb = size.height * (0.12 + w * 0.08);
      path.moveTo(0, yb);
      for (double x = 0; x <= size.width; x += 4) {
        final nx = x / size.width;
        final wh =
            math.sin(nx * math.pi * 3 + t * math.pi * 2 + w * 0.4) * 35 +
            math.sin(nx * math.pi * 6 + t * math.pi * 3.5 + w * 0.8) * 18;
        path.lineTo(x, yb + wh);
      }
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF00D9D0).withValues(alpha: 0.0),
              const Color(0xFF00FF94).withValues(alpha: 0.12 - w * 0.035),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, yb + 60)),
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter o) => o.t != t;
}

class _ShootersPainter extends CustomPainter {
  final double t;
  _ShootersPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    for (int i = 0; i < 3; i++) {
      final phase = (t + i * 0.33) % 1.0;
      if (phase > 0.28) continue;
      final prog = phase / 0.28;
      final sx = rng.nextDouble() * size.width * 0.6 + size.width * 0.15;
      final sy = rng.nextDouble() * size.height * 0.28;
      final cx = sx + 140 * prog;
      final cy = sy + 90 * prog;
      canvas.drawLine(
        Offset(cx - 80, cy - 50),
        Offset(cx, cy),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.85 * (1 - prog)),
            ],
          ).createShader(
            Rect.fromPoints(Offset(cx - 80, cy - 50), Offset(cx, cy)),
          )
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        2.5,
        Paint()
          ..color = Colors.white.withValues(alpha: 1 - prog)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_ShootersPainter o) => o.t != t;
}

class _CloudsPainter extends CustomPainter {
  final double t;
  _CloudsPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (int i = 0; i < 4; i++) {
      final bx =
          (i * size.width * 0.35 + t * size.width * 0.45) % (size.width + 160) -
          80;
      final by = size.height * (0.1 + i * 0.07);
      final cw = 70.0 + i * 28;
      final ch = 22.0 + i * 8;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(bx, by), width: cw, height: ch),
        p,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bx - cw * 0.28, by + ch * 0.2),
          width: cw * 0.55,
          height: ch * 0.75,
        ),
        p,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bx + cw * 0.28, by + ch * 0.18),
          width: cw * 0.48,
          height: ch * 0.68,
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_CloudsPainter o) => o.t != t;
}

class _MountainPainter extends CustomPainter {
  final double alpha;
  final int seed;
  final bool snowCapped;
  final Color baseColor;

  _MountainPainter({
    required this.alpha,
    required this.seed,
    required this.snowCapped,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final pts = <Offset>[];
    for (int i = 0; i <= 10; i++) {
      pts.add(
        Offset(
          (i / 10) * size.width,
          size.height - (0.2 + rng.nextDouble() * 0.72) * size.height,
        ),
      );
    }
    final path = Path()..moveTo(0, size.height);
    path.lineTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1], curr = pts[i];
      final cpX = prev.dx + (curr.dx - prev.dx) * 0.5;
      path.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = baseColor.withValues(alpha: alpha));

    if (snowCapped) {
      final sp = Path()..moveTo(0, size.height);
      path.moveTo(pts.first.dx, pts.first.dy + 12);
      for (int i = 1; i < pts.length; i++) {
        final prev = pts[i - 1], curr = pts[i];
        final cpX = prev.dx + (curr.dx - prev.dx) * 0.5;
        sp.cubicTo(cpX, prev.dy + 12, cpX, curr.dy + 12, curr.dx, curr.dy + 12);
      }
      for (int i = pts.length - 1; i >= 0; i--) {
        final p = pts[i];
        if (i == pts.length - 1) {
          sp.lineTo(p.dx, p.dy);
        } else {
          final nx = pts[i + 1];
          sp.quadraticBezierTo(p.dx + (nx.dx - p.dx) * 0.5, p.dy, p.dx, p.dy);
        }
      }
      sp.close();
      canvas.drawPath(
        sp,
        Paint()..color = Colors.white.withValues(alpha: 0.28),
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _TracksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
    const vY = 0.44; // vanish Y ratio
    final vX = size.width * 0.5;
    final lL = size.width * 0.36, lR = size.width * 0.64;
    canvas.drawLine(
      Offset(lL, size.height),
      Offset(vX - 2, size.height * vY),
      p,
    );
    canvas.drawLine(
      Offset(lR, size.height),
      Offset(vX + 2, size.height * vY),
      p,
    );
    p.strokeWidth = 1.5;
    for (int i = 0; i < 18; i++) {
      final t = i / 18.0;
      final persp = math.pow(t, 1.9).toDouble();
      final y = size.height - (size.height - size.height * vY) * persp;
      final spread = (1 - persp) * (lR - lL) / 2 + 4;
      p.color = Colors.white.withValues(alpha: 0.14 * (1 - persp * 0.7));
      canvas.drawLine(Offset(vX - spread, y), Offset(vX + spread, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _GroundPainter extends CustomPainter {
  final double t;
  _GroundPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF181410), Color(0xFF0A0806)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    final rng = math.Random(456);
    final gp =
        Paint()
          ..color = const Color(0xFF1A2010)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 50; i++) {
      final x = rng.nextDouble() * size.width;
      final gh = 4 + rng.nextDouble() * 9;
      final sw = math.sin(t * math.pi * 2 + x * 0.04) * 2.5;
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + sw, size.height - gh),
        gp,
      );
    }
  }

  @override
  bool shouldRepaint(_GroundPainter o) => o.t != t;
}

class _FirefliesPainter extends CustomPainter {
  final double t;
  _FirefliesPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(123);
    for (int i = 0; i < 18; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = size.height * 0.48 + rng.nextDouble() * size.height * 0.42;
      final fx = math.sin(t * math.pi * 2 + i * 1.6) * 14;
      final fy = math.cos(t * math.pi * 3 + i * 2.1) * 9;
      final bp = rng.nextDouble() * math.pi * 2;
      final blink = (math.sin(t * math.pi * 4.5 + bp) + 1) / 2;
      if (blink < 0.25) continue;
      canvas.drawCircle(
        Offset(bx + fx, by + fy),
        5,
        Paint()
          ..color = const Color(0xFFFFFF00).withValues(alpha: blink * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawCircle(
        Offset(bx + fx, by + fy),
        2,
        Paint()..color = const Color(0xFFFFFF80).withValues(alpha: blink * 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_FirefliesPainter o) => o.t != t;
}

class _LanternsPainter extends CustomPainter {
  final double t;
  _LanternsPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(789);
    for (int i = 0; i < 7; i++) {
      final bx = rng.nextDouble() * size.width;
      final prog = ((t + i * 0.14) % 1.0);
      final y = size.height + 40 - prog * (size.height + 80);
      final dx = math.sin(prog * math.pi * 3.5 + i) * 18;
      final x = bx + dx;
      if (y < -40 || y > size.height + 10) continue;
      final ls = 11.0 - prog * 3.5;
      final op = (1 - prog) * 0.75;
      canvas.drawCircle(
        Offset(x, y),
        ls * 2,
        Paint()
          ..color = const Color(0xFFFF6600).withValues(alpha: op * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: ls, height: ls * 1.4),
          Radius.circular(ls * 0.28),
        ),
        Paint()..color = const Color(0xFFFFAA00).withValues(alpha: op),
      );
      canvas.drawCircle(
        Offset(x, y - ls * 0.1),
        ls * 0.28,
        Paint()..color = const Color(0xFFFFFF60).withValues(alpha: op * 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_LanternsPainter o) => o.t != t;
}

class _MoonCraterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(321);
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (0.2 + rng.nextDouble() * 0.6),
          size.height * (0.2 + rng.nextDouble() * 0.6),
        ),
        2 + rng.nextDouble() * 3.5,
        Paint()..color = Colors.grey.withValues(alpha: 0.28),
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Ticket clipper ──────────────────────────────────────────

class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper();
  @override
  Path getClip(Size size) {
    const r = 10.0, notch = 9.0;
    final ny = size.height / 2;
    final path = Path();
    path.moveTo(r, 0);
    path.lineTo(size.width - r, 0);
    path.arcToPoint(Offset(size.width, r), radius: const Radius.circular(r));
    path.lineTo(size.width, ny - notch);
    path.arcToPoint(
      Offset(size.width, ny + notch),
      radius: const Radius.circular(notch),
      clockwise: false,
    );
    path.lineTo(size.width, size.height - r);
    path.arcToPoint(
      Offset(size.width - r, size.height),
      radius: const Radius.circular(r),
    );
    path.lineTo(r, size.height);
    path.arcToPoint(
      Offset(0, size.height - r),
      radius: const Radius.circular(r),
    );
    path.lineTo(0, ny + notch);
    path.arcToPoint(
      Offset(0, ny - notch),
      radius: const Radius.circular(notch),
      clockwise: false,
    );
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: const Radius.circular(r));
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

class _HatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.025)
          ..strokeWidth = 1;
    const gap = 16.0;
    for (double i = -size.height; i < size.width + size.height; i += gap) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ════════════════════════════════════════════════════════════════
// PASSENGER CABIN CARD — Social Co-Working Entry Point
// ════════════════════════════════════════════════════════════════

class _PassengerCabinCard extends StatelessWidget {
  _PassengerCabinCard();

  final _service = CabinService.instance;

  @override
  Widget build(BuildContext context) {
    final inCabin = _service.currentCabinId != null;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CabinSelectionScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF121825), Color(0xFF0E1018)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4A853).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4A853).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFFD4A853).withValues(alpha: 0.25),
                ),
              ),
              child: const Center(
                child: Text('👥', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PASSENGER CABINS',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD4A853),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  StreamBuilder<List<CabinModel>>(
                    stream: _service.publicCabinsStream(),
                    builder: (_, snap) {
                      final cabins = snap.data ?? [];
                      final activeCount = cabins.fold<int>(
                        0,
                        (sum, c) => sum + c.activeCount,
                      );
                      return Text(
                        inCabin
                            ? 'You\'re in a cabin — focus together'
                            : activeCount > 0
                                ? '$activeCount passengers focusing now'
                                : 'Open a cabin and invite friends',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF9A8E78),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFD4A853),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
