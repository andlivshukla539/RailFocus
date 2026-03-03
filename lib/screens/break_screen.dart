// lib/screens/break_screen.dart
// ═══════════════════════════════════════════════════════════════
//  RAIL FOCUS — BREAK / REST STOP SCREEN
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
// PALETTE
// ═══════════════════════════════════════════════════════════════

abstract class _P {
  static const bg = Color(0xFF06070E);
  static const card = Color(0xFF0C0E18);
  static const surface = Color(0xFF111320);
  static const rim = Color(0xFF1C1F2E);
  static const gold = Color(0xFFD4A855);
  static const cream = Color(0xFFEDE6D8);
  static const muted = Color(0xFF706A5C);
  static const teal = Color(0xFF00D9FF);
}

// ═══════════════════════════════════════════════════════════════
// STRETCH EXERCISES
// ═══════════════════════════════════════════════════════════════

class _Exercise {
  final String name;
  final String emoji;
  final String instruction;
  final int seconds;

  const _Exercise({
    required this.name,
    required this.emoji,
    required this.instruction,
    required this.seconds,
  });
}

const _exercises = [
  _Exercise(
    name: 'Neck Roll',
    emoji: '🔄',
    instruction: 'Slowly roll your head in a circle, 5 times each direction',
    seconds: 30,
  ),
  _Exercise(
    name: 'Shoulder Shrug',
    emoji: '💪',
    instruction:
        'Raise shoulders to ears, hold 5 seconds, release. Repeat 5 times',
    seconds: 30,
  ),
  _Exercise(
    name: 'Wrist Stretch',
    emoji: '🤲',
    instruction: 'Extend arm, pull fingers back gently. Hold 15s each hand',
    seconds: 30,
  ),
  _Exercise(
    name: 'Standing Stretch',
    emoji: '🧍',
    instruction: 'Stand up, reach for the ceiling, then touch your toes',
    seconds: 20,
  ),
  _Exercise(
    name: 'Eye Rest',
    emoji: '👀',
    instruction: 'Look at something 20 feet away for 20 seconds',
    seconds: 20,
  ),
];

const _mindfulTips = [
  'Take a moment to notice your breathing. Each exhale releases tension.',
  'Close your eyes and listen to the silence between sounds.',
  'Place both feet flat on the ground. Feel the connection to the earth.',
  'Think of one thing you\'re grateful for right now.',
  'Notice the temperature of the air on your skin.',
  'Scan your body from head to toe. Release any tension you find.',
  'Smile softly. Even a forced smile releases endorphins.',
];

// ═══════════════════════════════════════════════════════════════
// BREAK SCREEN
// ═══════════════════════════════════════════════════════════════

class BreakScreen extends StatefulWidget {
  final int breakMinutes;
  final VoidCallback? onResume;

  const BreakScreen({super.key, this.breakMinutes = 5, this.onResume});

  @override
  State<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends State<BreakScreen>
    with TickerProviderStateMixin {
  late final AnimationController _breatheCtrl;
  late final AnimationController _glowCtrl;
  late int _breakSec;
  Timer? _timer;
  bool _breathingMode = true;
  int _exerciseIndex = 0;
  late String _tip;

  // Breathing: 4s inhale, 4s hold, 4s exhale = 12s cycle
  String get _breathePhase {
    final v = _breatheCtrl.value;
    if (v < 0.33) return 'Inhale';
    if (v < 0.66) return 'Hold';
    return 'Exhale';
  }

  @override
  void initState() {
    super.initState();
    _breakSec = widget.breakMinutes * 60;
    _tip = _mindfulTips[math.Random().nextInt(_mindfulTips.length)];

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breatheCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_breakSec <= 0) {
        _timer?.cancel();
        if (mounted) _onResume();
        return;
      }
      if (mounted) setState(() => _breakSec--);
    });
  }

  void _onResume() {
    HapticFeedback.mediumImpact();
    if (widget.onResume != null) {
      widget.onResume!();
    } else {
      Navigator.pop(context);
    }
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildHeader(),
            const Spacer(flex: 1),
            if (_breathingMode)
              _buildBreathingCircle()
            else
              _buildExerciseCard(),
            const Spacer(flex: 1),
            _buildTip(),
            const SizedBox(height: 16),
            _buildModeToggle(),
            const SizedBox(height: 16),
            _buildResumeButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REST STOP',
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _P.teal,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'Take a moment to recharge',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: _P.muted,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _P.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _P.rim, width: 1),
            ),
            child: Text(
              _formatTime(_breakSec),
              style: GoogleFonts.spaceMono(
                fontSize: 16,
                color: _P.cream,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingCircle() {
    return AnimatedBuilder(
      animation: _breatheCtrl,
      builder: (context, _) {
        final phase = _breatheCtrl.value;
        double scale;
        if (phase < 0.33) {
          // Inhale: grow
          scale = 0.6 + (phase / 0.33) * 0.4;
        } else if (phase < 0.66) {
          // Hold: stay big
          scale = 1.0;
        } else {
          // Exhale: shrink
          scale = 1.0 - ((phase - 0.66) / 0.34) * 0.4;
        }

        return Column(
          children: [
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (context, child) {
                return Container(
                  width: 200 * scale,
                  height: 200 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _P.teal.withValues(
                          alpha: 0.25 + _glowCtrl.value * 0.15,
                        ),
                        _P.teal.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.6, 1],
                    ),
                    border: Border.all(
                      color: _P.teal.withValues(
                        alpha: 0.4 + _glowCtrl.value * 0.2,
                      ),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _P.teal.withValues(
                          alpha: 0.2 + _glowCtrl.value * 0.1,
                        ),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _breathePhase,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: _P.cream,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              '4-4-4 Breathing',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                color: _P.muted,
                letterSpacing: 1,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExerciseCard() {
    final exercise = _exercises[_exerciseIndex % _exercises.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _P.rim, width: 1),
        ),
        child: Column(
          children: [
            Text(exercise.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              exercise.name,
              style: GoogleFonts.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _P.cream,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.instruction,
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 15,
                color: _P.muted,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '~${exercise.seconds}s',
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                color: _P.teal,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleBtn(Icons.arrow_back_rounded, () {
                  setState(
                    () =>
                        _exerciseIndex = (_exerciseIndex - 1).clamp(
                          0,
                          _exercises.length - 1,
                        ),
                  );
                }),
                const SizedBox(width: 24),
                Text(
                  '${_exerciseIndex + 1}/${_exercises.length}',
                  style: GoogleFonts.spaceMono(fontSize: 11, color: _P.muted),
                ),
                const SizedBox(width: 24),
                _circleBtn(Icons.arrow_forward_rounded, () {
                  setState(
                    () =>
                        _exerciseIndex =
                            (_exerciseIndex + 1) % _exercises.length,
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _P.surface,
          border: Border.all(color: _P.rim),
        ),
        child: Icon(icon, color: _P.cream, size: 16),
      ),
    );
  }

  Widget _buildTip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _P.rim.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Text('💭', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _tip,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 13,
                  color: _P.cream.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _breathingMode = true);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  _breathingMode ? _P.teal.withValues(alpha: 0.15) : _P.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _breathingMode ? _P.teal : _P.rim),
            ),
            child: Text(
              '🧘 Breathe',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                color: _breathingMode ? _P.teal : _P.muted,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _breathingMode = false);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  !_breathingMode
                      ? _P.teal.withValues(alpha: 0.15)
                      : _P.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: !_breathingMode ? _P.teal : _P.rim),
            ),
            child: Text(
              '🏋️ Stretch',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                color: !_breathingMode ? _P.teal : _P.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumeButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTap: _onResume,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4A855), Color(0xFFB8824A)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _P.gold.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'RESUME JOURNEY',
              style: GoogleFonts.cinzel(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _P.bg,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
