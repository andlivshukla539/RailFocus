// lib/screens/arrival_screen.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — ARRIVAL SCREEN
//  Theme: Grand Station Arrival Celebration
//
//  FEATURES:
//  ─────────────────────────────────────────────────────────────
//  • Confetti/celebration animation for completed journeys
//  • Conductor's arrival message (context-aware)
//  • Session stats display
//  • Optional note input for reflection
//  • Different tone for early stops vs. completions
//  • Streak celebration for milestones
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_service.dart';
import '../models/session_model.dart';
import '../router/app_router.dart';
import '../services/storage_service.dart';

// ═══════════════════════════════════════════════════════════════
// PALETTE
// ═══════════════════════════════════════════════════════════════

class _P {
  static const ink     = Color(0xFF07090F);
  static const panel   = Color(0xFF131620);
  static const surface = Color(0xFF1A1E2C);
  static const brass   = Color(0xFFD4A853);
  static const brassLt = Color(0xFFF0CC7A);
  static const brassDk = Color(0xFF8A6930);
  static const cream   = Color(0xFFF5EDDB);
  static const t2      = Color(0xFF9A8E78);
  static const t3      = Color(0xFF564E40);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
}

// ═══════════════════════════════════════════════════════════════
// PRE-BAKED CONFETTI DATA
// ═══════════════════════════════════════════════════════════════

class _ConfettiPiece {
  final double x, speed, size, rotation, rotationSpeed;
  final Color color;
  final int shape; // 0=circle, 1=square, 2=rectangle

  const _ConfettiPiece({
    required this.x,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.shape,
  });
}

final _kConfetti = List<_ConfettiPiece>.unmodifiable(
  List.generate(50, (i) {
    final rng = math.Random(i * 31 + 7);
    final colors = [
      const Color(0xFFD4A853), // Brass
      const Color(0xFFF0CC7A), // Light brass
      const Color(0xFFFFB7C5), // Pink
      const Color(0xFF5B9BD5), // Blue
      const Color(0xFF6D8B74), // Green
      const Color(0xFFE8A87C), // Peach
    ];
    return _ConfettiPiece(
      x: rng.nextDouble(),
      speed: 0.3 + rng.nextDouble() * 0.7,
      size: 4.0 + rng.nextDouble() * 8.0,
      rotation: rng.nextDouble() * math.pi * 2,
      rotationSpeed: (rng.nextDouble() - 0.5) * 4,
      color: colors[rng.nextInt(colors.length)],
      shape: rng.nextInt(3),
    );
  }),
);

// ═══════════════════════════════════════════════════════════════
// MAIN ARRIVAL SCREEN
// ═══════════════════════════════════════════════════════════════

class ArrivalScreen extends StatefulWidget {
  const ArrivalScreen({super.key});

  @override
  State<ArrivalScreen> createState() => _ArrivalScreenState();
}

class _ArrivalScreenState extends State<ArrivalScreen>
    with TickerProviderStateMixin {

  // ── Animation Controllers ──────────────────────────────────
  late AnimationController _confettiCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _contentCtrl;
  late AnimationController _statsCtrl;

  // ── Data ───────────────────────────────────────────────────
  final _storage = StorageService();
  JourneySession? _lastSession;
  int _streak = 0;
  double _totalHours = 0;
  int _totalSessions = 0;
  bool _isCompleted = true;

  // ── Note Input ─────────────────────────────────────────────
  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();
  final _audio = AudioService();
  bool _noteSaved = false;

  @override
  void initState() {
    super.initState();

    // Load data
    _loadData();

    // Initialize animations
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _statsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Start animation sequence
    _startAnimations();
  }

  void _loadData() {
    _streak = _storage.getStreak();
    _totalHours = _storage.getTotalHours();
    _totalSessions = _storage.getTotalSessions();

    final sessions = _storage.getAllSessions();
    if (sessions.isNotEmpty) {
      _lastSession = sessions.first;
      _isCompleted = _lastSession!.completed;
    }
  }

  Future<void> _startAnimations() async {
    // Delay then start content fade in
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _contentCtrl.forward();

    // If completed, show confetti
    if (_isCompleted) {
      HapticFeedback.heavyImpact();
      _confettiCtrl.forward();
      _audio.playArrivalBell();
    }

    // Delay then show stats
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    _statsCtrl.forward();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _glowCtrl.dispose();
    _contentCtrl.dispose();
    _statsCtrl.dispose();
    _noteController.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // CONDUCTOR'S ARRIVAL MESSAGE
  // ═══════════════════════════════════════════════════════════

  String get _arrivalMessage {
    if (!_isCompleted) {
      // Early stop messages
      final messages = [
        'The journey pauses, but the rails remain.',
        'Even the finest trains sometimes stop early.',
        'Rest now. The next departure awaits.',
        'The station welcomes all travelers, whenever they arrive.',
      ];
      return messages[DateTime.now().minute % messages.length];
    }

    // Completed journey messages
    if (_streak >= 7) {
      final messages = [
        'Seven days of unwavering discipline. The railway salutes you.',
        'A week of journeys completed. Remarkable consistency.',
        'The tracks remember those who travel faithfully.',
      ];
      return messages[DateTime.now().minute % messages.length];
    }

    if (_totalSessions >= 50) {
      return 'Another milestone for a seasoned traveler. '
          'The station knows your footsteps well.';
    }

    final messages = [
      'You have arrived at your destination with grace.',
      'Another journey completed. Well traveled.',
      'The platform welcomes you home.',
      'Destination reached. The journey was the reward.',
      'You traveled well. Until the next departure.',
    ];
    return messages[DateTime.now().minute % messages.length];
  }

  String get _title {
    if (!_isCompleted) {
      return 'JOURNEY PAUSED';
    }
    if (_streak >= 7) {
      return 'MAGNIFICENT';
    }
    return 'YOU HAVE ARRIVED';
  }

  Color get _accentColor {
    if (!_isCompleted) return _P.warning;
    if (_streak >= 7) return _P.brassLt;
    return _P.success;
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
            // Layer 1: Ambient glow
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.3),
                      radius: 1.4,
                      colors: [
                        _accentColor.withValues(
                            alpha: 0.04 + _glowCtrl.value * 0.05),
                        _P.ink,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Layer 2: Confetti (only if completed)
            if (_isCompleted)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _ConfettiPainter(t: _confettiCtrl.value),
                  ),
                ),
              ),

            // Layer 3: Main content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Arrival badge
                    _buildArrivalBadge(),

                    const SizedBox(height: 28),

                    // Title
                    _buildTitle(),

                    const SizedBox(height: 20),

                    // Conductor message
                    _buildConductorMessage(),

                    const SizedBox(height: 32),

                    // Session stats
                    _buildSessionStats(),

                    const SizedBox(height: 24),

                    // Streak celebration (if applicable)
                    if (_streak >= 3)
                      _buildStreakCelebration(),

                    const SizedBox(height: 24),

                    // Note input
                    _buildNoteInput(),

                    const SizedBox(height: 32),

                    // Return button
                    _buildReturnButton(),

                    const SizedBox(height: 40),
                  ],
                ),
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
                        _P.ink.withValues(alpha: 0.5),
                      ],
                      stops: const [0.5, 1.0],
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

  // ── Arrival Badge ──────────────────────────────────────────

  Widget _buildArrivalBadge() {
    return AnimatedBuilder(
      animation: _contentCtrl,
      builder: (_, child) {
        final scale = Curves.easeOutBack
            .transform(_contentCtrl.value.clamp(0.0, 1.0));
        final opacity = _contentCtrl.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale.clamp(0.0, 1.5),
            child: child,
          ),
        );
      },
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isCompleted
                ? [_P.brassLt, _P.brass, _P.brassDk]
                : [_P.warning, _P.warning.withValues(alpha: 0.7)],
          ),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Icon(
          _isCompleted ? Icons.check_rounded : Icons.pause_rounded,
          color: _P.ink,
          size: 48,
        ),
      ),
    );
  }

  // ── Title ──────────────────────────────────────────────────

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _contentCtrl,
      builder: (_, child) {
        final opacity = Curves.easeOut
            .transform(_contentCtrl.value.clamp(0.0, 1.0));
        final slide = (1 - _contentCtrl.value) * 20;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, slide),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Text(
            _title,
            style: GoogleFonts.cormorant(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _P.cream,
              letterSpacing: 4,
            ),
          ),
          if (_lastSession != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _lastSession!.routeName,
                  style: GoogleFonts.cormorant(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: _P.t2,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Conductor Message ──────────────────────────────────────

  Widget _buildConductorMessage() {
    return AnimatedBuilder(
      animation: _contentCtrl,
      builder: (_, child) {
        final opacity = Curves.easeOut
            .transform((_contentCtrl.value - 0.3).clamp(0.0, 1.0) / 0.7);

        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _P.panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _P.brass.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            // Decorative line
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _decoLine(),
                const SizedBox(width: 12),
                Icon(Icons.format_quote_rounded,
                    color: _P.brass.withValues(alpha: 0.4),
                    size: 20),
                const SizedBox(width: 12),
                _decoLine(),
              ],
            ),

            const SizedBox(height: 16),

            // Message
            Text(
              _arrivalMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorant(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: _P.cream,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 16),

            // Conductor signature
            Text(
              '— The Conductor',
              style: GoogleFonts.cormorant(
                fontSize: 13,
                color: _P.t3,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decoLine() {
    return Container(
      width: 30, height: 1,
      color: _P.brass.withValues(alpha: 0.3),
    );
  }

  // ── Session Stats ──────────────────────────────────────────

  Widget _buildSessionStats() {
    return AnimatedBuilder(
      animation: _statsCtrl,
      builder: (_, child) {
        final opacity = Curves.easeOut
            .transform(_statsCtrl.value.clamp(0.0, 1.0));
        final slide = (1 - _statsCtrl.value) * 30;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, slide),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: _P.brass.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _P.brass.withValues(alpha: 0.15),
                  ),
                  child: Icon(Icons.analytics_outlined,
                      color: _P.brass, size: 16),
                ),
                const SizedBox(width: 12),
                Text('SESSION STATS',
                    style: GoogleFonts.dmMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _P.brass,
                      letterSpacing: 2,
                    )),
              ],
            ),

            const SizedBox(height: 20),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.timer_outlined,
                    label: 'DURATION',
                    value: _lastSession?.formattedDuration ?? '—',
                    color: _P.brass,
                    ctrl: _statsCtrl,
                    delay: 0.0,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.local_fire_department_rounded,
                    label: 'STREAK',
                    value: '$_streak days',
                    color: const Color(0xFFFF6030),
                    ctrl: _statsCtrl,
                    delay: 0.15,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.hourglass_bottom_rounded,
                    label: 'TOTAL HOURS',
                    value: _totalHours.toStringAsFixed(1),
                    color: _P.brassLt,
                    ctrl: _statsCtrl,
                    delay: 0.3,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.train_rounded,
                    label: 'JOURNEYS',
                    value: '$_totalSessions',
                    color: const Color(0xFF5B9BD5),
                    ctrl: _statsCtrl,
                    delay: 0.45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Streak Celebration ─────────────────────────────────────

  Widget _buildStreakCelebration() {
    if (!_isCompleted) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _statsCtrl,
      builder: (_, child) {
        final opacity = Curves.easeOut
            .transform((_statsCtrl.value - 0.5).clamp(0.0, 1.0) * 2);

        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF6030).withValues(alpha: 0.15),
              const Color(0xFFFF9020).withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFFF6030).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Fire icon with glow
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6030).withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6030).withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFFF6030), size: 22),
            ),

            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _streak >= 7 ? '🔥 WEEK STREAK!' : '🔥 STREAK ACTIVE',
                    style: GoogleFonts.dmMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF6030),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_streak consecutive days of focus',
                    style: GoogleFonts.cormorant(
                      fontSize: 14,
                      color: _P.cream,
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

  // ── Note Input ─────────────────────────────────────────────

  Widget _buildNoteInput() {
    return AnimatedBuilder(
      animation: _statsCtrl,
      builder: (_, child) {
        final opacity = Curves.easeOut
            .transform((_statsCtrl.value - 0.6).clamp(0.0, 1.0) / 0.4);

        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _P.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: _P.brass.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit_note_rounded,
                    color: _P.brass.withValues(alpha: 0.6),
                    size: 20),
                const SizedBox(width: 10),
                Text('REFLECTION',
                    style: GoogleFonts.dmMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _P.t2,
                      letterSpacing: 2,
                    )),
                const Spacer(),
                if (_noteSaved)
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: _P.success, size: 14),
                      const SizedBox(width: 4),
                      Text('SAVED',
                          style: GoogleFonts.dmMono(
                            fontSize: 9,
                            color: _P.success,
                            letterSpacing: 1,
                          )),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Text field
            TextField(
              controller: _noteController,
              focusNode: _noteFocus,
              maxLines: 3,
              maxLength: 200,
              style: GoogleFonts.cormorant(
                fontSize: 16,
                color: _P.cream,
                fontStyle: FontStyle.italic,
              ),
              cursorColor: _P.brass,
              decoration: InputDecoration(
                hintText: 'What did you accomplish?',
                hintStyle: GoogleFonts.cormorant(
                  fontSize: 16,
                  color: _P.t3,
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                counterStyle: GoogleFonts.dmMono(
                  fontSize: 9,
                  color: _P.t3,
                ),
              ),
              onChanged: (_) {
                if (_noteSaved) {
                  setState(() => _noteSaved = false);
                }
              },
            ),

            const SizedBox(height: 12),

            // Save button
            GestureDetector(
              onTap: _saveNote,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _P.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _P.brass.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Text('SAVE NOTE',
                      style: GoogleFonts.dmMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _P.brass,
                        letterSpacing: 2,
                      )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveNote() {
    if (_noteController.text.trim().isEmpty) return;

    HapticFeedback.lightImpact();

    // TODO: Save note to session
    // For now, just show confirmation
    setState(() => _noteSaved = true);
    _noteFocus.unfocus();
  }

  // ── Return Button ──────────────────────────────────────────

  Widget _buildReturnButton() {
    return AnimatedBuilder(
      animation: _statsCtrl,
      builder: (_, child) {
        final opacity = Curves.easeOut
            .transform((_statsCtrl.value - 0.8).clamp(0.0, 1.0) / 0.2);

        return Opacity(opacity: opacity, child: child);
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.go(AppRouter.home);
        },
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_P.brassLt, _P.brass, _P.brassDk],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _P.brass.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home_rounded, color: _P.ink, size: 22),
              const SizedBox(width: 12),
              Text('RETURN TO STATION',
                  style: GoogleFonts.dmMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _P.ink,
                    letterSpacing: 2,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STAT ITEM WIDGET
// ═══════════════════════════════════════════════════════════════

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final AnimationController ctrl;
  final double delay;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.ctrl,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, child) {
        final t = ((ctrl.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final scale = Curves.easeOutBack.transform(t).clamp(0.0, 1.2);

        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.cormorant(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _P.cream,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmMono(
              fontSize: 8,
              color: _P.t3,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONFETTI PAINTER
// ═══════════════════════════════════════════════════════════════

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;

    for (final piece in _kConfetti) {
      // Calculate position
      final progress = (t * piece.speed * 1.5).clamp(0.0, 1.0);
      final x = piece.x * size.width +
          math.sin(t * math.pi * 4 + piece.rotation) * 30;
      final y = -20 + progress * (size.height + 100);

      // Fade out at the end
      final alpha = (1 - (progress - 0.7).clamp(0.0, 1.0) / 0.3).clamp(0.0, 1.0);
      if (alpha <= 0) continue;

      final rotation = piece.rotation + t * piece.rotationSpeed * math.pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final paint = Paint()
        ..color = piece.color.withValues(alpha: alpha * 0.8);

      switch (piece.shape) {
        case 0: // Circle
          canvas.drawCircle(Offset.zero, piece.size / 2, paint);
          break;
        case 1: // Square
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero,
                width: piece.size,
                height: piece.size),
            paint,
          );
          break;
        case 2: // Rectangle
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero,
                width: piece.size,
                height: piece.size * 0.4),
            paint,
          );
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter o) => o.t != t;
}