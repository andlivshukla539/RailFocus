// lib/screens/focus_screen.dart
// ═══════════════════════════════════════════════════════════════
//  RAIL FOCUS — FOCUS SESSION SCREEN  v6  "THE OBSERVATORY"
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/route_model.dart';
import '../models/session_model.dart';
import '../router/app_router.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../services/timer_service.dart';
import '../services/wakelock_service.dart';
import '../widgets/audio_control.dart';
import '../widgets/journey_map_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

bool get _isLowEnd {
  return WidgetsBinding.instance.window.physicalSize.shortestSide < 720;
}

// ───────────────────────────────────────────────────────────────
// ENUMS
// ───────────────────────────────────────────────────────────────

enum CelestialType { sun, moon, none }

enum ParticleKind { blossom, snow, firefly, sand, none }

// ───────────────────────────────────────────────────────────────
// AMBIENT SOUND CONSTANTS
// ───────────────────────────────────────────────────────────────

const _kAmbientColor = Color(0xFF9B85D4);
const _kAmbientEqSpeeds = [0.55, 0.38, 0.65, 0.42, 0.58];

// ───────────────────────────────────────────────────────────────
// ROUTE VISUALS
// ───────────────────────────────────────────────────────────────

@immutable
class _RouteVisuals {
  final String shortName;
  final String departure;
  final String arrival;
  final int distanceKm;
  final CelestialType celestial;
  final bool isNight;
  final List<Color> sky;
  final Color farMtn;
  final Color midMtn;
  final Color hill;
  final Color tree;
  final Color ground;
  final ParticleKind particle;

  const _RouteVisuals({
    required this.shortName,
    required this.departure,
    required this.arrival,
    required this.distanceKm,
    required this.celestial,
    required this.isNight,
    required this.sky,
    required this.farMtn,
    required this.midMtn,
    required this.hill,
    required this.tree,
    required this.ground,
    required this.particle,
  });
}

const Map<String, _RouteVisuals> _kVis = {
  'tokyo_kyoto': _RouteVisuals(
    shortName: 'Tokyo → Kyoto',
    departure: 'TOKYO',
    arrival: 'KYOTO',
    distanceKm: 513,
    celestial: CelestialType.moon,
    isNight: true,
    particle: ParticleKind.blossom,
    sky: [
      Color(0xFF0D0614),
      Color(0xFF1E0A22),
      Color(0xFF3D1535),
      Color(0xFF7A2E52),
      Color(0xFFB05E78),
    ],
    farMtn: Color(0xFF110818),
    midMtn: Color(0xFF1A1025),
    hill: Color(0xFF0E2415),
    tree: Color(0xFF091A0F),
    ground: Color(0xFF060E08),
  ),
  'swiss_alps': _RouteVisuals(
    shortName: 'Zürich → Zermatt',
    departure: 'ZÜRICH',
    arrival: 'ZERMATT',
    distanceKm: 220,
    celestial: CelestialType.sun,
    isNight: false,
    particle: ParticleKind.snow,
    sky: [
      Color(0xFF08111E),
      Color(0xFF0F2035),
      Color(0xFF1E3E60),
      Color(0xFF3A6A96),
      Color(0xFF7AAFC8),
    ],
    farMtn: Color(0xFF1E2E3C),
    midMtn: Color(0xFF172636),
    hill: Color(0xFF102E2A),
    tree: Color(0xFF081E16),
    ground: Color(0xFF061410),
  ),
  'norwegian_fjords': _RouteVisuals(
    shortName: 'Oslo → Bergen',
    departure: 'OSLO',
    arrival: 'BERGEN',
    distanceKm: 490,
    celestial: CelestialType.moon,
    isNight: true,
    particle: ParticleKind.firefly,
    sky: [
      Color(0xFF01040B),
      Color(0xFF030810),
      Color(0xFF060E1C),
      Color(0xFF0A1628),
      Color(0xFF0E1E36),
    ],
    farMtn: Color(0xFF060E1A),
    midMtn: Color(0xFF081422),
    hill: Color(0xFF061612),
    tree: Color(0xFF030E0A),
    ground: Color(0xFF020808),
  ),
  'sahara_express': _RouteVisuals(
    shortName: 'Casa → Marrakech',
    departure: 'CASABLANCA',
    arrival: 'MARRAKECH',
    distanceKm: 240,
    celestial: CelestialType.sun,
    isNight: false,
    particle: ParticleKind.sand,
    sky: [
      Color(0xFF100400),
      Color(0xFF281000),
      Color(0xFF5A2E00),
      Color(0xFFA86010),
      Color(0xFFD49A38),
    ],
    farMtn: Color(0xFF4E300A),
    midMtn: Color(0xFF6A4414),
    hill: Color(0xFF886020),
    tree: Color(0xFF5A3808),
    ground: Color(0xFF3E2406),
  ),
  'trans_siberian': _RouteVisuals(
    shortName: 'Moscow → Vladivostok',
    departure: 'MOSCOW',
    arrival: 'VLADIVOSTOK',
    distanceKm: 9259,
    celestial: CelestialType.moon,
    isNight: true,
    particle: ParticleKind.snow,
    sky: [
      Color(0xFF060810),
      Color(0xFF0A1220),
      Color(0xFF142038),
      Color(0xFF1E3050),
      Color(0xFF2A4268),
    ],
    farMtn: Color(0xFF0A1420),
    midMtn: Color(0xFF0E1A2A),
    hill: Color(0xFF0A1818),
    tree: Color(0xFF080E12),
    ground: Color(0xFF04080C),
  ),
  'orient_express': _RouteVisuals(
    shortName: 'Paris → Istanbul',
    departure: 'PARIS',
    arrival: 'ISTANBUL',
    distanceKm: 2740,
    celestial: CelestialType.sun,
    isNight: false,
    particle: ParticleKind.none,
    sky: [
      Color(0xFF1A0A08),
      Color(0xFF2E1408),
      Color(0xFF5A2E10),
      Color(0xFF8A4A20),
      Color(0xFFD4882A),
    ],
    farMtn: Color(0xFF3A2010),
    midMtn: Color(0xFF4A2E18),
    hill: Color(0xFF2A3820),
    tree: Color(0xFF1A2814),
    ground: Color(0xFF101808),
  ),
  'indian_pacific': _RouteVisuals(
    shortName: 'Sydney → Perth',
    departure: 'SYDNEY',
    arrival: 'PERTH',
    distanceKm: 4352,
    celestial: CelestialType.sun,
    isNight: false,
    particle: ParticleKind.sand,
    sky: [
      Color(0xFF200808),
      Color(0xFF401410),
      Color(0xFF802818),
      Color(0xFFA84818),
      Color(0xFFD06828),
    ],
    farMtn: Color(0xFF6A3818),
    midMtn: Color(0xFF884820),
    hill: Color(0xFF705028),
    tree: Color(0xFF4A3010),
    ground: Color(0xFF382008),
  ),
};

_RouteVisuals _visuFor(RouteModel r) =>
    _kVis[r.id] ??
    const _RouteVisuals(
      shortName: 'Journey',
      departure: 'ORIGIN',
      arrival: 'DESTINATION',
      distanceKm: 300,
      celestial: CelestialType.sun,
      isNight: false,
      particle: ParticleKind.none,
      sky: [Color(0xFF0C1620), Color(0xFF1E3C5A), Color(0xFF7AAFC8)],
      farMtn: Color(0xFF1E2E3C),
      midMtn: Color(0xFF172636),
      hill: Color(0xFF102E2A),
      tree: Color(0xFF081E16),
      ground: Color(0xFF061410),
    );

// ───────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ───────────────────────────────────────────────────────────────

abstract class _C {
  static const bg = Color(0xFF06070E);
  static const card = Color(0xFF0C0E18);
  static const surface = Color(0xFF111320);
  static const rim = Color(0xFF1C1F2E);
  static const copper = Color(0xFFB8824A);
  static const gold = Color(0xFFD4A855);
  static const goldLt = Color(0xFFEDCB80);
  static const goldDk = Color(0xFF7A5220);
  static const cream = Color(0xFFEDE6D8);
  static const muted = Color(0xFF706A5C);
  static const dim = Color(0xFF3E3A32);
  static const danger = Color(0xFFB83838);
}

// ───────────────────────────────────────────────────────────────
// FOCUS SCREEN
// ───────────────────────────────────────────────────────────────

class FocusScreen extends StatefulWidget {
  final RouteModel? route;
  final String? mood;
  final String? goal;
  final int? durationMinutes;

  const FocusScreen({
    super.key,
    this.route,
    this.mood,
    this.goal,
    this.durationMinutes,
  });

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // ── Session state ──────────────────────────────────────────
  late final RouteModel _route;
  late final _RouteVisuals _vis;
  late final String _goal;
  late final int _totalSec;
  late final DateTime _startTime;
  late int _remSec;
  Timer? _tick;
  bool _paused = false;
  bool _done = false;
  final Set<int> _shownMilestones = {};

  // ── Animation controllers ──────────────────────────────────
  late final AnimationController _scroll;
  late final AnimationController _glow;
  late final AnimationController _sway;
  late final AnimationController _cross;
  late final AnimationController _enter;
  late final AnimationController _flash;
  late final AnimationController _eqCtrl;

  late final Animation<double> _fadein;
  late final Animation<Offset> _slidein;

  final ValueNotifier<double> _progN = ValueNotifier(0);
  final ValueNotifier<int> _remSecNotifier = ValueNotifier(0);
  final _storage = StorageService();
  final _timerService = TimerService();

  // ── Sound state ────────────────────────────────────────────
  final _audio = AudioService();
  bool _soundPlaying = true; // Default to true as it auto-starts
  double _volume = 0.7;

  double get _prog => (1.0 - _remSec / _totalSec).clamp(0.0, 1.0);

  Color get _activeAccent =>
      _soundPlaying ? _kAmbientColor : _route.accentColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _route = widget.route ?? RouteModel.tokyoKyoto;
    _vis = _visuFor(_route);
    _goal = widget.goal ?? 'Deep focus session';
    _totalSec = (widget.durationMinutes ?? 25) * 60;
    _remSec = _totalSec;
    _startTime = DateTime.now();

    // DEBUG — remove after testing
    debugPrint(
      '🚂 Focus: duration=${widget.durationMinutes}min, totalSec=$_totalSec',
    );

    // Scenic controllers
    _scroll = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _sway = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _cross = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // EQ bars
    _eqCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _fadein = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _slidein = Tween<Offset>(
      begin: const Offset(0, .04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // Phase 8: Request notification permission on first use
    NotificationService.requestPermission();

    // Phase 8: Enable wakelock (screen stays on)
    WakelockService.enable();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _enter.forward();
      _startTimer();
      _scheduleCross();

      // Centralized Audio: Start ambient for this route
      _audio.playAmbient('sounds/Sleep.mp3');

      if (await Permission.accessNotificationPolicy.isDenied) {
        await Permission.accessNotificationPolicy.request();
      }

      // Phase 8: Start the background-safe timer and schedule notification
      _timerService.startSession(
        durationMinutes: widget.durationMinutes ?? 25,
        routeName: _route.name,
        routeEmoji: _route.emoji,
      );
    });
  }

  @override
  void dispose() {
    WakelockService.disable();
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _scroll.dispose();
    _glow.dispose();
    _sway.dispose();
    _cross.dispose();
    _enter.dispose();
    _flash.dispose();
    _eqCtrl.dispose();
    _progN.dispose();
    _remSecNotifier.dispose();
    super.dispose();
  }

  // ── App Lifecycle ──────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (!_paused) {
        _scroll.repeat();
        _sway.repeat(reverse: true);
      }

      // App came back from background.
      // Recalculate remaining time from wall clock.
      final remaining = _timerService.getRemainingSeconds();

      if (remaining <= 0 && !_done) {
        // Timer expired while app was in background!
        _endSession(completed: true);
      } else {
        // Update the displayed time to match reality.
        if (mounted) {
          setState(() {
            _remSec = remaining;
            _remSecNotifier.value = _remSec;
            _progN.value = _prog;
          });
        }
      }

      // Resume audio if it was playing
      if (!_paused) {
        _audio.resumeAmbient();
        if (mounted) setState(() => _soundPlaying = true);
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Pause animations to save battery
      if (!_paused) {
        _scroll.stop();
        _sway.stop();
      }

      // App going to background — pause audio
      _audio.pauseAmbient();
      if (mounted) setState(() => _soundPlaying = false);
      // Timer notification is already scheduled — it'll fire on time
    }
  }

  // ── Sound control (Updated to use AudioService) ────────────
  void _toggleSound() {
    HapticFeedback.lightImpact();
    if (_soundPlaying) {
      _audio.pauseAmbient();
      if (mounted) setState(() => _soundPlaying = false);
    } else {
      _audio.resumeAmbient();
      if (mounted) setState(() => _soundPlaying = true);
    }
  }

  // Volume slider left hooked up to state, assuming your AudioService
  // can be extended to accept local volume changes if needed, or
  // you can remove the volume slider from the UI later if it's redundant.
  void _setVolume(double v) {
    setState(() => _volume = v);
    // If your AudioService supports volume setting: _audio.setVolume(v);
  }

  // ── Timer ──────────────────────────────────────────────────

  void _scheduleCross() {
    Future.delayed(Duration(seconds: 10 + math.Random().nextInt(12)), () {
      if (!mounted) {
        return;
      }
      _cross.forward(from: 0).then((_) {
        if (mounted) {
          Future.delayed(const Duration(seconds: 18), _scheduleCross);
        }
      });
    });
  }

  void _startTimer() {
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused || _remSec <= 0) {
        return;
      }

      if (mounted) {
        setState(() {
          _remSec--;
          _remSecNotifier.value = _remSec;
          _progN.value = _prog;
        });
      }

      if (_remSec == 60 || _remSec == 10) {
        HapticFeedback.mediumImpact();
        if (mounted) _flash.forward(from: 0);
      }

      // Milestone toasts at 25%, 50%, 75%
      _checkMilestone();

      if (_remSec <= 0) {
        _endSession(completed: true);
      }
    });
  }

  void _checkMilestone() {
    final percent = ((_prog) * 100).round();
    const milestones = {
      25: '✦ Quarter way',
      50: '🚂 Halfway there',
      75: '✦ Almost arrived',
    };
    for (final entry in milestones.entries) {
      if (percent >= entry.key && !_shownMilestones.contains(entry.key)) {
        _shownMilestones.add(entry.key);
        HapticFeedback.selectionClick();
        _showMilestoneToast(entry.value);
        break;
      }
    }
  }

  void _showMilestoneToast(String message) {
    if (!mounted) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (_) => _MilestoneToast(
            message: message,
            accentColor: _route.accentColor,
            onDone: () {
              entry.remove();
            },
          ),
    );
    Overlay.of(context).insert(entry);
  }

  void _togglePause() {
    HapticFeedback.lightImpact();
    setState(() => _paused = !_paused);

    if (_paused) {
      _scroll.stop();
      _sway.stop();
      _audio.pauseAmbient();
      setState(() => _soundPlaying = false);
      _timerService.pause(); // Phase 8: Pause background timer
    } else {
      _scroll.repeat();
      _sway.repeat(reverse: true);
      _audio.resumeAmbient();
      setState(() => _soundPlaying = true);
      _timerService.resume(); // Phase 8: Resume + reschedule notif

      // Sync displayed time with background timer
      setState(() {
        _remSec = _timerService.getRemainingSeconds();
      });
    }
  }

  Future<void> _endSession({required bool completed}) async {
    if (_done) {
      return;
    }
    _done = true;
    _tick?.cancel();

    // Centralized Audio: Fade out gracefully
    await _audio.stopAmbient(fadeOut: true);

    // Phase 8: Clean up background timer + notifications + wakelock
    await _timerService.endSession();
    await WakelockService.disable();
    // Cancel streak warning since user completed a session
    if (completed) await NotificationService.cancelStreakWarning();

    if (completed) {
      _audio.playArrivalBell();
    }

    HapticFeedback.heavyImpact();
    final mins = ((_totalSec - _remSec) / 60).ceil().clamp(1, 9999);
    await _storage.saveSession(
      JourneySession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        routeName: _route.name,
        durationMinutes: mins,
        startTime: _startTime,
        completed: completed,
        mood: widget.mood,
        goal: _goal,
      ),
    );
    if (mounted) {
      context.go(
        AppRouter.arrival,
        extra: {
          'route': _route,
          'mood': widget.mood,
          'goal': _goal,
          'durationMinutes': widget.durationMinutes ?? 25,
          'actualMinutes': ((_totalSec - _remSec) / 60).ceil().clamp(1, 9999),
        },
      );
    }
  }

  void _showStop() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .92),
      builder:
          (_) => _StopDialog(
            onConfirm: () async {
              Navigator.pop(context);
              // Centralized Audio: Abrupt stop
              await _audio.stopAmbient(fadeOut: false);
              _endSession(completed: false);
            },
            onCancel: () => Navigator.pop(context),
          ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accent = _activeAccent;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated ambient glow behind everything ─────────
          Positioned.fill(
            child: RepaintBoundary(
              child: _AmbientGlow(ctrl: _glow, color: accent),
            ),
          ),

          // ── Star field (always visible) ─────────────────────
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _StarFieldPainter()),
            ),
          ),

          // ── Main content ────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),

                // Header — fade in first
                _buildHeader(accent)
                    .animate()
                    .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                    .slideY(begin: -0.15, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 8),

                // Window — scale + fade for cinematic reveal
                Expanded(
                  flex: 10,
                  child: _buildWindow()
                      .animate(delay: 150.ms)
                      .fadeIn(duration: 700.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1, 1),
                        duration: 700.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ),

                const SizedBox(height: 14),

                // Timer — slide up + fade
                _buildTimer()
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 10),

                // Journey map — slide from right
                JourneyMapWidget(
                  routeId: _route.id,
                  routeEmoji: _route.emoji,
                  distanceKm: _vis.distanceKm,
                  progress: _progN,
                  accentColor: accent,
                ).animate(delay: 400.ms)
                    .fadeIn(duration: 500.ms)
                    .slideX(begin: 0.08, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 12),

                // Sound panel — fade in
                _buildSoundPanel(accent)
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 10),

                // Controls — last to appear
                _buildControls(accent)
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Milestone flash overlay ─────────────────────────
          Positioned.fill(
            child: RepaintBoundary(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _flash,
                  builder: (_, __) {
                    final v = math.sin(_flash.value * math.pi).clamp(0.0, 1.0);
                    return v > 0
                        ? DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                accent.withValues(alpha: v * .18),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        )
                        : const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),

          // ── Vignette ────────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.1,
                    colors: [Colors.transparent, _C.bg.withValues(alpha: .55)],
                    stops: const [.35, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── Centralized Audio Control Button ────────────────
          const Positioned(
            top:
                54, // Adjusted slightly to sit beneath the top edge of SafeArea
            right: 16,
            child: AudioControlButton(),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // HEADER
  // ──────────────────────────────────────────────────────────

  Widget _buildHeader(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _Chip(
            color: accent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_route.emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 7),
                Text(
                  _vis.shortName.toUpperCase(),
                  style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // AudioControlButton will sit roughly here in the Stack
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SCENIC WINDOW
  // ──────────────────────────────────────────────────────────

  Widget _buildWindow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: _sway,
        builder: (_, child) {
          final s = math.sin(_sway.value * math.pi * 2);
          return Transform(
            transform:
                Matrix4.identity()
                  ..translate(0.0, s * 1.2, 0.0)
                  ..rotateZ(s * 0.0005),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: _C.copper.withValues(alpha: .48),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _activeAccent.withValues(alpha: .12),
                blurRadius: 36,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: .78),
                blurRadius: 50,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _scroll,
                    builder:
                        (_, __) => CustomPaint(
                          painter: _SkyPainter(vis: _vis, t: _scroll.value),
                        ),
                  ),
                ),
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _scroll,
                    builder:
                        (_, __) => CustomPaint(
                          painter: _LandscapePainter(
                            vis: _vis,
                            t: _scroll.value,
                            paused: _paused,
                          ),
                        ),
                  ),
                ),
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _scroll,
                    builder:
                        (_, __) => CustomPaint(
                          painter: _ParticlePainter(
                            vis: _vis,
                            t: _scroll.value,
                            paused: _paused,
                          ),
                        ),
                  ),
                ),
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_cross, _scroll]),
                    builder:
                        (_, __) => CustomPaint(
                          painter: _CrossingTrainPainter(
                            progress: _cross.value,
                            t: _scroll.value,
                            paused: _paused,
                          ),
                        ),
                  ),
                ),
                if (!_paused)
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _scroll,
                      builder:
                          (_, __) => CustomPaint(
                            painter: _SpeedLinePainter(t: _scroll.value),
                          ),
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: const Alignment(.3, .4),
                          colors: [
                            Colors.white.withValues(alpha: .06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 50,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            _C.bg.withValues(alpha: .30),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _FramePainter(accent: _activeAccent),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 9,
                  right: 12,
                  child: Text(
                    _vis.shortName,
                    style: GoogleFonts.spaceMono(
                      fontSize: 7,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w300,
                      color: _C.cream.withValues(alpha: .15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // TIMER
  // ──────────────────────────────────────────────────────────

  Widget _buildTimer() {
    return ValueListenableBuilder<int>(
      valueListenable: _remSecNotifier,
      builder: (_, remSec, __) {
        return Column(
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.cormorantGaramond(
                fontSize: 84,
                fontWeight: FontWeight.w200,
                letterSpacing: 10,
                height: 1.0,
                color: _paused ? _C.cream.withValues(alpha: .30) : _C.cream,
              ),
              child: Text(_formatTime(remSec)),
            ),
            const SizedBox(height: 3),
            Text(
              _paused ? 'journey paused' : 'remaining until arrival',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: _C.muted,
                letterSpacing: .6,
              ),
            ),
          ],
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────
  // PROGRESS RAIL
  // ──────────────────────────────────────────────────────────

  Widget _buildProgressRail(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (_, cst) {
          final w = cst.maxWidth;
          return Column(
            children: [
              Row(
                children: [
                  Text(
                    _vis.departure,
                    style: GoogleFonts.spaceMono(
                      fontSize: 7.5,
                      color: _C.muted,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _vis.arrival,
                    style: GoogleFonts.spaceMono(
                      fontSize: 7.5,
                      color: _C.muted,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 22,
                child: ValueListenableBuilder<double>(
                  valueListenable: _progN,
                  builder:
                      (_, p, __) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          CustomPaint(
                            size: Size(w, 22),
                            painter: _TrackPainter(),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                            width: (w * p).clamp(0.0, w),
                            height: 5,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_C.copper, accent],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: .60),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                            left: (w * p - 10).clamp(0.0, w - 20),
                            top: 0,
                            child: _TrainPip(color: accent),
                          ),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<double>(
                valueListenable: _progN,
                builder:
                    (_, p, __) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(p * _vis.distanceKm).round()} km',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: accent,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${_vis.distanceKm} km total',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            color: _C.dim,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SOUND PANEL — Play/stop tied to _audio service now
  // ──────────────────────────────────────────────────────────

  Widget _buildSoundPanel(Color accent) {
    final playing = _soundPlaying;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: playing ? _kAmbientColor.withValues(alpha: .10) : _C.card,
          border: Border.all(
            color: playing ? _kAmbientColor.withValues(alpha: .45) : _C.rim,
            width: playing ? 1.5 : 1,
          ),
          boxShadow:
              playing
                  ? [
                    BoxShadow(
                      color: _kAmbientColor.withValues(alpha: .18),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleSound,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      playing
                          ? _kAmbientColor.withValues(alpha: .20)
                          : _C.surface,
                  border: Border.all(
                    color:
                        playing
                            ? _kAmbientColor.withValues(alpha: .60)
                            : _C.rim,
                  ),
                ),
                child: Center(
                  child: Icon(
                    playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: playing ? _kAmbientColor : _C.muted,
                    size: 22,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('🌙', style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        'AMBIENT SOUND',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: playing ? _kAmbientColor : _C.muted,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: playing ? 6 : 0,
                        height: playing ? 6 : 0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kAmbientColor,
                          boxShadow:
                              playing
                                  ? [
                                    BoxShadow(
                                      color: _kAmbientColor.withValues(
                                        alpha: .8,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ]
                                  : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  AnimatedBuilder(
                    animation: _eqCtrl,
                    builder: (_, __) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(10, (i) {
                          final phase = i * (math.pi * 2 / 10);
                          final speed = _kAmbientEqSpeeds[i % 5];
                          final raw = math.sin(
                            _eqCtrl.value * math.pi * 2 * speed + phase,
                          );
                          final h =
                              playing ? 4.0 + (raw * .5 + .5) * 18.0 : 3.0;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 3,
                            height: h,
                            decoration: BoxDecoration(
                              color:
                                  playing
                                      ? _kAmbientColor.withValues(
                                        alpha: .40 + (raw * .5 + .5) * .55,
                                      )
                                      : _C.rim,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            SizedBox(
              width: 72,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 5,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: playing ? _kAmbientColor : _C.dim,
                  inactiveTrackColor: _C.rim,
                  thumbColor: playing ? _kAmbientColor : _C.muted,
                ),
                child: Slider(
                  value: _volume,
                  min: 0,
                  max: 1,
                  onChanged: _setVolume,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // CONTROLS
  // ──────────────────────────────────────────────────────────

  Widget _buildControls(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _PressBtn(
              onTap: _togglePause,
              accent: accent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: _C.cream,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _paused ? 'RESUME' : 'PAUSE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _C.cream,
                      letterSpacing: 2.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _PressBtn(
            onTap: _showStop,
            fixedWidth: 56,
            accent: _C.danger,
            bg: _C.danger.withValues(alpha: .12),
            border: _C.danger.withValues(alpha: .40),
            child: const Icon(Icons.stop_rounded, color: _C.danger, size: 24),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// UI PAINTERS & WIDGETS (Unchanged from original)
// ═══════════════════════════════════════════════════════════════

class _AmbientGlow extends StatelessWidget {
  final AnimationController ctrl;
  final Color color;
  const _AmbientGlow({required this.ctrl, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder:
          (_, __) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -.50),
                radius: 1.65,
                colors: [
                  color.withValues(alpha: .04 + ctrl.value * .07),
                  Colors.transparent,
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  static final _stars = List.generate(65, (i) {
    final r = math.Random(i * 17 + 3);
    return (
      x: r.nextDouble(),
      y: r.nextDouble() * .65,
      rad: .4 + r.nextDouble() * 1.1,
      a: .08 + r.nextDouble() * .35,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final s in _stars) {
      p.color = Colors.white.withValues(alpha: s.a);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.rad, p);
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter _) => false;
}

class _SkyPainter extends CustomPainter {
  final _RouteVisuals vis;
  final double t;
  const _SkyPainter({required this.vis, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          vis.sky,
          List.generate(vis.sky.length, (i) => i / (vis.sky.length - 1)),
        ),
    );
    if (vis.isNight) {
      _stars(canvas, size, _isLowEnd ? 40 : 80);
    }
    _celestial(canvas, size);
    if (vis.particle == ParticleKind.firefly) {
      _aurora(canvas, size);
    }
  }

  void _stars(Canvas canvas, Size size, int count) {
    final rng = math.Random(42);
    for (int i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(
          rng.nextDouble() * size.width,
          rng.nextDouble() * size.height * .62,
        ),
        .5 + rng.nextDouble() * 1.1,
        Paint()
          ..color = Colors.white.withValues(
            alpha: .18 + rng.nextDouble() * .58,
          ),
      );
    }
  }

  void _celestial(Canvas canvas, Size size) {
    final cx = size.width * .73;
    final cy =
        size.height * .22 + math.sin(t * math.pi * 2) * size.height * .016;

    switch (vis.celestial) {
      case CelestialType.sun:
        canvas.drawCircle(
          Offset(cx, cy),
          62,
          Paint()
            ..shader = ui.Gradient.radial(Offset(cx, cy), 62, [
              const Color(0xFFFFE060).withValues(alpha: .16),
              Colors.transparent,
            ]),
        );
        canvas.drawCircle(
          Offset(cx, cy),
          38,
          Paint()
            ..shader = ui.Gradient.radial(Offset(cx, cy), 38, [
              const Color(0xFFFFEE80).withValues(alpha: .28),
              Colors.transparent,
            ]),
        );
        canvas.drawCircle(
          Offset(cx, cy),
          24,
          Paint()
            ..shader = ui.Gradient.radial(
              Offset(cx, cy),
              24,
              [
                const Color(0xFFFFFDE8),
                const Color(0xFFFFD848),
                const Color(0xFFFF8800).withValues(alpha: 0),
              ],
              [0, .55, 1],
            ),
        );

      case CelestialType.moon:
        canvas.drawCircle(
          Offset(cx, cy),
          44,
          Paint()
            ..shader = ui.Gradient.radial(Offset(cx, cy), 44, [
              Colors.white.withValues(alpha: .10),
              Colors.transparent,
            ]),
        );
        canvas.drawCircle(
          Offset(cx, cy),
          22,
          Paint()
            ..shader = ui.Gradient.radial(Offset(cx, cy), 22, [
              const Color(0xFFF5F3EF),
              const Color(0xFFCCCBC4),
            ]),
        );
        canvas.drawCircle(
          Offset(cx + 7, cy - 5),
          5.0,
          Paint()..color = Colors.black.withValues(alpha: .07),
        );
        canvas.drawCircle(
          Offset(cx - 6, cy + 6),
          3.0,
          Paint()..color = Colors.black.withValues(alpha: .06),
        );

      case CelestialType.none:
        break;
    }
  }

  void _aurora(Canvas canvas, Size size) {
    for (int b = 0; b < 5; b++) {
      final baseY = 12.0 + b * 18;
      final path = Path()..moveTo(0, baseY);
      for (double x = 0; x <= size.width; x += 3) {
        path.lineTo(
          x,
          baseY +
              math.sin(x / 28 + t * math.pi * 2 + b * .8) * 11 +
              math.sin(x / 52 + t * math.pi * 2.4) * 6,
        );
      }
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(0, baseY + 30),
            [
              Colors.transparent,
              const Color(0xFF40D4BE).withValues(alpha: .10 - b * .016),
              Colors.transparent,
            ],
            [0, .55, 1],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_SkyPainter o) => o.t != t;
}

class _LandscapePainter extends CustomPainter {
  final _RouteVisuals vis;
  final double t;
  final bool paused;

  static const double kRailTop = 12.0;
  static const double kGroundH = 24.0;

  const _LandscapePainter({
    required this.vis,
    required this.t,
    required this.paused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final at = paused ? 0.0 : t;
    _mtns(canvas, size, at, .06, .30, .26, 11, vis.farMtn);
    _mtns(canvas, size, at, .15, .24, .42, 22, vis.midMtn);
    _hills(canvas, size, at, .32, .18, 31, vis.hill);
    _trees(canvas, size, at, vis.tree);
    _foreground(canvas, size, at, vis.ground);
  }

  void _mtns(
    Canvas canvas,
    Size size,
    double t,
    double speed,
    double hFrac,
    double opacity,
    int seed,
    Color col,
  ) {
    final rng = math.Random(seed);
    final off = (t * speed * size.width * 2) % (size.width * 2);
    final path = Path()..moveTo(-off - size.width, size.height);
    double x = -off - size.width;
    while (x < size.width * 2.6) {
      final ph = size.height * (.16 + rng.nextDouble() * hFrac);
      final px = x + 55 + rng.nextDouble() * 95;
      path.lineTo(px, size.height - ph);
      x = px + 50 + rng.nextDouble() * 80;
      path.lineTo(x, size.height - rng.nextDouble() * 20);
    }
    path.lineTo(size.width * 2.6, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = col.withValues(alpha: opacity));
  }

  void _hills(
    Canvas canvas,
    Size size,
    double t,
    double speed,
    double hFrac,
    int seed,
    Color col,
  ) {
    final rng = math.Random(seed);
    final off = (t * speed * size.width * 3.5) % (size.width * 2.5);
    final path = Path()..moveTo(-off - 90, size.height);
    for (double x = -off - 90; x < size.width + 130; x += 48) {
      final y = size.height - (16 + rng.nextDouble() * size.height * hFrac);
      path.quadraticBezierTo(
        x + 24,
        y - 10 - rng.nextDouble() * 16,
        x + 48,
        y + rng.nextDouble() * 14,
      );
    }
    path.lineTo(size.width + 130, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = col.withValues(alpha: .84));
  }

  void _trees(Canvas canvas, Size size, double t, Color col) {
    final rng = math.Random(50);
    final off = (t * .58 * size.width * 4) % (size.width * 3);
    final p = Paint()..color = col.withValues(alpha: .92);
    for (
      double x = -off;
      x < size.width + 90;
      x += 30 + rng.nextDouble() * 22
    ) {
      final h = 30 + rng.nextDouble() * 24;
      final by = size.height - kGroundH;
      canvas.drawRect(Rect.fromLTWH(x - 1.5, by - h * .38, 3, h * .38), p);
      canvas.drawPath(
        Path()
          ..moveTo(x, by - h)
          ..lineTo(x - 9 - rng.nextDouble() * 5, by - h * .38)
          ..lineTo(x + 9 + rng.nextDouble() * 5, by - h * .38)
          ..close(),
        p,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x, by - h * .70)
          ..lineTo(x - 11 - rng.nextDouble() * 5, by - h * .24)
          ..lineTo(x + 11 + rng.nextDouble() * 5, by - h * .24)
          ..close(),
        p,
      );
    }
  }

  void _foreground(Canvas canvas, Size size, double t, Color col) {
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - kGroundH, size.width, kGroundH),
      Paint()..color = col,
    );
    final pOff = (t * size.width * 6) % 210;
    final polePaint = Paint()..color = col.withValues(alpha: .88);
    final wirePaint =
        Paint()
          ..color = col.withValues(alpha: .55)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
    for (double x = -pOff; x < size.width + 110; x += 210) {
      canvas.drawRect(
        Rect.fromLTWH(x - 1.5, size.height - kGroundH - 44, 3, 44),
        polePaint,
      );
      canvas.drawLine(
        Offset(x - 18, size.height - kGroundH - 39),
        Offset(x + 21, size.height - kGroundH - 39),
        wirePaint..strokeWidth = 2.2,
      );
      canvas.drawLine(
        Offset(x + 19, size.height - kGroundH - 38),
        Offset(x + 192, size.height - kGroundH - 33),
        wirePaint..strokeWidth = 1.1,
      );
      canvas.drawCircle(
        Offset(x - 17, size.height - kGroundH - 39),
        2.0,
        Paint()..color = col.withValues(alpha: .70),
      );
      canvas.drawCircle(
        Offset(x + 20, size.height - kGroundH - 39),
        2.0,
        Paint()..color = col.withValues(alpha: .70),
      );
    }
    final rPaint =
        Paint()
          ..color = col.withValues(alpha: .55)
          ..strokeWidth = 2.5;
    canvas.drawLine(
      Offset(0, size.height - kRailTop),
      Offset(size.width, size.height - kRailTop),
      rPaint,
    );
    canvas.drawLine(
      Offset(0, size.height - kRailTop - 6),
      Offset(size.width, size.height - kRailTop - 6),
      rPaint,
    );
    final sOff = (t * size.width * 8) % 24;
    final sPaint = Paint()..color = col.withValues(alpha: .30);
    for (double x = -sOff; x < size.width + 24; x += 24) {
      canvas.drawRect(
        Rect.fromLTWH(x - 1, size.height - kRailTop - 7, 2, 12),
        sPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LandscapePainter o) => o.t != t || o.paused != paused;
}

class _ParticlePainter extends CustomPainter {
  final _RouteVisuals vis;
  final double t;
  final bool paused;
  const _ParticlePainter({
    required this.vis,
    required this.t,
    required this.paused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (paused) {
      return;
    }
    switch (vis.particle) {
      case ParticleKind.blossom:
        _blossom(canvas, size);
        break;
      case ParticleKind.snow:
        _snow(canvas, size);
        break;
      case ParticleKind.firefly:
        _firefly(canvas, size);
        break;
      case ParticleKind.sand:
        _sand(canvas, size);
        break;
      case ParticleKind.none:
        break;
    }
  }

  void _blossom(Canvas canvas, Size size) {
    final rng = math.Random(77);
    final p = Paint();
    final count = _isLowEnd ? 14 : 28;
    for (int i = 0; i < count; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = rng.nextDouble() * size.height * .75;
      final drft = math.sin(t * math.pi * 2 + i * .4) * 22;
      final fall =
          (t * rng.nextDouble() * size.height * .6 + i * (size.height / 28)) %
          size.height;
      final px = (bx + drft + t * 68) % (size.width + 30) - 15;
      final py = (by + fall) % size.height;
      final r = 2.0 + rng.nextDouble() * 2.5;
      p.color = const Color(
        0xFFFFB8C6,
      ).withValues(alpha: .25 + rng.nextDouble() * .45);
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(t * math.pi * 4 + i.toDouble());
      for (int j = 0; j < 4; j++) {
        canvas.save();
        canvas.rotate(j * math.pi / 2);
        canvas.drawOval(Rect.fromLTWH(-r * .5, -r, r, r * 1.8), p);
        canvas.restore();
      }
      canvas.restore();
    }
  }

  void _snow(Canvas canvas, Size size) {
    final rng = math.Random(99);
    final count = _isLowEnd ? 18 : 36;
    for (int i = 0; i < count; i++) {
      final bx = rng.nextDouble() * size.width;
      final speed = .25 + rng.nextDouble() * .60;
      final drft = math.sin(t * math.pi * 2.5 + i * .6) * 14;
      final fall =
          (t * speed * size.height * 2.2 + i * (size.height / 36)) %
          (size.height + 40);
      final r = 1.2 + rng.nextDouble() * 2.0;
      final sp =
          Paint()
            ..color = Colors.white.withValues(
              alpha: .35 + rng.nextDouble() * .45,
            )
            ..strokeWidth = r * .55
            ..style = PaintingStyle.stroke;
      canvas.save();
      canvas.translate(bx + drft, fall - 20);
      canvas.rotate(t * math.pi * 3 + i.toDouble());
      for (int arm = 0; arm < 6; arm++) {
        canvas.drawLine(Offset.zero, Offset(0, -r * 2.2), sp);
        canvas.rotate(math.pi / 3);
      }
      canvas.restore();
    }
  }

  void _firefly(Canvas canvas, Size size) {
    final rng = math.Random(55);
    final count = _isLowEnd ? 11 : 22;
    for (int i = 0; i < count; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = rng.nextDouble() * size.height * .55;
      final drft = math.sin(t * math.pi * 1.5 + i * .5) * 32;
      final px = (bx + drft) % (size.width + 40) - 20;
      final py = (by + math.cos(t * math.pi + i) * 16) % size.height;
      final a = (math.sin(t * math.pi * 3 + i * 1.2) * .5 + .5) * .65;
      final r = 1.5 + rng.nextDouble() * 2;
      canvas.drawCircle(
        Offset(px, py),
        r * 4,
        Paint()
          ..shader = ui.Gradient.radial(Offset(px, py), r * 4, [
            const Color(0xFF40D4BE).withValues(alpha: a),
            Colors.transparent,
          ]),
      );
      canvas.drawCircle(
        Offset(px, py),
        r,
        Paint()..color = const Color(0xFF40D4BE).withValues(alpha: a),
      );
    }
  }

  void _sand(Canvas canvas, Size size) {
    final rng = math.Random(33);
    final lp = Paint()..style = PaintingStyle.stroke;
    final count = _isLowEnd ? 28 : 55;
    for (int i = 0; i < count; i++) {
      final by = rng.nextDouble() * size.height;
      final speed = 1.5 + rng.nextDouble() * 2.5;
      final px =
          size.width -
          ((t * speed * size.width * 4 + i * (size.width / 55)) %
              (size.width + 60));
      final py = by + math.sin(t * math.pi * 3 + i) * 6;
      final len = 4.0 + rng.nextDouble() * 18;
      lp.color = const Color(
        0xFFC8A050,
      ).withValues(alpha: .09 + rng.nextDouble() * .30);
      lp.strokeWidth = .8 + rng.nextDouble() * 1.2;
      canvas.drawLine(Offset(px, py), Offset(px + len, py), lp);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter o) => o.t != t || o.paused != paused;
}

class _CrossingTrainPainter extends CustomPainter {
  final double progress;
  final double t;
  final bool paused;

  const _CrossingTrainPainter({
    required this.progress,
    required this.t,
    required this.paused,
  });

  static const _body = Color(0xFF1E1B17);
  static const _bodyHi = Color(0xFF332E28);
  static const _brass = Color(0xFFB8822A);
  static const _brassLt = Color(0xFFD4A845);
  static const _red = Color(0xFF8B1A1A);
  static const _redLt = Color(0xFFAA2828);
  static const _wheel = Color(0xFF252018);
  static const _spoke = Color(0xFF4A4438);
  static const _smoke = Color(0xFFB8B0A0);
  static const _fire = Color(0xFFFF6820);
  static const _win = Color(0xFFFFB040);

  static const double _bcy = -36.0;
  static const double _br = 17.0;

  static const double _cabX = 0.0;
  static const double _cabW = 54.0;
  static const double _cabTop = -70.0;
  static const double _cabBot = -16.0;

  static const double _boilX = -_cabW;
  static const double _boilW = 138.0;
  static const double _boilLeft = -_cabW - _boilW;

  static const double _sbX = _boilLeft;
  static const double _sbW = 26.0;
  static const double _sbLeft = _sbX - _sbW;

  static const double _cowX = _sbLeft;

  static const double _stackX = _sbX + _boilW * .22;
  static const double _stackBot = _bcy - _br;
  static const double _stackH = 32.0;
  static const double _stackR1 = 5.5;
  static const double _stackR2 = 9.0;

  static const double _sdX = _sbX + _boilW * .42;
  static const double _sdR = 11.0;
  static const double _sdBot = _bcy - _br;

  static const double _sanX = _sbX + _boilW * .60;
  static const double _sanR = 8.0;

  static const double _drW = 22.0;
  static const double _dw1 = _sbX + _boilW * .18;
  static const double _dw2 = _sbX + _boilW * .48;
  static const double _dw3 = _sbX + _boilW * .76;

  static const double _ltW = 12.0;
  static const double _ltX = _sbLeft - 10;

  static const double _ttW = 13.0;
  static const double _ttX = _cabX - _cabW * .35;

  static const double _tenW = 90.0;
  static const double _tenTop = -54.0;
  static const double _tenBot = -16.0;

  static const double _totalW = _cabW + _boilW + _sbW + 16 + _tenW + 10;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= .001 || progress >= .999) {
      return;
    }

    final e = Curves.easeInOut.transform(progress);
    final tx = (size.width + 40) - e * (size.width + _totalW + 80);
    final ty = size.height - _LandscapePainter.kRailTop;

    canvas.save();
    canvas.translate(tx, ty);
    _drawTrain(canvas, size);
    canvas.restore();
  }

  void _drawTrain(Canvas canvas, Size size) {
    final wheelAngle = paused ? 0.0 : t * math.pi * 2 * 18;
    final fireAlpha =
        paused ? 0.12 : 0.12 + math.sin(t * math.pi * 2 * 6) * 0.06;

    _drawTender(canvas);
    _drawCab(canvas, fireAlpha);
    _drawBoiler(canvas);
    _drawSmokebox(canvas);
    _drawRunningBoard(canvas);
    _drawCylinder(canvas, wheelAngle);
    _drawCowcatcher(canvas);
    _drawDriveWheels(canvas, wheelAngle);
    _drawLeadingTruck(canvas, wheelAngle);
    _drawTrailingTruck(canvas, wheelAngle);
    _drawStack(canvas);
    _drawDomes(canvas);
    _drawHandrail(canvas);
    _drawHeadlamp(canvas);
    _drawSmoke(canvas);
    _drawFireglow(canvas, fireAlpha);
  }

  void _drawTender(Canvas canvas) {
    final double tx = _cabX + 6;

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(tx, _tenTop, _tenW, _tenBot - _tenTop),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
        bottomLeft: Radius.zero,
        bottomRight: Radius.zero,
      ),
      Paint()..color = _body,
    );
    canvas.drawRect(
      Rect.fromLTWH(tx, _tenTop, _tenW, 3),
      Paint()..color = _bodyHi,
    );
    canvas.drawRect(
      Rect.fromLTWH(tx, _tenTop + 8, _tenW, 6),
      Paint()..color = _red,
    );
    canvas.drawRect(
      Rect.fromLTWH(tx, _tenBot - 14, _tenW, 2),
      Paint()..color = _brass,
    );
    final coal =
        Path()
          ..moveTo(tx + 4, _tenTop)
          ..quadraticBezierTo(tx + 22, _tenTop - 8, tx + 38, _tenTop - 5)
          ..quadraticBezierTo(tx + 55, _tenTop - 11, tx + 68, _tenTop - 6)
          ..quadraticBezierTo(tx + 80, _tenTop - 4, tx + _tenW - 4, _tenTop)
          ..close();
    canvas.drawPath(coal, Paint()..color = const Color(0xFF141210));

    final twR = 10.0;
    final wheelAngle = paused ? 0.0 : t * math.pi * 2 * 14;
    for (final wx in [tx + 14.0, tx + 36.0, tx + 58.0, tx + 78.0]) {
      _drawSpokedWheel(canvas, wx, -twR, twR, 6, wheelAngle);
    }

    canvas.drawRect(
      Rect.fromLTWH(tx - 1, _tenBot - 10, 3, 7),
      Paint()..color = const Color(0xFF0E0C0A),
    );
  }

  void _drawCab(Canvas canvas, double fireAlpha) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          _cabX - _cabW,
          _cabTop,
          _cabW,
          _cabTop.abs() + _cabBot.abs(),
        ),
        const Radius.circular(2),
      ),
      Paint()..color = _body,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(_cabX - _cabW - 2, _cabTop - 6, _cabW + 4, 8),
        const Radius.circular(4),
      ),
      Paint()..color = _bodyHi,
    );

    canvas.drawRect(
      Rect.fromLTWH(_cabX - _cabW, _cabTop + 6, _cabW, 5),
      Paint()..color = _red,
    );

    canvas.drawRect(
      Rect.fromLTWH(_cabX - _cabW, _cabBot - 4, _cabW, 3),
      Paint()..color = _brass,
    );

    for (final wox in [_cabX - _cabW + 8.0, _cabX - _cabW + 28.0]) {
      final winRect = Rect.fromLTWH(wox, _cabTop + 14, 16, 20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(winRect, const Radius.circular(3)),
        Paint()..color = _win.withValues(alpha: .55),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(winRect.inflate(3), const Radius.circular(5)),
        Paint()
          ..color = _win.withValues(alpha: .14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(winRect, const Radius.circular(3)),
        Paint()
          ..color = _brass.withValues(alpha: .6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    final wx = _cabX - _cabW + 18.0;
    canvas.drawRect(
      Rect.fromLTWH(wx, _cabTop - 12, 2.5, 10),
      Paint()..color = _brass,
    );
    canvas.drawOval(
      Rect.fromLTWH(wx - 2, _cabTop - 14, 6.5, 4),
      Paint()..color = _brassLt,
    );

    canvas.drawCircle(
      Offset(_cabX - _cabW - 2, _cabBot - 10),
      18,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(_cabX - _cabW - 2, _cabBot - 10),
          18,
          [_fire.withValues(alpha: fireAlpha * 1.5), Colors.transparent],
        ),
    );
  }

  void _drawBoiler(Canvas canvas) {
    final boilerRect = Rect.fromLTWH(_boilLeft, _bcy - _br, _boilW, _br * 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boilerRect, const Radius.circular(3)),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(_boilLeft, _bcy - _br),
          Offset(_boilLeft, _bcy + _br),
          [_bodyHi, _body, const Color(0xFF141210)],
          [0.0, 0.42, 1.0],
        ),
    );

    final bandP =
        Paint()
          ..color = _brass.withValues(alpha: .55)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    for (double bx = _boilLeft + 28; bx < _boilLeft + _boilW - 10; bx += 28) {
      canvas.drawLine(
        Offset(bx, _bcy - _br + 2),
        Offset(bx, _bcy + _br - 2),
        bandP,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(_boilLeft + 4, _bcy - _br, _boilW - 8, 5),
        const Radius.circular(2),
      ),
      Paint()..color = _bodyHi.withValues(alpha: .7),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(_boilLeft + 4, _bcy + _br - 5, _boilW - 8, 5),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.black.withValues(alpha: .4),
    );
  }

  void _drawSmokebox(Canvas canvas) {
    final sbCy = _bcy;
    final sbR = _br + 3.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(_sbLeft, sbCy - sbR, _sbW, sbR * 2),
        const Radius.circular(2),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(_sbLeft, sbCy - sbR),
          Offset(_sbLeft, sbCy + sbR),
          [_bodyHi, _body, Colors.black.withValues(alpha: .8)],
          [0.0, 0.38, 1.0],
        ),
    );

    canvas.drawCircle(
      Offset(_sbLeft, sbCy),
      sbR,
      Paint()..color = const Color(0xFF181510),
    );
    canvas.drawCircle(
      Offset(_sbLeft, sbCy),
      sbR,
      Paint()
        ..color = _brass.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawCircle(
      Offset(_sbLeft, sbCy),
      3.5,
      Paint()
        ..shader = ui.Gradient.radial(Offset(_sbLeft - 1, sbCy - 1), 2.5, [
          _brassLt,
          _brass,
        ]),
    );

    final defP = Paint()..color = _body;
    canvas.drawPath(
      Path()
        ..moveTo(_sbLeft + 2, sbCy - sbR)
        ..lineTo(_sbLeft + 2, sbCy - sbR - 10)
        ..lineTo(_sbX - 4, _bcy - _br - 4)
        ..lineTo(_sbX - 4, _bcy - _br)
        ..close(),
      defP,
    );
    canvas.drawLine(
      Offset(_sbLeft + 2, sbCy - sbR - 10),
      Offset(_sbX - 4, _bcy - _br - 4),
      Paint()
        ..color = _brass.withValues(alpha: .45)
        ..strokeWidth = 1.0,
    );
  }

  void _drawRunningBoard(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(_boilLeft, _bcy + _br, _boilW + _cabW, 4),
      Paint()..color = _bodyHi,
    );
    canvas.drawRect(
      Rect.fromLTWH(_boilLeft, _bcy + _br + 4, _boilW + _cabW, 2),
      Paint()..color = _brass.withValues(alpha: .35),
    );
  }

  void _drawCylinder(Canvas canvas, double wheelAngle) {
    const cxBase = _sbLeft + 6.0;
    const cyBase = _bcy + _br - 4.0;
    const cLen = 28.0;
    const cH = 10.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cxBase - cLen, cyBase, cLen, cH),
        const Radius.circular(3),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cxBase - cLen, cyBase),
          Offset(cxBase - cLen, cyBase + cH),
          [_bodyHi, _body],
        ),
    );

    canvas.drawOval(
      Rect.fromLTWH(cxBase - cLen - 4, cyBase + 1, 8, cH - 2),
      Paint()..color = _brass.withValues(alpha: .70),
    );

    final pistonX = math.sin(wheelAngle) * 5;
    canvas.drawLine(
      Offset(cxBase, cyBase + cH / 2),
      Offset(_dw1 - 8 + pistonX, -_drW + 4),
      Paint()
        ..color = _spoke
        ..strokeWidth = 2.0,
    );

    if (!paused) {
      final wp =
          Paint()
            ..color = _smoke.withValues(alpha: .18)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;
      for (int i = 0; i < 3; i++) {
        final phase = t * math.pi * 2 * 4 + i * 0.9;
        canvas.drawLine(
          Offset(cxBase - cLen - 4, cyBase + 3 + i * 2.5),
          Offset(
            cxBase - cLen - 4 - 5 - math.sin(phase) * 3,
            cyBase + 3 + i * 2.5 - 4,
          ),
          wp,
        );
      }
    }
  }

  void _drawCowcatcher(Canvas canvas) {
    final sbLeft = _sbLeft;
    final railY = 0.0;
    final topY = _bcy + _br + 6;

    final cowP =
        Paint()
          ..color = _brass.withValues(alpha: .80)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    canvas.drawPath(
      Path()
        ..moveTo(sbLeft, topY)
        ..lineTo(sbLeft - 18, railY)
        ..lineTo(sbLeft - 10, railY)
        ..lineTo(sbLeft, topY + 4)
        ..close(),
      Paint()..color = _body,
    );

    for (int i = 0; i < 4; i++) {
      final frac = i / 3.0;
      canvas.drawLine(
        Offset(sbLeft - 1, topY + frac * 4),
        Offset(sbLeft - 4 - frac * 14, railY),
        cowP,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(sbLeft - 20, -2, 10, 4),
      Paint()..color = _brass,
    );
  }

  void _drawDriveWheels(Canvas canvas, double wheelAngle) {
    for (final wx in [_dw1, _dw2, _dw3]) {
      _drawSpokedWheel(canvas, wx, -_drW, _drW, 8, wheelAngle);
    }

    final rodY = -_drW * 0.72;
    final rodP =
        Paint()
          ..color = _spoke
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(_dw1, rodY), Offset(_dw3, rodY), rodP);

    canvas.drawLine(
      Offset(_dw1, rodY - 1),
      Offset(_dw3, rodY - 1),
      Paint()
        ..color = _bodyHi.withValues(alpha: .5)
        ..strokeWidth = 1.5,
    );
  }

  void _drawLeadingTruck(Canvas canvas, double wheelAngle) {
    _drawSpokedWheel(canvas, _ltX, -_ltW, _ltW, 6, wheelAngle * .8);
    _drawSpokedWheel(canvas, _ltX - 26, -_ltW, _ltW, 6, wheelAngle * .8);
  }

  void _drawTrailingTruck(Canvas canvas, double wheelAngle) {
    _drawSpokedWheel(canvas, _ttX, -_ttW, _ttW, 6, wheelAngle * .9);
  }

  void _drawStack(Canvas canvas) {
    final tube =
        Path()
          ..moveTo(_stackX - _stackR1, _stackBot)
          ..lineTo(_stackX - _stackR1, _stackBot - _stackH * .75)
          ..quadraticBezierTo(
            _stackX - _stackR1 - 2,
            _stackBot - _stackH,
            _stackX - _stackR2,
            _stackBot - _stackH,
          )
          ..lineTo(_stackX + _stackR2, _stackBot - _stackH)
          ..quadraticBezierTo(
            _stackX + _stackR1 + 2,
            _stackBot - _stackH,
            _stackX + _stackR1,
            _stackBot - _stackH * .75,
          )
          ..lineTo(_stackX + _stackR1, _stackBot)
          ..close();
    canvas.drawPath(tube, Paint()..color = _body);

    canvas.drawOval(
      Rect.fromLTWH(
        _stackX - _stackR2 - 2,
        _stackBot - _stackH - 5,
        (_stackR2 + 2) * 2,
        10,
      ),
      Paint()..color = _bodyHi,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        _stackX - _stackR1 - 1,
        _stackBot - 4,
        (_stackR1 + 1) * 2,
        4,
      ),
      Paint()..color = _brass.withValues(alpha: .70),
    );
  }

  void _drawDomes(Canvas canvas) {
    final sdTop = _sdBot - _sdR - 12;
    canvas.drawPath(
      Path()
        ..moveTo(_sdX - _sdR, _sdBot)
        ..quadraticBezierTo(_sdX - _sdR, sdTop, _sdX, sdTop - 2)
        ..quadraticBezierTo(_sdX + _sdR, sdTop, _sdX + _sdR, _sdBot)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(_sdX - _sdR, sdTop),
          Offset(_sdX + _sdR, sdTop),
          [_bodyHi, _body],
        ),
    );
    canvas.drawRect(
      Rect.fromLTWH(_sdX - _sdR, _sdBot - 4, _sdR * 2, 4),
      Paint()..color = _brass.withValues(alpha: .75),
    );
    for (final vx in [_sdX - 3.0, _sdX + 3.0]) {
      canvas.drawRect(
        Rect.fromLTWH(vx - 1, sdTop - 7, 2, 7),
        Paint()..color = _brass,
      );
      canvas.drawOval(
        Rect.fromLTWH(vx - 2.5, sdTop - 9, 5, 3),
        Paint()..color = _brassLt,
      );
    }

    final sanTop = _sdBot - _sanR - 8;
    canvas.drawPath(
      Path()
        ..moveTo(_sanX - _sanR, _sdBot)
        ..quadraticBezierTo(_sanX - _sanR, sanTop, _sanX, sanTop - 1)
        ..quadraticBezierTo(_sanX + _sanR, sanTop, _sanX + _sanR, _sdBot)
        ..close(),
      Paint()..color = _bodyHi,
    );
    canvas.drawRect(
      Rect.fromLTWH(_sanX - _sanR, _sdBot - 3, _sanR * 2, 3),
      Paint()..color = _brass.withValues(alpha: .60),
    );
  }

  void _drawHandrail(Canvas canvas) {
    final railP =
        Paint()
          ..color = _brass.withValues(alpha: .55)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(_boilLeft + 10, _bcy - _br + 5),
      Offset(_boilLeft + _boilW - 4, _bcy - _br + 5),
      railP,
    );
    for (double sx = _boilLeft + 14; sx < _boilLeft + _boilW - 4; sx += 30) {
      canvas.drawLine(
        Offset(sx, _bcy - _br + 5),
        Offset(sx, _bcy + _br + 4),
        railP,
      );
    }
  }

  void _drawHeadlamp(Canvas canvas) {
    final lx = _sbLeft - 2;
    final ly = _bcy - 8;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(lx - 9, ly - 9, 11, 16),
        const Radius.circular(2),
      ),
      Paint()..color = _brass,
    );
    canvas.drawCircle(
      Offset(lx - 4, ly),
      5,
      Paint()
        ..shader = ui.Gradient.radial(Offset(lx - 3, ly - 1), 3, [
          Colors.white.withValues(alpha: .95),
          _win,
        ]),
    );
    canvas.drawCircle(
      Offset(lx - 4, ly),
      18,
      Paint()
        ..color = _win.withValues(alpha: .12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRect(Rect.fromLTWH(lx, ly - 3, 6, 6), Paint()..color = _bodyHi);
  }

  void _drawSmoke(Canvas canvas) {
    if (paused) {
      return;
    }
    const puffs = 8;
    for (int i = 0; i < puffs; i++) {
      final phase = ((t * 2.2 + i / puffs) % 1.0);
      final px = _stackX + phase * 28;
      final py =
          _stackBot - _stackH - 4 - phase * 38 - math.sin(phase * math.pi) * 8;
      final r = 3.0 + phase * 14;
      final a = (1.0 - phase) * 0.38;

      canvas.drawCircle(
        Offset(px, py),
        r,
        Paint()..color = _smoke.withValues(alpha: a),
      );
    }
  }

  void _drawFireglow(Canvas canvas, double alpha) {
    canvas.drawCircle(
      Offset(_cabX - _cabW - 5, -_drW * .3),
      22,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(_cabX - _cabW - 5, -_drW * .3),
          22,
          [_fire.withValues(alpha: alpha), Colors.transparent],
        ),
    );
  }

  void _drawSpokedWheel(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    int spokes,
    double angle,
  ) {
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = _red);
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = _redLt
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    canvas.drawCircle(Offset(cx, cy), r - 3, Paint()..color = _wheel);

    final spokeP =
        Paint()
          ..color = _spoke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;

    for (int i = 0; i < spokes; i++) {
      final a = angle + (i / spokes) * math.pi * 2;
      canvas.drawLine(
        Offset(cx + math.cos(a) * 3.5, cy + math.sin(a) * 3.5),
        Offset(cx + math.cos(a) * (r - 3.5), cy + math.sin(a) * (r - 3.5)),
        spokeP,
      );
    }

    final cwA = angle + math.pi * .6;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(
          cx + math.cos(cwA) * (r * .55),
          cy + math.sin(cwA) * (r * .55),
        ),
        radius: r * .28,
      ),
      cwA - math.pi * .5,
      math.pi,
      true,
      Paint()..color = _bodyHi,
    );

    canvas.drawCircle(
      Offset(cx, cy),
      4.5,
      Paint()
        ..shader = ui.Gradient.radial(Offset(cx - 1, cy - 1), 3, [
          _brassLt,
          _brass,
        ]),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      4.5,
      Paint()
        ..color = Colors.black.withValues(alpha: .30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
  }

  @override
  bool shouldRepaint(_CrossingTrainPainter o) =>
      o.progress != progress || o.t != t || o.paused != paused;
}

class _SpeedLinePainter extends CustomPainter {
  final double t;
  const _SpeedLinePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(12);
    final p = Paint()..style = PaintingStyle.stroke;
    for (int i = 0; i < 10; i++) {
      final y = .12 + rng.nextDouble() * .60;
      final len = 16 + rng.nextDouble() * 42;
      final xOff =
          (t * size.width * 9 + i * size.width / 10) % (size.width + 90);
      p.color = Colors.white.withValues(alpha: .022 + rng.nextDouble() * .050);
      p.strokeWidth = .6 + rng.nextDouble() * 1.0;
      canvas.drawLine(
        Offset(size.width - xOff, size.height * y),
        Offset(size.width - xOff + len, size.height * y),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_SpeedLinePainter o) => o.t != t;
}

class _FramePainter extends CustomPainter {
  final Color accent;
  const _FramePainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(9, 9, size.width - 18, size.height - 18),
        const Radius.circular(15),
      ),
      Paint()
        ..color = _C.copper.withValues(alpha: .11)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    _corners(canvas, size);
    _rivets(canvas, size);
  }

  void _corners(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = _C.copper.withValues(alpha: .22)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
    const d = 15.0, l = 20.0;
    canvas.drawLine(const Offset(d, d + l), const Offset(d, d), p);
    canvas.drawLine(const Offset(d, d), const Offset(d + l, d), p);
    canvas.drawLine(
      Offset(size.width - d - l, d),
      Offset(size.width - d, d),
      p,
    );
    canvas.drawLine(
      Offset(size.width - d, d),
      Offset(size.width - d, d + l),
      p,
    );
    canvas.drawLine(
      Offset(d, size.height - d - l),
      Offset(d, size.height - d),
      p,
    );
    canvas.drawLine(
      Offset(d, size.height - d),
      Offset(d + l, size.height - d),
      p,
    );
    canvas.drawLine(
      Offset(size.width - d - l, size.height - d),
      Offset(size.width - d, size.height - d),
      p,
    );
    canvas.drawLine(
      Offset(size.width - d, size.height - d - l),
      Offset(size.width - d, size.height - d),
      p,
    );
  }

  void _rivets(Canvas canvas, Size size) {
    const r = 13.5;
    for (final o in [
      Offset(r, r),
      Offset(size.width - r, r),
      Offset(r, size.height - r),
      Offset(size.width - r, size.height - r),
    ]) {
      canvas.drawCircle(
        o,
        4.5,
        Paint()
          ..shader = ui.Gradient.radial(o - const Offset(1.5, 1.5), 3.5, [
            _C.goldLt,
            _C.goldDk,
          ]),
      );
      canvas.drawCircle(
        o,
        4.5,
        Paint()
          ..color = Colors.black.withValues(alpha: .28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _TrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, (size.height - 5) / 2, size.width, 5),
        const Radius.circular(2.5),
      ),
      Paint()..color = _C.surface,
    );
    final tp = Paint()..color = _C.rim;
    for (double x = 0; x < size.width; x += 22) {
      canvas.drawRect(Rect.fromLTWH(x, (size.height - 11) / 2, 1.5, 11), tp);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _TrainPip extends StatelessWidget {
  final Color color;
  const _TrainPip({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: _C.bg, width: 2.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .65), blurRadius: 14),
        ],
      ),
      child: const Center(
        child: Text('🚄', style: TextStyle(fontSize: 8, height: 1)),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final Color color;
  final Widget child;
  const _Chip({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: .26)),
      ),
      child: child,
    );
  }
}

class _PressBtn extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double? fixedWidth;
  final Color? bg;
  final Color? border;
  final Color? accent;

  const _PressBtn({
    required this.onTap,
    required this.child,
    this.fixedWidth,
    this.bg,
    this.border,
    this.accent,
  });

  @override
  State<_PressBtn> createState() => _PressBtnState();
}

class _PressBtnState extends State<_PressBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
  );
  late final Animation<double> _sc = Tween<double>(
    begin: 1.0,
    end: .94,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _sc,
        child: Container(
          width: widget.fixedWidth,
          height: 52,
          decoration: BoxDecoration(
            color: widget.bg ?? _C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.border ?? _C.copper.withValues(alpha: .26),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x28000000),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class _StopDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _StopDialog({required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _C.danger.withValues(alpha: .28)),
            boxShadow: [
              BoxShadow(
                color: _C.danger.withValues(alpha: .08),
                blurRadius: 48,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: .72),
                blurRadius: 60,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.danger.withValues(alpha: .10),
                  border: Border.all(color: _C.danger.withValues(alpha: .24)),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: _C.danger,
                  size: 34,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'EMERGENCY STOP',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _C.cream,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Disembark before reaching the destination?\nYour journey will still be logged.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: _C.muted,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _PressBtn(
                      onTap: onCancel,
                      child: Text(
                        'STAY ON',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _C.cream,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PressBtn(
                      onTap: onConfirm,
                      bg: _C.danger,
                      border: _C.danger,
                      child: Text(
                        'END EARLY',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MILESTONE TOAST — shown at 25%, 50%, 75% progress
// ═══════════════════════════════════════════════════════════════

class _MilestoneToast extends StatefulWidget {
  final String message;
  final Color accentColor;
  final VoidCallback onDone;
  const _MilestoneToast({
    required this.message,
    required this.accentColor,
    required this.onDone,
  });

  @override
  State<_MilestoneToast> createState() => _MilestoneToastState();
}

class _MilestoneToastState extends State<_MilestoneToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3000),
      )
      ..forward().then((_) {
        if (mounted) widget.onDone();
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        // 0-0.1: fade in, 0.1-0.8: hold, 0.8-1.0: fade out
        double opacity;
        if (t < 0.1) {
          opacity = (t / 0.1).clamp(0.0, 1.0);
        } else if (t > 0.8) {
          opacity = ((1.0 - t) / 0.2).clamp(0.0, 1.0);
        } else {
          opacity = 1.0;
        }
        final slide = t < 0.1 ? (1.0 - t / 0.1) * 20.0 : 0.0;

        return Positioned(
          top: MediaQuery.of(context).padding.top + 60 - slide,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: opacity,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131620).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFF5EDDB),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
