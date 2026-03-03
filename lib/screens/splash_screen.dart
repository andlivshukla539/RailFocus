import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class _Sp {
  static const ink = Color(0xFF07090F);
  static const brass = Color(0xFFD4A853);
  static const brassLt = Color(0xFFF0CC7A);
  static const brassDk = Color(0xFF8A6930);
  static const cream = Color(0xFFF5EDDB);
  static const t2 = Color(0xFF9A8E78);
}

double _iv(double value, double start, double end) {
  return ((value - start) / (end - start)).clamp(0.0, 1.0);
}

class _Particle {
  final double angle, distance, size, phase;
  const _Particle(this.angle, this.distance, this.size, this.phase);
}

final _kParticles = List<_Particle>.unmodifiable(
  List.generate(24, (i) {
    final rng = math.Random(i * 13 + 7);
    return _Particle(
      (i / 24) * math.pi * 2,
      0.35 + rng.nextDouble() * 0.12,
      1.5 + rng.nextDouble() * 2.5,
      rng.nextDouble() * math.pi * 2,
    );
  }),
);

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Sp.ink,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;

          final ringAppear = Curves.easeOut.transform(_iv(t, 0.0, 0.15));
          final iconScale = Curves.easeOutBack
              .transform(_iv(t, 0.08, 0.28))
              .clamp(0.0, 1.0);
          final iconGlow = _iv(t, 0.12, 0.30);
          final titleFade = Curves.easeOut.transform(_iv(t, 0.22, 0.38));
          final titleSpacing = Curves.easeOutCubic.transform(
            _iv(t, 0.22, 0.42),
          );
          final taglineFade = Curves.easeOut.transform(_iv(t, 0.35, 0.48));
          final particlePulse = _iv(t, 0.50, 0.72);
          final fadeOut = _iv(t, 0.82, 1.0);

          final masterOpacity = (1.0 - fadeOut).clamp(0.0, 1.0);

          return Opacity(
            opacity: masterOpacity,
            child: Stack(
              children: [
                // Background glow
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.6,
                        colors: [
                          _Sp.brass.withValues(alpha: 0.04 + iconGlow * 0.08),
                          _Sp.ink,
                        ],
                      ),
                    ),
                  ),
                ),

                // Particle ring
                if (particlePulse > 0)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ParticleRingPainter(progress: particlePulse),
                    ),
                  ),

                // Centre content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brass ring + train icon
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ring
                            Opacity(
                              opacity: ringAppear,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _Sp.brass.withValues(
                                      alpha: ringAppear * 0.5,
                                    ),
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            ),

                            // Inner ring
                            Opacity(
                              opacity: ringAppear,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _Sp.brass.withValues(
                                      alpha: ringAppear * 0.2,
                                    ),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),

                            // Gold glow behind icon
                            if (iconGlow > 0)
                              Container(
                                width: 100 + iconGlow * 20,
                                height: 100 + iconGlow * 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _Sp.brass.withValues(
                                        alpha: iconGlow * 0.3,
                                      ),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              ),

                            // Train icon
                            Transform.scale(
                              scale: iconScale,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _Sp.brassLt,
                                      _Sp.brass,
                                      _Sp.brassDk,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _Sp.brass.withValues(
                                        alpha: 0.3 + iconGlow * 0.3,
                                      ),
                                      blurRadius: 24,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.train_rounded,
                                  color: _Sp.ink,
                                  size: 38,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Title
                      Opacity(
                        opacity: titleFade,
                        child: Text(
                          'LUXE RAIL',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: _Sp.cream,
                            letterSpacing: 6 + titleSpacing * 10,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Decorative line
                      Opacity(
                        opacity: titleFade,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 30 * titleFade,
                              height: 1,
                              color: _Sp.brass.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 10),
                            Transform.rotate(
                              angle: math.pi / 4,
                              child: Container(
                                width: 5,
                                height: 5,
                                color: _Sp.brass,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 30 * titleFade,
                              height: 1,
                              color: _Sp.brass.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Tagline
                      Opacity(
                        opacity: taglineFade,
                        child: Text(
                          'Focus Through the Journey',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: _Sp.t2,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Vignette
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 1.0,
                          colors: [
                            Colors.transparent,
                            _Sp.ink.withValues(alpha: 0.5),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ParticleRingPainter extends CustomPainter {
  final double progress;
  const _ParticleRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseR = size.width * 0.15;
    final p = Paint();

    for (final particle in _kParticles) {
      final dist = baseR + particle.distance * size.width * progress;
      final angle = particle.angle + progress * 0.3;
      final x = cx + math.cos(angle) * dist;
      final y = cy + math.sin(angle) * dist;
      final alpha = (1.0 - progress) * 0.6;
      final r = particle.size * (1.0 + progress * 0.5);

      p.color = _Sp.brass.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  @override
  bool shouldRepaint(_ParticleRingPainter o) => o.progress != progress;
}
