// lib/screens/boarding_screen.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — CINEMATIC BOARDING RITUAL  (v2 — overflow-safe)
//  FIXES:
//    • RenderFlex overflow: main Column is now inside a LayoutBuilder
//      so every phase widget receives a bounded height.
//    • ConductorPhase: text is now readable (larger font, full opacity,
//      wrapped in a scrollable container with proper padding).
//    • General: Spacer widgets replaced with fixed SizedBox so content
//      never overflows on small screens.
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:ui' as ui;
import '../services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/route_model.dart';
import '../router/app_router.dart';
import '../services/conductor_service.dart';
import '../services/storage_service.dart';

// ═══════════════════════════════════════════════════════════════
// ENUMS & PALETTE
// ═══════════════════════════════════════════════════════════════

enum BoardingPhase {
  standby,
  intro,
  ticket,
  flipBoard,
  bell,
  conductor,
  doors,
  depart,
}

class _P {
  static const ink     = Color(0xFF07090F);
  static const panel   = Color(0xFF131620);
  static const brass   = Color(0xFFD4A853);
  static const brassLt = Color(0xFFF0CC7A);
  static const brassDk = Color(0xFF8A6930);
  static const cream   = Color(0xFFF5EDDB);
  static const t2      = Color(0xFF9A8E78);
  static const t3      = Color(0xFF564E40);
}

// ═══════════════════════════════════════════════════════════════
// PRE-BAKED BOKEH DATA — zero per-frame allocations
// ═══════════════════════════════════════════════════════════════

class _BokehDot {
  final double x, y, r, phase;
  const _BokehDot(this.x, this.y, this.r, this.phase);
}

final _kBokeh = List<_BokehDot>.unmodifiable(
  List.generate(25, (i) {
    final rng = math.Random(i * 17 + 3);
    return _BokehDot(
      rng.nextDouble(),
      rng.nextDouble() * 0.6,
      2.0 + rng.nextDouble() * 5.0,
      rng.nextDouble() * math.pi * 2,
    );
  }),
);

// ═══════════════════════════════════════════════════════════════
// HELPER: Extract sub-interval from 0-1 animation
// ═══════════════════════════════════════════════════════════════

double _iv(double value, double start, double end) {
  return ((value - start) / (end - start)).clamp(0.0, 1.0);
}

// ═══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════

class BoardingRitualScreen extends StatefulWidget {
  final RouteModel? route;
  final String? mood;
  final String? goal;
  final int? durationMinutes;

  const BoardingRitualScreen({
    super.key,
    this.route,
    this.mood,
    this.goal,
    this.durationMinutes,
  });

  @override
  State<BoardingRitualScreen> createState() => _BoardingRitualScreenState();
}

class _BoardingRitualScreenState extends State<BoardingRitualScreen>
    with TickerProviderStateMixin {

  BoardingPhase _currentPhase = BoardingPhase.standby;
  bool _showSkip = false;

  late final AnimationController _fogCtrl;
  late final AnimationController _glowCtrl;
  late final Map<BoardingPhase, AnimationController> _phaseControllers;

  late final RouteModel _route;
  late final Color _accent;
  late final String _announcement;
  late final String _gate;
  late final String _deptTime;

  final _conductor = ConductorService();
  final _storage   = StorageService();
  final _audio     = AudioService();
  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeControllers();
    _runSequence();
  }

  void _initializeData() {
    _route  = widget.route ?? RouteModel.tokyoKyoto;
    _accent = _route.accentColor;

    _announcement = _conductor.generateAnnouncement(SessionContext(
      goal:                 widget.goal,
      mood:                 widget.mood,
      durationMinutes:      widget.durationMinutes ?? 25,
      totalSessions:        _storage.getTotalSessions(),
      currentStreak:        _storage.getStreak(),
      lastSessionCompleted: _storage.getTotalSessions() > 0,
      routeName:            _route.name,
    ));

    final now = DateTime.now();
    _gate    = '${(now.minute % 9) + 1}'
        '${String.fromCharCode(65 + now.second % 5)}';
    _deptTime = '${now.hour.toString().padLeft(2, '0')}'
        ':${(now.minute ~/ 5 * 5).toString().padLeft(2, '0')}';
  }

  void _initializeControllers() {
    _fogCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 25))..repeat();
    _glowCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);

    _phaseControllers = {
      BoardingPhase.intro:     AnimationController(vsync: this, duration: const Duration(milliseconds: 600)),
      BoardingPhase.ticket:    AnimationController(vsync: this, duration: const Duration(milliseconds: 2200)),
      BoardingPhase.flipBoard: AnimationController(vsync: this, duration: const Duration(milliseconds: 1800)),
      BoardingPhase.bell:      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200)),
      BoardingPhase.conductor: AnimationController(vsync: this, duration: const Duration(milliseconds: 3500)),
      BoardingPhase.doors:     AnimationController(vsync: this, duration: const Duration(milliseconds: 1800)),
      BoardingPhase.depart:    AnimationController(vsync: this, duration: const Duration(milliseconds: 1000)),
    };
  }

  @override
  void dispose() {
    _fogCtrl.dispose();
    _glowCtrl.dispose();
    for (final ctrl in _phaseControllers.values) ctrl.dispose();
    super.dispose();
  }

  Future<void> _runSequence() async {
    final sequence = [
      (BoardingPhase.intro,     null),
      (BoardingPhase.ticket,    HapticFeedback.mediumImpact),
      (BoardingPhase.flipBoard, HapticFeedback.lightImpact),
      (BoardingPhase.bell,      HapticFeedback.selectionClick),
      (BoardingPhase.conductor, HapticFeedback.selectionClick),
      (BoardingPhase.doors,     HapticFeedback.heavyImpact),
      (BoardingPhase.depart,    HapticFeedback.heavyImpact),
    ];

    for (final step in sequence) {
      if (!mounted) return;
      final phase       = step.$1;
      final hapticAction = step.$2;

      setState(() {
        _currentPhase = phase;
        if (phase == BoardingPhase.ticket) {
          Future.delayed(const Duration(milliseconds: 1700), () {
            if (mounted) _audio.playTicketStamp();
          });
          _showSkip = true;
        }
            if (phase == BoardingPhase.depart)  _showSkip = false;
            {}
      });

      if (hapticAction != null) hapticAction();
      await _phaseControllers[phase]!.forward();
    }

    _depart();
  }

  void _depart() {
    _audio.playWhistle();
    if (mounted) {
      context.go(AppRouter.focus, extra: {
        'route': widget.route,
        'mood': widget.mood,
        'goal': widget.goal,
        'durationMinutes': widget.durationMinutes,
      });
    }
  }

  void _skip() {
    HapticFeedback.lightImpact();
    _depart();
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _P.ink,
        body: Stack(
          children: [
            // ── Ambient accent glow ───────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.4),
                      radius: 1.3,
                      colors: [
                        _accent.withValues(alpha: 0.04 + _glowCtrl.value * 0.06),
                        _P.ink,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Station silhouette ────────────────────────────
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _StationBgPainter(accent: _accent)),
              ),
            ),

            // ── Bokeh lights ──────────────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _BokehPainter(t: _glowCtrl.value, accent: _accent),
                ),
              ),
            ),

            // ── Platform fog ──────────────────────────────────
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _fogCtrl,
                  builder: (_, __) => CustomPaint(painter: _FogPainter(t: _fogCtrl.value)),
                ),
              ),
            ),

            // ── Main content — OVERFLOW-SAFE ─────────────────
            // LayoutBuilder gives us the exact available height so
            // every child can be bounded instead of using Spacers.
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availH = constraints.maxHeight;
                  final headerH = 96.0;   // header + top spacing
                  final skipH   = _showSkip ? 64.0 : 20.0;
                  final phaseH  = availH - headerH - skipH;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      _buildHeader(),
                      // Phase content — bounded height, never overflows
                      SizedBox(
                        height: phaseH,
                        width: double.infinity,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.04),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(_currentPhase),
                            child: _buildPhase(),
                          ),
                        ),
                      ),
                      // Skip button
                      if (_showSkip) ...[
                        _SkipButton(onTap: _skip),
                        const SizedBox(height: 16),
                      ] else
                        const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),

            // ── Steam overlay (phase 6) ───────────────────────
            if (_currentPhase == BoardingPhase.depart)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _phaseControllers[BoardingPhase.depart]!,
                    builder: (_, __) => CustomPaint(
                      painter: _HeavySteamPainter(
                          t: _phaseControllers[BoardingPhase.depart]!.value),
                    ),
                  ),
                ),
              ),

            // ── Cinematic letterbox bars ──────────────────────
            _CinematicBars(ctrl: _phaseControllers[BoardingPhase.intro]!),

            // ── Vignette ─────────────────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.0,
                      colors: [Colors.transparent, _P.ink.withValues(alpha: 0.65)],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedOpacity(
      opacity: _currentPhase != BoardingPhase.standby ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [_P.brassLt, _P.brass, _P.brassDk]),
                boxShadow: [BoxShadow(color: _P.brass.withValues(alpha: 0.4), blurRadius: 16)],
              ),
              child: const Icon(Icons.train_rounded, color: _P.ink, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LUXE RAIL',
                    style: GoogleFonts.cormorant(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: _P.cream, letterSpacing: 5,
                    )),
                Text(_route.name.toUpperCase(),
                    style: GoogleFonts.cormorant(
                      fontSize: 11, fontStyle: FontStyle.italic,
                      color: _accent.withValues(alpha: 0.9),
                      letterSpacing: 1,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhase() {
    return switch (_currentPhase) {
      BoardingPhase.standby   => const SizedBox.shrink(),
      BoardingPhase.intro     => const SizedBox.shrink(),
      BoardingPhase.ticket    => _TicketPhase(
          ctrl: _phaseControllers[BoardingPhase.ticket]!, accent: _accent, route: _route),
      BoardingPhase.flipBoard => _FlipBoardPhase(
          ctrl: _phaseControllers[BoardingPhase.flipBoard]!, accent: _accent,
          gate: _gate, time: _deptTime),
      BoardingPhase.bell      => _BellPhase(
          ctrl: _phaseControllers[BoardingPhase.bell]!, accent: _accent),
      BoardingPhase.conductor => _ConductorPhase(
          ctrl: _phaseControllers[BoardingPhase.conductor]!, accent: _accent,
          announcement: _announcement),
      BoardingPhase.doors     => _DoorsPhase(
          ctrl: _phaseControllers[BoardingPhase.doors]!, accent: _accent),
      BoardingPhase.depart    => _DepartPhase(accent: _accent),
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// CINEMATIC LETTERBOX BARS
// ═══════════════════════════════════════════════════════════════

class _CinematicBars extends StatelessWidget {
  final AnimationController ctrl;
  const _CinematicBars({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final h = 36.0 * Curves.easeOutCubic.transform(ctrl.value);
        return Stack(children: [
          Positioned(top: 0, left: 0, right: 0,
              child: Container(height: h, color: Colors.black)),
          Positioned(bottom: 0, left: 0, right: 0,
              child: Container(height: h, color: Colors.black)),
        ]);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SKIP BUTTON
// ═══════════════════════════════════════════════════════════════

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SkipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _P.panel.withValues(alpha: 0.6),
          border: Border.all(color: _P.brass.withValues(alpha: 0.18)),
        ),
        child: Text('SKIP CEREMONY',
            style: GoogleFonts.dmMono(
              fontSize: 9, color: _P.t2, letterSpacing: 2,
            )),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PHASE 1: TICKET SCAN
// ═══════════════════════════════════════════════════════════════

class _TicketPhase extends StatelessWidget {
  final AnimationController ctrl;
  final Color accent;
  final RouteModel route;

  const _TicketPhase({required this.ctrl, required this.accent, required this.route});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t       = ctrl.value;
        // easeOutBack overshoots 1.0 — clamp all values used in Opacity/scale
        final appear  = Curves.easeOutBack.transform(_iv(t, 0.0, 0.12)).clamp(0.0, 1.0);
        final scan    = Curves.easeInOut.transform(_iv(t, 0.12, 0.45)).clamp(0.0, 1.0);
        final punch   = Curves.easeOutCubic.transform(_iv(t, 0.45, 0.58)).clamp(0.0, 1.0);
        final shimmer = _iv(t, 0.58, 0.75).clamp(0.0, 1.0);
        final stamp   = Curves.easeOutBack.transform(_iv(t, 0.75, 0.90)).clamp(0.0, 1.0);
        final done    = _iv(t, 0.90, 1.0).clamp(0.0, 1.0);

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.8 + appear * 0.2,
                child: Opacity(
                  opacity: appear.clamp(0.0, 1.0),
                  child: SizedBox(
                    width: 180, height: 230,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 160, height: 210,
                          decoration: BoxDecoration(
                            color: _P.panel,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.3 + stamp * 0.4),
                              width: 2,
                            ),
                            boxShadow: [BoxShadow(
                              color: accent.withValues(alpha: 0.15 + stamp * 0.25),
                              blurRadius: 30 + stamp * 20,
                            )],
                          ),
                          child: Stack(children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(route.emoji, style: const TextStyle(fontSize: 42)),
                                const SizedBox(height: 10),
                                Text('BOARDING PASS',
                                    style: GoogleFonts.dmMono(
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                      color: _P.t2, letterSpacing: 2,
                                    )),
                                const SizedBox(height: 6),
                                Text(route.name.toUpperCase(),
                                    style: GoogleFonts.cormorant(
                                      fontSize: 14, fontWeight: FontWeight.w600,
                                      color: _P.cream, letterSpacing: 1,
                                    )),
                              ],
                            ),
                            if (punch > 0)
                              Positioned(
                                top: 18, right: 18,
                                child: Opacity(
                                  opacity: punch,
                                  child: Container(
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle, color: _P.ink,
                                      border: Border.all(
                                          color: accent.withValues(alpha: 0.4), width: 1.5),
                                    ),
                                    child: Icon(Icons.check_rounded, size: 12, color: accent),
                                  ),
                                ),
                              ),
                            if (stamp > 0)
                              Center(
                                child: Transform.scale(
                                  scale: stamp,
                                  child: Transform.rotate(
                                    angle: -0.15,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: accent, width: 2.5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('VALIDATED',
                                          style: GoogleFonts.dmMono(
                                            fontSize: 12, fontWeight: FontWeight.w800,
                                            color: accent, letterSpacing: 3,
                                          )),
                                    ),
                                  ),
                                ),
                              ),
                            if (shimmer > 0 && shimmer < 1)
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: CustomPaint(
                                    painter: _ShimmerPainter(t: shimmer, accent: accent),
                                  ),
                                ),
                              ),
                          ]),
                        ),
                        if (scan > 0 && scan < 1)
                          Positioned(
                            top: 15 + (195 * scan), left: 5, right: 5,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: accent,
                                boxShadow: [BoxShadow(
                                  color: accent.withValues(alpha: 0.8),
                                  blurRadius: 20, spreadRadius: 3,
                                )],
                              ),
                            ),
                          ),
                        if (punch > 0 && punch < 1)
                          Positioned(
                            top: -30 + (48 * punch), right: 20,
                            child: Container(
                              width: 30, height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_P.brassLt, _P.brass, _P.brassDk],
                                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [BoxShadow(
                                    color: _P.brass.withValues(alpha: 0.5), blurRadius: 12)],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedOpacity(
                opacity: done > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: accent, size: 20),
                    const SizedBox(width: 10),
                    Text('TICKET VALIDATED',
                        style: GoogleFonts.dmMono(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: accent, letterSpacing: 2,
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PHASE 2: FLIP-BOARD
// ═══════════════════════════════════════════════════════════════

class _FlipBoardPhase extends StatelessWidget {
  final AnimationController ctrl;
  final Color accent;
  final String gate, time;

  const _FlipBoardPhase({
    required this.ctrl, required this.accent,
    required this.gate, required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value;
        final clockAppear = Curves.easeOut.transform(_iv(t, 0.75, 1.0));

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PLATFORM',
                  style: GoogleFonts.dmMono(fontSize: 10, color: _P.t2, letterSpacing: 4)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0C14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _P.brass.withValues(alpha: 0.25)),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < gate.length; i++) ...[
                      _FlipChar(finalChar: gate[i], progress: t,
                          charIndex: i, totalChars: gate.length),
                      if (i < gate.length - 1) const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Opacity(
                opacity: clockAppear,
                child: Transform.scale(
                  scale: 0.9 + clockAppear * 0.1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 36, height: 36,
                        child: CustomPaint(
                            painter: _ClockPainter(accent: accent, time: time)),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DEPARTURE',
                              style: GoogleFonts.dmMono(
                                fontSize: 8, color: _P.t3, letterSpacing: 2,
                              )),
                          Text(time,
                              style: GoogleFonts.cormorant(
                                fontSize: 28, fontWeight: FontWeight.w700,
                                color: _P.cream,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FlipChar extends StatelessWidget {
  final String finalChar;
  final double progress;
  final int charIndex, totalChars;

  const _FlipChar({
    required this.finalChar, required this.progress,
    required this.charIndex, required this.totalChars,
  });

  @override
  Widget build(BuildContext context) {
    final settleStart = 0.3 + charIndex * 0.12;
    final settleEnd   = settleStart + 0.2;
    final settled     = _iv(progress, settleStart, settleEnd);

    String display;
    if (settled >= 1.0) {
      display = finalChar;
    } else if (progress < 0.05) {
      display = ' ';
    } else {
      final rng = math.Random((progress * 200).toInt() + charIndex * 37);
      display = String.fromCharCode(
          (finalChar.codeUnitAt(0) >= 65 && finalChar.codeUnitAt(0) <= 90)
              ? 65 + rng.nextInt(26)
              : 48 + rng.nextInt(10));
    }

    return Container(
      width: 44, height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: settled >= 1.0
              ? _P.brass.withValues(alpha: 0.4)
              : _P.t3.withValues(alpha: 0.2),
        ),
        boxShadow: settled >= 1.0
            ? [BoxShadow(color: _P.brass.withValues(alpha: 0.2), blurRadius: 10)]
            : null,
      ),
      child: Stack(children: [
        Positioned(
          top: 29, left: 4, right: 4,
          child: Container(height: 1, color: Colors.black.withValues(alpha: 0.5)),
        ),
        Center(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateX(settled < 1.0
                  ? math.sin(progress * math.pi * 12 + charIndex) * 0.15 : 0),
            child: Text(display,
                style: GoogleFonts.dmMono(
                  fontSize: 30, fontWeight: FontWeight.w700,
                  color: settled >= 1.0 ? _P.brassLt : _P.t2,
                )),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PHASE 3: STATION BELL
// ═══════════════════════════════════════════════════════════════

class _BellPhase extends StatelessWidget {
  final AnimationController ctrl;
  final Color accent;
  const _BellPhase({required this.ctrl, required this.accent});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t      = ctrl.value;
        final appear = Curves.easeOut.transform(_iv(t, 0.0, 0.15));
        final sway   = math.sin(t * math.pi * 6) * 0.08 * (1 - t);
        final ring1  = _iv(t, 0.15, 0.55);
        final ring2  = _iv(t, 0.45, 0.85);
        final ring3  = _iv(t, 0.65, 1.0);

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200, height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _ring(ring1, accent, 40),
                    _ring(ring2, accent, 55),
                    _ring(ring3, accent, 70),
                    Opacity(
                      opacity: appear,
                      child: Transform.rotate(
                        angle: sway,
                        child: CustomPaint(
                            size: const Size(80, 100), painter: _BellPainter()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: appear,
                child: Text('ALL ABOARD',
                    style: GoogleFonts.cormorant(
                      fontSize: 28, fontWeight: FontWeight.w700,
                      color: _P.cream, letterSpacing: 4,
                    )),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ring(double progress, Color color, double maxRadius) {
    if (progress <= 0) return const SizedBox.shrink();
    return Container(
      width: maxRadius * 2 * progress,
      height: maxRadius * 2 * progress,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.4 * (1 - progress)),
          width: 2.5 * (1 - progress),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PHASE 4: CONDUCTOR ANNOUNCEMENT  ← KEY FIX
//
//  Changes vs original:
//  • Entire widget is a scrollable SingleChildScrollView so long
//    announcements never overflow.
//  • textFade starts at 0.35 (was 0.45) and ends at 0.65 (was 0.80)
//    so the text reaches full opacity while the phase is still active.
//  • Opacity clamp ensures 1.0 is always reached, not just approached.
//  • Font size raised to 22 (was 20), weight w600 (was w500).
//  • Background card added behind the text for contrast/readability.
//  • Phase duration raised to 3500ms in initState above.
// ═══════════════════════════════════════════════════════════════

class _ConductorPhase extends StatelessWidget {
  final AnimationController ctrl;
  final Color accent;
  final String announcement;

  const _ConductorPhase({
    required this.ctrl, required this.accent, required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t          = ctrl.value;
        // easeOutBack overshoots 1.0 by design — clamp immediately so
        // Opacity / Transform.scale never receive an out-of-range value.
        final iconAppear = Curves.easeOutBack.transform(_iv(t, 0.0, 0.20)).clamp(0.0, 1.0);
        final hatTip     = Curves.easeInOutCubic.transform(_iv(t, 0.20, 0.35)).clamp(0.0, 1.0);
        final hatReturn  = Curves.easeInOutCubic.transform(_iv(t, 0.35, 0.42)).clamp(0.0, 1.0);
        final lineAppear = Curves.easeOut.transform(_iv(t, 0.30, 0.45)).clamp(0.0, 1.0);
        final textFade   = Curves.easeOut.transform(_iv(t, 0.35, 0.65)).clamp(0.0, 1.0);

        final tilt = hatTip < 1.0 ? hatTip * 0.12 : 0.12 * (1 - hatReturn);

        return SingleChildScrollView(
          // Scroll if text is very long — prevents overflow
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),

                // Conductor icon
                Opacity(
                  opacity: iconAppear,
                  child: Transform.scale(
                    scale: iconAppear,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()..rotateZ(tilt),
                      child: Container(
                        width: 68, height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_P.brassLt, _P.brass, _P.brassDk],
                          ),
                          boxShadow: [BoxShadow(
                            color: _P.brass.withValues(alpha: 0.5),
                            blurRadius: 28, spreadRadius: 4,
                          )],
                        ),
                        child: const Icon(Icons.record_voice_over_rounded,
                            color: _P.ink, size: 30),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Opacity(
                  opacity: iconAppear,
                  child: Text('THE CONDUCTOR',
                      style: GoogleFonts.dmMono(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: _P.brass, letterSpacing: 3,
                      )),
                ),

                const SizedBox(height: 20),

                Opacity(opacity: lineAppear, child: _decoLine()),

                const SizedBox(height: 16),

                // ── Announcement card ──────────────────────────
                // Clamp ensures opacity always hits 1.0
                Opacity(
                  opacity: textFade,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - textFade)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        // Subtle card so text pops against dark background
                        color: _P.panel.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _P.brass.withValues(alpha: 0.18)),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16, offset: const Offset(0, 4),
                        )],
                      ),
                      child: Text(
                        announcement,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cormorant(
                          // ↑ larger & bolder than original
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          // Full cream — no alpha reduction
                          color: _P.cream,
                          height: 1.65,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Opacity(opacity: lineAppear, child: _decoLine()),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _decoLine() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40, height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent, _P.brass.withValues(alpha: 0.5),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
                color: _P.brass, borderRadius: BorderRadius.circular(1)),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 40, height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _P.brass.withValues(alpha: 0.5), Colors.transparent,
            ]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PHASE 5: DOORS CLOSING
// ═══════════════════════════════════════════════════════════════

class _DoorsPhase extends StatelessWidget {
  final AnimationController ctrl;
  final Color accent;
  const _DoorsPhase({required this.ctrl, required this.accent});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t     = ctrl.value;
        final gauge = Curves.easeInOut.transform(_iv(t, 0.0, 0.35)).clamp(0.0, 1.0);
        final close = Curves.easeInOutCubic.transform(_iv(t, 0.25, 0.80)).clamp(0.0, 1.0);
        final seal  = Curves.easeOutBack.transform(_iv(t, 0.80, 1.0)).clamp(0.0, 1.0);

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80, height: 50,
                child: CustomPaint(painter: _GaugePainter(value: gauge, accent: accent)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 220, height: 180,
                child: Stack(children: [
                  Positioned(left: 0, top: 0, bottom: 0,
                      width: 110 - (close * 55), child: _DoorPanel()),
                  Positioned(right: 0, top: 0, bottom: 0,
                      width: 110 - (close * 55), child: _DoorPanel()),
                  if (seal > 0)
                    Center(
                      child: Transform.scale(
                        scale: seal,
                        child: Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                                colors: [_P.brassLt, _P.brass, _P.brassDk]),
                            boxShadow: [BoxShadow(
                                color: _P.brass.withValues(alpha: 0.7), blurRadius: 24)],
                          ),
                          child: const Icon(Icons.lock_rounded, color: _P.ink, size: 26),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 20),
              Text('DOORS CLOSING',
                  style: GoogleFonts.dmMono(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: accent, letterSpacing: 3,
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _DoorPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF2A2A2A), Color(0xFF151515)]),
        border: Border.all(color: _P.brass.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(painter: _DoorDetailPainter()),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PHASE 6: DEPARTING
// ═══════════════════════════════════════════════════════════════

class _DepartPhase extends StatelessWidget {
  final Color accent;
  const _DepartPhase({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 40)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.train_rounded, color: accent, size: 30),
            const SizedBox(width: 18),
            Text('DEPARTING...',
                style: GoogleFonts.dmMono(
                  fontSize: 17, fontWeight: FontWeight.w700,
                  color: accent, letterSpacing: 3,
                )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAINTERS (unchanged)
// ═══════════════════════════════════════════════════════════════

class _StationBgPainter extends CustomPainter {
  final Color accent;
  const _StationBgPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final p      = Paint()..color = Colors.white.withValues(alpha: 0.02);
    final floorY = size.height * 0.85;

    canvas.drawLine(
      Offset(0, floorY), Offset(size.width, floorY),
      Paint()..color = Colors.white.withValues(alpha: 0.04)..strokeWidth = 1,
    );

    for (int i = 0; i < 3; i++) {
      final x1 = size.width * (0.1 + i * 0.35);
      final x2 = x1 + 18;
      canvas.drawRect(Rect.fromLTWH(x1, size.height * 0.15, 8,
          floorY - size.height * 0.15), p);
      canvas.drawRect(Rect.fromLTWH(x2, size.height * 0.15, 8,
          floorY - size.height * 0.15), p);
      final archRect = Rect.fromLTWH(x1, size.height * 0.12, x2 + 8 - x1, 30);
      canvas.drawArc(archRect, math.pi, math.pi, false,
          p..style = PaintingStyle.stroke..strokeWidth = 3);
      p.style = PaintingStyle.fill;
    }

    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.08, size.width, 3),
        Paint()..color = Colors.white.withValues(alpha: 0.015));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.12, size.width, 2),
        Paint()..color = Colors.white.withValues(alpha: 0.01));
  }

  @override
  bool shouldRepaint(_StationBgPainter o) => false;
}

class _BokehPainter extends CustomPainter {
  final double t;
  final Color accent;
  const _BokehPainter({required this.t, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (final dot in _kBokeh) {
      final tw    = (math.sin(t * math.pi * 2 + dot.phase) + 1) * 0.5;
      final alpha = (0.03 + tw * 0.08).clamp(0.0, 1.0);
      p.color = accent.withValues(alpha: alpha);
      canvas.drawCircle(
          Offset(dot.x * size.width, dot.y * size.height), dot.r + tw * 2, p);
    }
  }

  @override
  bool shouldRepaint(_BokehPainter o) => o.t != t;
}

class _FogPainter extends CustomPainter {
  final double t;
  const _FogPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    final rng = math.Random(77);
    for (int i = 0; i < 6; i++) {
      final baseX  = rng.nextDouble() * size.width;
      final drift  = math.sin(t * math.pi * 2 + i * 1.3) * 40;
      final y      = size.height * (0.78 + rng.nextDouble() * 0.18);
      final w      = 120.0 + rng.nextDouble() * 100;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(baseX + drift, y),
            width: w, height: 30 + rng.nextDouble() * 20),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_FogPainter o) => o.t != t;
}

class _ShimmerPainter extends CustomPainter {
  final double t;
  final Color accent;
  const _ShimmerPainter({required this.t, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final cx = (t * (size.width + 120)) - 60;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = ui.Gradient.linear(
        Offset(cx - 60, 0), Offset(cx + 60, 0),
        [Colors.transparent, accent.withValues(alpha: 0.3), Colors.transparent],
        [0.0, 0.5, 1.0],
      ),
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter o) => o.t != t;
}

class _BellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx   = size.width / 2;
    final body = Path()
      ..moveTo(cx - 12, 20)
      ..lineTo(cx - 28, size.height - 10)
      ..quadraticBezierTo(cx, size.height + 5, cx + 28, size.height - 10)
      ..lineTo(cx + 12, 20)
      ..close();

    canvas.drawPath(body, Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx - 20, 0), Offset(cx + 20, 0),
        [_P.brassDk, _P.brassLt, _P.brass, _P.brassDk], [0, 0.3, 0.7, 1],
      ));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, 18), width: 28, height: 10),
          const Radius.circular(5)),
      Paint()..color = _P.brass,
    );

    canvas.drawCircle(Offset(cx, size.height - 15), 5,
        Paint()..color = _P.brassDk);
    canvas.drawLine(Offset(cx, 0), Offset(cx, 14),
        Paint()..color = _P.brass..strokeWidth = 3..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ClockPainter extends CustomPainter {
  final Color accent;
  final String time;
  const _ClockPainter({required this.accent, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 2;

    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = _P.panel);
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..style = PaintingStyle.stroke
          ..color = _P.brass.withValues(alpha: 0.5)..strokeWidth = 2);

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2 - math.pi / 2;
      canvas.drawLine(
        Offset(cx + math.cos(angle) * (r - 4), cy + math.sin(angle) * (r - 4)),
        Offset(cx + math.cos(angle) * (r - 1), cy + math.sin(angle) * (r - 1)),
        Paint()..color = _P.brass.withValues(alpha: 0.6)..strokeWidth = 1.5,
      );
    }

    final parts = time.split(':');
    final h     = int.tryParse(parts[0]) ?? 12;
    final m     = int.tryParse(parts[1]) ?? 0;

    final hAngle = ((h % 12) / 12 + m / 720) * math.pi * 2 - math.pi / 2;
    canvas.drawLine(Offset(cx, cy),
        Offset(cx + math.cos(hAngle) * r * 0.5, cy + math.sin(hAngle) * r * 0.5),
        Paint()..color = _P.cream..strokeWidth = 2.5..strokeCap = StrokeCap.round);

    final mAngle = (m / 60) * math.pi * 2 - math.pi / 2;
    canvas.drawLine(Offset(cx, cy),
        Offset(cx + math.cos(mAngle) * r * 0.72, cy + math.sin(mAngle) * r * 0.72),
        Paint()..color = accent..strokeWidth = 1.5..strokeCap = StrokeCap.round);

    canvas.drawCircle(Offset(cx, cy), 2.5, Paint()..color = _P.brass);
  }

  @override
  bool shouldRepaint(_ClockPainter o) => false;
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color accent;
  const _GaugePainter({required this.value, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height;
    final r  = size.width / 2 - 4;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi, math.pi, false,
      Paint()..style = PaintingStyle.stroke
        ..color = _P.t3.withValues(alpha: 0.3)
        ..strokeWidth = 6..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi, math.pi * value, false,
      Paint()..style = PaintingStyle.stroke
        ..color = value > 0.8 ? const Color(0xFFFF4444)
            : value > 0.5 ? accent : _P.brass
        ..strokeWidth = 6..strokeCap = StrokeCap.round,
    );

    final angle = math.pi + math.pi * value;
    canvas.drawLine(Offset(cx, cy),
        Offset(cx + math.cos(angle) * (r - 8), cy + math.sin(angle) * (r - 8)),
        Paint()..color = _P.cream..strokeWidth = 2..strokeCap = StrokeCap.round);

    canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = _P.brass);
  }

  @override
  bool shouldRepaint(_GaugePainter o) => o.value != value;
}

class _DoorDetailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = _P.brass.withValues(alpha: 0.15)..strokeWidth = 1.5;
    for (int i = 1; i < 4; i++) {
      final x = (size.width / 4) * i;
      canvas.drawLine(Offset(x, 8), Offset(x, size.height - 8), p);
    }
    final rp = Paint()..color = _P.brassDk.withValues(alpha: 0.6);
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 3; col++) {
        canvas.drawCircle(
          Offset((size.width / 4) * (col + 0.5),
              16 + row * ((size.height - 32) / 4)),
          2, rp,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _HeavySteamPainter extends CustomPainter {
  final double t;
  const _HeavySteamPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final p = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

    for (int i = 0; i < 14; i++) {
      final x       = size.width * (0.15 + rng.nextDouble() * 0.7);
      final baseY   = size.height * 0.8;
      final rise    = size.height * 0.7 * t;
      final wobble  = math.sin(t * math.pi * 5 + i * 1.2) * 30;
      final y       = baseY - rise + wobble;
      final opacity = (1 - t * 0.7) * (0.15 + rng.nextDouble() * 0.25);
      final radius  = 35 + rng.nextDouble() * 50 + t * 40;

      p.color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), radius, p);
    }

    if (t > 0.7) {
      final fadeAlpha = ((t - 0.7) / 0.3).clamp(0.0, 1.0);
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _P.ink.withValues(alpha: fadeAlpha * 0.8));
    }
  }

  @override
  bool shouldRepaint(_HeavySteamPainter o) => o.t != t;
}