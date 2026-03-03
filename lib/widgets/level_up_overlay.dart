// lib/widgets/level_up_overlay.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — LEVEL UP OVERLAY
//  Celebration animation when the user's station upgrades.
//  Shows confetti, the new station emoji, and the level name.
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
// LEVEL UP OVERLAY
// ═══════════════════════════════════════════════════════════════

class LevelUpOverlay extends StatefulWidget {
  final int newLevel;
  final String stationName;
  final String stationEmoji;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.stationName,
    required this.stationEmoji,
    required this.onDismiss,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _scaleCtrl;
  late AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _fadeCtrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeCtrl,
      child: GestureDetector(
        onTap: _dismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Stack(
            children: [
              // Confetti particles
              AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (_, __) {
                  return CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: _ConfettiPainter(
                      progress: _confettiCtrl.value,
                    ),
                  );
                },
              ),

              // Center content
              Center(
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _scaleCtrl,
                    curve: Curves.elasticOut,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Star burst
                      Text('✨', style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),

                      // Level up label
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFDAA520), Color(0xFFFFD700)],
                          ),
                        ),
                        child: Text(
                          'LEVEL UP!',
                          style: GoogleFonts.spaceMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0A0A0F),
                            letterSpacing: 4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Station emoji (big)
                      Text(
                        widget.stationEmoji,
                        style: const TextStyle(fontSize: 64),
                      ),

                      const SizedBox(height: 12),

                      // Station name
                      Text(
                        widget.stationName,
                        style: GoogleFonts.cinzel(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF7E7CE),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'LEVEL ${widget.newLevel}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDAA520),
                          letterSpacing: 3,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Tap to continue',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFFF7E7CE).withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONFETTI PAINTER
// ═══════════════════════════════════════════════════════════════

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter({required this.progress});

  static final _particles = List.generate(40, (i) {
    final rng = math.Random(i * 17 + 3);
    return _Particle(
      x: rng.nextDouble(),
      startY: -0.1 - rng.nextDouble() * 0.3,
      speed: 0.3 + rng.nextDouble() * 0.7,
      rotation: rng.nextDouble() * math.pi * 2,
      rotSpeed: (rng.nextDouble() - 0.5) * 4,
      size: 4 + rng.nextDouble() * 6,
      color: [
        const Color(0xFFDAA520),
        const Color(0xFFFFD700),
        const Color(0xFFF7E7CE),
        const Color(0xFF9B85D4),
        const Color(0xFF4CAF50),
        const Color(0xFFFF6B35),
      ][rng.nextInt(6)],
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = p.startY + progress * p.speed * 1.5;
      if (y > 1.1) continue;

      final rot = p.rotation + progress * p.rotSpeed;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(p.x * size.width, y * size.height);
      canvas.rotate(rot);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  final double x, startY, speed, rotation, rotSpeed, size;
  final Color color;
  const _Particle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.rotation,
    required this.rotSpeed,
    required this.size,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════════════
// STATION LEVEL INFO (matches station_widget.dart)
// ═══════════════════════════════════════════════════════════════

const _stationNames = [
  'Empty Lot', 'Wooden Platform', 'Small Halt', 'Rural Station',
  'Town Depot', 'City Station', 'Metro Hub', 'Grand Station',
  'Central Terminal', 'Imperial Station', 'Grand Terminus',
];

const _stationEmojis = [
  '🏗️', '🪵', '🚏', '🏠', '🏘️', '🏢', '🏙️', '🏛️', '🎭', '👑', '🌟',
];

String stationNameForLevel(int level) =>
    _stationNames[level.clamp(0, _stationNames.length - 1)];

String stationEmojiForLevel(int level) =>
    _stationEmojis[level.clamp(0, _stationEmojis.length - 1)];
