// lib/screens/dining_car_screen.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — THE DINING CAR
//  When a focus block ends, the passenger steps into the dining car.
//  A perfectly brewed coffee steams. The jazz plays low and warm.
//  Route Lore reveals the history of the landscape they just passed.
//  A 5-minute strict countdown keeps them from getting too comfortable.
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ──────────────────────────────────────────────────────────────
// PALETTE
// ──────────────────────────────────────────────────────────────
class _D {
  static const bg = Color(0xFF08060E);
  static const mahogany = Color(0xFF1A0E06);
  static const mahoganyLt = Color(0xFF2C1A0E);
  static const brass = Color(0xFFD4A853);
  static const brassLt = Color(0xFFF0CC7A);
  static const brassDk = Color(0xFF8A6930);
  static const cream = Color(0xFFF5EDDB);
  static const t2 = Color(0xFF9A8E78);
  static const t3 = Color(0xFF564E40);
  static const coffee = Color(0xFF4A2C0C);
  static const coffeeLt = Color(0xFF6B3E12);
  static const steam = Color(0xFFB8A89A);
}

// ──────────────────────────────────────────────────────────────
// ROUTE LORE — 1920s fictional landscape descriptions
// ──────────────────────────────────────────────────────────────
const _routeLore = [
  _Lore(
    region: 'The Midnight Valley',
    emoji: '🌙',
    story:
        'In 1908, local shepherds called it "La Valle Dimenticata" — the forgotten valley. '
        'A single lantern is lit at a farmhouse window each night since 1923, when a widow '
        'awaited her husband who never returned from the Brenner Pass.',
  ),
  _Lore(
    region: 'Copper Pine Ridge',
    emoji: '🌲',
    story:
        'The pines here were named for the peculiar orange hue their bark develops every '
        'autumn. Swedish botanist Erik Halvar documented the phenomenon in 1887, concluding '
        'the copper-rich soil grants them this startling autumnal glow.',
  ),
  _Lore(
    region: 'The Amber Gorge',
    emoji: '🏔️',
    story:
        'During the Great Flood of 1912, engineers drove this rail line through solid granite '
        'using only hand chisels and dynamite. The workers sang folk songs every evening — '
        'the echoes of which, locals claim, can still be heard at dusk.',
  ),
  _Lore(
    region: 'The Silver Lake Flats',
    emoji: '💧',
    story:
        'Every winter, the lakeside freezes into a mirror so perfect that the early railways '
        'would halt here so passengers could step off and see the stars reflected beneath '
        'their feet. A tradition that, sadly, ended with the introduction of faster trains.',
  ),
  _Lore(
    region: 'The Northern Viaduct',
    emoji: '🌉',
    story:
        'Built by a father and son over eleven years, the stone viaduct has stood since 1899. '
        'The father placed a single golden coin in the keystone arch, saying: "As long as '
        'this bridge stands, our family name shall not be forgotten."',
  ),
  _Lore(
    region: 'The Lavender Meadows',
    emoji: '💜',
    story:
        'Every July, the lavender blooms so densely that bees from as far as sixty miles '
        'arrive in clouds visible to passengers. Local honey carries this route\'s particular '
        'warmth — said to be the finest in all of Southern Europe.',
  ),
];

class _Lore {
  final String region;
  final String emoji;
  final String story;
  const _Lore({required this.region, required this.emoji, required this.story});
}

// ──────────────────────────────────────────────────────────────
// STEAM PARTICLE DATA
// ──────────────────────────────────────────────────────────────
class _SteamP {
  final double xOff, speed, size, phase;
  const _SteamP(this.xOff, this.speed, this.size, this.phase);
}

final _kSteams = List<_SteamP>.unmodifiable(
  List.generate(18, (i) {
    final r = math.Random(i * 11 + 5);
    return _SteamP(
      (r.nextDouble() - 0.5) * 30,
      0.15 + r.nextDouble() * 0.4,
      8 + r.nextDouble() * 16,
      r.nextDouble() * math.pi * 2,
    );
  }),
);

// ──────────────────────────────────────────────────────────────
// SCREEN
// ──────────────────────────────────────────────────────────────
class DiningCarScreen extends StatefulWidget {
  final int breakMinutes;
  final VoidCallback? onResume;

  const DiningCarScreen({super.key, this.breakMinutes = 5, this.onResume});

  @override
  State<DiningCarScreen> createState() => _DiningCarScreenState();
}

class _DiningCarScreenState extends State<DiningCarScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────
  late final AnimationController _steamCtrl;   // looping steam
  late final AnimationController _glowCtrl;    // ambient coffee glow
  late final AnimationController _revealCtrl;  // lore card reveal
  late final AnimationController _exitCtrl;    // fade-to-black on resume

  // ── State ──────────────────────────────────────────────────
  late int _breakSec;
  Timer? _timer;
  late final _Lore _lore;
  bool _isExiting = false;
  bool _loreExpanded = false;

  @override
  void initState() {
    super.initState();
    _breakSec = widget.breakMinutes * 60;
    _lore = _routeLore[math.Random().nextInt(_routeLore.length)];

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _steamCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Slight delay before lore card appears
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _revealCtrl.forward();
    });

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _steamCtrl.dispose();
    _glowCtrl.dispose();
    _revealCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_breakSec <= 0) {
        _timer?.cancel();
        _doResume();
        return;
      }
      setState(() => _breakSec--);
    });
  }

  Future<void> _doResume() async {
    if (_isExiting) return;
    _isExiting = true;
    HapticFeedback.mediumImpact();
    await _exitCtrl.forward();
    if (widget.onResume != null) {
      widget.onResume!();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _fmt(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitCtrl,
      builder: (_, child) => Opacity(
        opacity: (1 - _exitCtrl.value).clamp(0.0, 1.0),
        child: child,
      ),
      child: Scaffold(
        backgroundColor: _D.bg,
        body: Stack(
          children: [
            // ── Mahogany background gradient ────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _D.bg,
                      _D.mahogany.withValues(alpha: 0.8),
                      _D.mahogany,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // ── Ambient coffee glow ─────────────────────────
            Positioned(
              bottom: -80,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) => Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomCenter,
                      radius: 1.0,
                      colors: [
                        _D.coffeeLt.withValues(alpha: 0.06 + _glowCtrl.value * 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Vignette ────────────────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.0,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // ── Main content ─────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  Expanded(child: _buildCenter()),
                  _buildLoreCard(),
                  const SizedBox(height: 20),
                  _buildProgressBar(),
                  const SizedBox(height: 16),
                  _buildResumeButton(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THE DINING CAR',
                style: GoogleFonts.spaceMono(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: _D.brass,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'Rest & Recharge',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: _D.cream,
                ),
              ),
            ],
          ),
          // Countdown timer pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _D.mahoganyLt,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _D.brass.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: _D.brass, size: 14),
                const SizedBox(width: 6),
                Text(
                  _fmt(_breakSec),
                  style: GoogleFonts.spaceMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _D.cream,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Centre — Coffee cup ─────────────────────────────────────
  Widget _buildCenter() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Steam above the cup
          SizedBox(
            height: 60,
            width: 120,
            child: AnimatedBuilder(
              animation: _steamCtrl,
              builder: (_, __) => CustomPaint(
                painter: _CoffeeSteamPainter(t: _steamCtrl.value),
              ),
            ),
          ),

          // Coffee cup illustration
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, child) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _D.coffeeLt.withValues(alpha: (0.15 + _glowCtrl.value * 0.12).clamp(0.0, 1.0)),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: child,
            ),
            child: _buildCoffeeCup(),
          ),

          const SizedBox(height: 24),

          Text(
            '"Savour the moment between destinations."',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: _D.t2,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCoffeeCup() {
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(
        painter: _CoffeeCupPainter(),
      ),
    );
  }

  // ── Lore Card ───────────────────────────────────────────────
  Widget _buildLoreCard() {
    return AnimatedBuilder(
      animation: _revealCtrl,
      builder: (_, child) => Opacity(
        opacity: Curves.easeOut.transform(_revealCtrl.value),
        child: Transform.translate(
          offset: Offset(0, (1 - Curves.easeOutCubic.transform(_revealCtrl.value)) * 20),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _loreExpanded = !_loreExpanded);
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _D.mahoganyLt.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _D.brass.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_lore.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PASSING THROUGH',
                            style: GoogleFonts.spaceMono(
                              fontSize: 7,
                              color: _D.brass,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _lore.region,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _D.cream,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _loreExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _D.t2,
                      size: 20,
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      children: [
                        Divider(color: _D.brass.withValues(alpha: 0.2), height: 1),
                        const SizedBox(height: 14),
                        Text(
                          _lore.story,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: _D.cream.withValues(alpha: 0.75),
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _loreExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Progress bar ────────────────────────────────────────────
  Widget _buildProgressBar() {
    final total = widget.breakMinutes * 60;
    final progress = 1.0 - (_breakSec / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Break Progress',
                style: GoogleFonts.spaceMono(
                  fontSize: 8,
                  color: _D.t3,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.spaceMono(
                  fontSize: 8,
                  color: _D.brass,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: _D.mahoganyLt,
              valueColor: AlwaysStoppedAnimation<Color>(_D.brass),
            ),
          ),
        ],
      ),
    );
  }

  // ── Resume button ────────────────────────────────────────────
  Widget _buildResumeButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: _doResume,
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [_D.brassLt, _D.brass, _D.brassDk],
            ),
            boxShadow: [
              BoxShadow(
                color: _D.brass.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.train_rounded, color: _D.bg, size: 20),
              const SizedBox(width: 10),
              Text(
                'ALL ABOARD — RESUME JOURNEY',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _D.bg,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════════
class _CoffeeSteamPainter extends CustomPainter {
  final double t;
  const _CoffeeSteamPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;
    for (final p in _kSteams) {
      final progress = (t * p.speed + p.phase / (math.pi * 2)) % 1.0;
      final x = size.width / 2 + p.xOff + math.sin(progress * math.pi * 4) * 8;
      final y = size.height * (1.0 - progress);
      final alpha = (math.sin(progress * math.pi) * 0.35).clamp(0.0, 1.0);
      paint.color = _D.steam.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), p.size * (0.4 + progress * 0.6), paint);
    }
  }

  @override
  bool shouldRepaint(_CoffeeSteamPainter o) => o.t != t;
}

class _CoffeeCupPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Cup body
    final bodyPath = Path()
      ..moveTo(cx - 38, cy - 20)
      ..lineTo(cx - 30, cy + 35)
      ..quadraticBezierTo(cx, cy + 45, cx + 30, cy + 35)
      ..lineTo(cx + 38, cy - 20)
      ..close();

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_D.coffeeLt, _D.coffee],
        ).createShader(Rect.fromLTWH(cx - 38, cy - 20, 76, 65)),
    );

    // Rim of the cup
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 20), width: 80, height: 14),
        const Radius.circular(7),
      ),
      Paint()..color = _D.brassDk,
    );

    // Coffee surface
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 20), width: 76, height: 16),
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF3D210D), _D.coffee],
        ).createShader(
            Rect.fromCenter(center: Offset(cx, cy - 20), width: 76, height: 16)),
    );

    // Handle
    final handle = Path()
      ..moveTo(cx + 38, cy - 8)
      ..quadraticBezierTo(cx + 60, cy - 8, cx + 60, cy + 8)
      ..quadraticBezierTo(cx + 60, cy + 24, cx + 40, cy + 24)
      ..lineTo(cx + 35, cy + 16)
      ..quadraticBezierTo(cx + 50, cy + 16, cx + 50, cy + 8)
      ..quadraticBezierTo(cx + 50, cy - 2, cx + 36, cy - 2)
      ..close();

    canvas.drawPath(handle, Paint()..color = _D.brassDk);

    // Saucer
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + 42), width: 90, height: 12),
      Paint()..color = _D.brassDk.withValues(alpha: 0.8),
    );

    // Gold rim highlight on cup
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 20), width: 80, height: 14),
        const Radius.circular(7),
      ),
      Paint()
        ..color = _D.brassLt.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_CoffeeCupPainter o) => false;
}
