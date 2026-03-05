// lib/screens/auth/login_screen.dart
// ═══════════════════════════════════════════════════════════════
//  RAIL FOCUS — GRAND STATION ARRIVAL (Login)
//  Cinematic, animated first-impression screen.
//  • Custom-painted vintage station clock (animated hands)
//  • Animated rail track sliding left
//  • 16 steam particles rising from the locomotive stack
//  • Glassmorphic "platform board" header with departure info
//  • Premium gold CTA + translucent guest button
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../services/auth_service.dart';

// ──────────────────────────────────────────────────────────────
// PALETTE
// ──────────────────────────────────────────────────────────────
class _L {
  static const bg       = Color(0xFF050710);
  static const midnight = Color(0xFF070A18);
  static const velvet   = Color(0xFF0E1020);
  static const brass    = Color(0xFFD4A853);
  static const brassLt  = Color(0xFFF0CC7A);
  static const brassDk  = Color(0xFF8A6930);
  static const cream    = Color(0xFFF5EDDB);
  static const t2       = Color(0xFF9A8E78);
  static const t3       = Color(0xFF564E40);
  static const google   = Color(0xFFEA4335);
  static const error    = Color(0xFFCF6679);
  static const star     = Color(0xFFFFE4A0);
}

// ──────────────────────────────────────────────────────────────
// STEAM PARTICLES
// ──────────────────────────────────────────────────────────────
class _Steam { final double xOff, speed, size, phase;
  const _Steam(this.xOff, this.speed, this.size, this.phase); }

final _kSteams = List<_Steam>.unmodifiable(
  List.generate(16, (i) {
    final r = math.Random(i * 13 + 7);
    return _Steam(
      (r.nextDouble() - 0.5) * 28,
      0.1 + r.nextDouble() * 0.35,
      7 + r.nextDouble() * 14,
      r.nextDouble() * math.pi * 2,
    );
  }),
);

class _SteamPainter extends CustomPainter {
  final double t;
  const _SteamPainter(this.t);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..blendMode = BlendMode.screen;
    for (final st in _kSteams) {
      final progress = (t * st.speed + st.phase / (math.pi * 2)) % 1.0;
      final x = s.width / 2 + st.xOff + math.sin(progress * math.pi * 3) * 10;
      final y = s.height * (1.0 - progress);
      final alpha = (math.sin(progress * math.pi) * 0.4).clamp(0.0, 1.0);
      p.color = const Color(0xFFB8A89A).withValues(alpha: alpha);
      c.drawCircle(Offset(x, y), st.size * (0.5 + progress * 0.5), p);
    }
  }
  @override bool shouldRepaint(_SteamPainter o) => o.t != t;
}

// ──────────────────────────────────────────────────────────────
// RAIL TRACK PAINTER
// ──────────────────────────────────────────────────────────────
class _TrackPainter extends CustomPainter {
  final double offset;
  const _TrackPainter(this.offset);

  @override
  void paint(Canvas c, Size s) {
    final railPaint = Paint()
      ..color = _L.brassDk.withValues(alpha: 0.35)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final tiePaint = Paint()
      ..color = _L.t3.withValues(alpha: 0.2)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const trackSpacing = 18.0;
    const tieSpacing = 32.0;
    final cy = s.height / 2;

    // Rails
    c.drawLine(Offset(0, cy - trackSpacing), Offset(s.width, cy - trackSpacing), railPaint);
    c.drawLine(Offset(0, cy + trackSpacing), Offset(s.width, cy + trackSpacing), railPaint);

    // Ties
    double x = -(offset % tieSpacing);
    while (x < s.width + tieSpacing) {
      c.drawLine(Offset(x, cy - trackSpacing - 4), Offset(x, cy + trackSpacing + 4), tiePaint);
      x += tieSpacing;
    }
  }
  @override bool shouldRepaint(_TrackPainter o) => o.offset != offset;
}

// ──────────────────────────────────────────────────────────────
// STATION CLOCK PAINTER (the main icon)
// ──────────────────────────────────────────────────────────────
class _ClockPainter extends CustomPainter {
  final double seconds; // 0..60
  const _ClockPainter(this.seconds);

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final r = math.min(cx, cy) - 4;

    // Outer bezel
    c.drawCircle(
      Offset(cx, cy), r,
      Paint()..color = _L.brassDk,
    );
    c.drawCircle(
      Offset(cx, cy), r - 4,
      Paint()..color = _L.midnight,
    );

    // Gold ring
    c.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = _L.brass
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Hour ticks
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2;
      final isMajor = i % 3 == 0;
      final outer = Offset(cx + (r - 8) * math.sin(angle), cy - (r - 8) * math.cos(angle));
      final inner = Offset(cx + (r - (isMajor ? 20 : 13)) * math.sin(angle), cy - (r - (isMajor ? 20 : 13)) * math.cos(angle));
      c.drawLine(outer, inner, Paint()
        ..color = isMajor ? _L.brass : _L.brassDk
        ..strokeWidth = isMajor ? 2.5 : 1.5
        ..strokeCap = StrokeCap.round);
    }

    // Minute hand
    final minAngle = (seconds / 60) * math.pi * 2;
    _drawHand(c, cx, cy, minAngle, r * 0.62, 2.0, _L.cream);

    // Second hand (jumpy)
    final secAngle = (seconds.truncate() / 60) * math.pi * 2;
    _drawHand(c, cx, cy, secAngle, r * 0.7, 1.2, _L.brass);

    // Centre nipple
    c.drawCircle(Offset(cx, cy), 5, Paint()..color = _L.brass);
    c.drawCircle(Offset(cx, cy), 3, Paint()..color = _L.midnight);
  }

  void _drawHand(Canvas c, double cx, double cy, double angle, double len, double width, Color color) {
    final tip = Offset(cx + len * math.sin(angle), cy - len * math.cos(angle));
    final tail = Offset(cx - (len * 0.2) * math.sin(angle), cy + (len * 0.2) * math.cos(angle));
    c.drawLine(tail, tip, Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round);
  }

  @override bool shouldRepaint(_ClockPainter o) => o.seconds != seconds;
}

// ──────────────────────────────────────────────────────────────
// LOGIN SCREEN
// ──────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Logic ─────────────────────────────────────────────────
  bool _loading = false;
  String? _error;
  _Btn? _activeBtn;

  // ── Animations ────────────────────────────────────────────
  late final AnimationController _steamCtrl;
  late final AnimationController _trackCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _glowCtrl;

  // ── Clock ─────────────────────────────────────────────────
  Timer? _clockTimer;
  double _clockSec = 0;

  // ── Star field ────────────────────────────────────────────
  final _stars = List.generate(40, (i) {
    final r = math.Random(i * 37 + 11);
    return (
      x: r.nextDouble(),
      y: r.nextDouble() * 0.6,
      size: 0.5 + r.nextDouble() * 1.5,
      alpha: 0.2 + r.nextDouble() * 0.5,
    );
  });

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _steamCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _trackCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _glowCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _fadeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    // Align clock to real time
    final now = DateTime.now();
    _clockSec = (now.minute * 60 + now.second).toDouble();

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _fadeCtrl.forward();
    });

    _clockTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() => _clockSec = (_clockSec + 0.25) % 3600);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _steamCtrl.dispose();
    _trackCtrl.dispose();
    _glowCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Auth ──────────────────────────────────────────────────
  void _setLoading(_Btn btn) {
    if (mounted) setState(() { _loading = true; _activeBtn = btn; _error = null; });
  }
  void _setError(String msg) {
    if (mounted) setState(() { _loading = false; _activeBtn = null; _error = msg; });
  }
  void _clearLoading() {
    if (mounted) setState(() { _loading = false; _activeBtn = null; });
  }

  Future<void> _googleSignIn() async {
    HapticFeedback.mediumImpact();
    _setLoading(_Btn.google);
    try {
      final result = await AuthService.instance.signInWithGoogle();
      if (result == null) { _clearLoading(); return; }
      if (mounted) context.go(AppRouter.home);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Sign-in failed. Please try again.');
    } finally {
      if (mounted && _activeBtn == _Btn.google) _clearLoading();
    }
  }

  Future<void> _guestSignIn() async {
    HapticFeedback.lightImpact();
    _setLoading(_Btn.guest);
    try {
      await AuthService.instance.signInAnonymously();
      if (mounted) context.go(AppRouter.home);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Could not board as a guest. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _L.bg,
      body: Stack(
        children: [
          // ── Deep space background ───────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [
                    const Color(0xFF0D1030),
                    _L.bg,
                  ],
                ),
              ),
            ),
          ),

          // ── Stars ───────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _StarPainter(_stars),
              ),
            ),
          ),

          // ── Animated rail tracks (bottom third) ─────────
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            height: 50,
            child: AnimatedBuilder(
              animation: _trackCtrl,
              builder: (_, __) => CustomPaint(
                painter: _TrackPainter(_trackCtrl.value * 320),
              ),
            ),
          ),

          // ── Gold horizon glow ────────────────────────────
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _L.brass.withValues(alpha: 0.2 + _glowCtrl.value * 0.15),
                      _L.brass.withValues(alpha: 0.35 + _glowCtrl.value * 0.2),
                      _L.brass.withValues(alpha: 0.2 + _glowCtrl.value * 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Steam from top of clock (simulating a loco) ─
          Positioned(
            top: size.height * 0.12,
            left: 0,
            right: 0,
            height: 90,
            child: AnimatedBuilder(
              animation: _steamCtrl,
              builder: (_, __) => CustomPaint(
                painter: _SteamPainter(_steamCtrl.value),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────
          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeCtrl,
              builder: (_, child) => Opacity(
                opacity: Curves.easeOut.transform(_fadeCtrl.value),
                child: child,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── STATION CLOCK ICON ─────────────────────
                  AnimatedBuilder(
                    animation: _glowCtrl,
                    builder: (_, child) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _L.brass.withValues(alpha: (0.12 + _glowCtrl.value * 0.12).clamp(0.0, 1.0)),
                            blurRadius: 50,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                    child: SizedBox(
                      width: 110,
                      height: 110,
                      child: AnimatedBuilder(
                        animation: _clockTimer != null
                            ? _steamCtrl // tick proxy — any animation
                            : _steamCtrl,
                        builder: (_, __) => CustomPaint(
                          painter: _ClockPainter(_clockSec % 60),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── App name ───────────────────────────────
                  Text(
                    'RAILFOCUS',
                    style: GoogleFonts.cinzel(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: _L.cream,
                      letterSpacing: 8,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Departure board tag ────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: _L.brass.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(20),
                      color: _L.brass.withValues(alpha: 0.06),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _L.brass,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'BOARDING  ·  PLATFORM 1  ·  ALL ABOARD',
                          style: GoogleFonts.spaceMono(
                            fontSize: 7.5,
                            color: _L.brass,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Your focus journey awaits',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                      color: _L.t2,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(),

                  // ── Error ──────────────────────────────────
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _L.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _L.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: _L.error, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 14,
                                  color: _L.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Google Sign-In ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: GestureDetector(
                      onTap: _loading ? null : _googleSignIn,
                      child: AnimatedBuilder(
                        animation: _glowCtrl,
                        builder: (_, child) => Container(
                          height: 62,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [_L.brassLt, _L.brass, _L.brassDk],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _L.brass.withValues(alpha: (0.25 + _glowCtrl.value * 0.15).clamp(0.0, 1.0)),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: child,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_activeBtn == _Btn.google)
                              const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: _L.bg, strokeWidth: 2),
                              )
                            else ...[
                              Container(
                                width: 28, height: 28,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: _L.bg),
                                child: Center(
                                  child: Text('G',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: _L.google,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'CONTINUE WITH GOOGLE',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _L.bg,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Guest ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: GestureDetector(
                      onTap: _loading ? null : _guestSignIn,
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _L.brass.withValues(alpha: 0.25)),
                          color: _L.velvet.withValues(alpha: 0.6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_activeBtn == _Btn.guest)
                              SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  color: _L.t2,
                                  strokeWidth: 2,
                                ),
                              )
                            else ...[
                              Icon(Icons.person_outline_rounded, color: _L.t2, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'BOARD AS GUEST',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _L.t2,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Footer ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24, height: 1,
                        color: _L.t3,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Guest data saved locally on device',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 11,
                          color: _L.t3,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 24, height: 1,
                        color: _L.t3,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// STAR FIELD PAINTER
// ──────────────────────────────────────────────────────────────
class _StarPainter extends CustomPainter {
  final List<({double x, double y, double size, double alpha})> stars;
  const _StarPainter(this.stars);

  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    for (final st in stars) {
      p.color = _L.star.withValues(alpha: st.alpha);
      c.drawCircle(Offset(st.x * s.width, st.y * s.height), st.size, p);
    }
  }
  @override bool shouldRepaint(_StarPainter o) => false;
}

// ──────────────────────────────────────────────────────────────
enum _Btn { google, guest }
