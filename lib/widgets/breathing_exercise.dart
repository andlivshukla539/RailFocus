// lib/widgets/breathing_exercise.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — BREATHING EXERCISE
//  A calming breathing animation before focus sessions.
//  4-7-8 breathing: Inhale 4s, Hold 7s, Exhale 8s
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ═══════════════════════════════════════════════════════════════
// BREATHING SCREEN
// ═══════════════════════════════════════════════════════════════

class BreathingExercise extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const BreathingExercise({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<BreathingExercise> createState() => _BreathingExerciseState();
}

class _BreathingExerciseState extends State<BreathingExercise>
    with TickerProviderStateMixin {
  static const _inhale = 4; // Inhale seconds
  static const _hold = 7; // Hold seconds
  static const _exhale = 8; // Exhale seconds
  static const _totalCycle = _inhale + _hold + _exhale; // 19s per cycle
  static const _cycles = 2; // 2 cycles = ~38s

  late AnimationController _breathCtrl;
  late AnimationController _glowCtrl;

  String _phase = 'INHALE';
  int _currentCycle = 1;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();

    _breathCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalCycle * _cycles),
    )..addListener(_updatePhase);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _breathCtrl.forward().whenComplete(() {
      if (mounted) {
        setState(() => _isComplete = true);
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  void _updatePhase() {
    final totalElapsed = _breathCtrl.value * _totalCycle * _cycles;
    final cycleProgress = totalElapsed % _totalCycle;
    final cycle = (totalElapsed / _totalCycle).floor() + 1;

    String newPhase;
    if (cycleProgress < _inhale) {
      newPhase = 'INHALE';
    } else if (cycleProgress < _inhale + _hold) {
      newPhase = 'HOLD';
    } else {
      newPhase = 'EXHALE';
    }

    if (newPhase != _phase || cycle != _currentCycle) {
      if (newPhase != _phase) HapticFeedback.selectionClick();
      setState(() {
        _phase = newPhase;
        _currentCycle = cycle.clamp(1, _cycles);
      });
    }
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  double get _circleScale {
    final totalElapsed = _breathCtrl.value * _totalCycle * _cycles;
    final cycleProgress = totalElapsed % _totalCycle;

    if (cycleProgress < _inhale) {
      // Inhaling: expand 0.4 → 1.0
      return 0.4 + 0.6 * (cycleProgress / _inhale);
    } else if (cycleProgress < _inhale + _hold) {
      // Holding: stay at 1.0
      return 1.0;
    } else {
      // Exhaling: shrink 1.0 → 0.4
      final exhaleProgress = (cycleProgress - _inhale - _hold) / _exhale;
      return 1.0 - 0.6 * exhaleProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.2,
          colors: [Color(0xFF0F1020), Color(0xFF07090F)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'BREATHE',
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD4A853),
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onSkip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF706A5C).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'SKIP →',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF706A5C),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Breathing circle
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _breathCtrl,
                  builder: (_, __) {
                    final scale = _circleScale;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cycle indicator
                        Text(
                          '$_currentCycle / $_cycles',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: const Color(0xFF706A5C),
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // The breathing circle
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow ring
                            AnimatedBuilder(
                              animation: _glowCtrl,
                              builder: (_, __) => Container(
                                width: 200 * scale + 20,
                                height: 200 * scale + 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF9B85D4).withValues(
                                        alpha: 0.1 + _glowCtrl.value * 0.1,
                                      ),
                                      blurRadius: 40,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Main circle
                            Container(
                              width: 200 * scale,
                              height: 200 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _phaseColor.withValues(alpha: 0.3),
                                    _phaseColor.withValues(alpha: 0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: _phaseColor.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                            ),

                            // Inner dot
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _phaseColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Phase label
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _isComplete ? '✨ READY' : _phase,
                            key: ValueKey(_isComplete ? 'done' : _phase),
                            style: GoogleFonts.cinzel(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _phaseColor,
                              letterSpacing: 6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _phaseInstruction,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFFF5EDDB).withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _phaseColor {
    switch (_phase) {
      case 'INHALE':
        return const Color(0xFF9B85D4); // Purple
      case 'HOLD':
        return const Color(0xFFD4A853); // Brass
      case 'EXHALE':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFFF5EDDB);
    }
  }

  String get _phaseInstruction {
    if (_isComplete) return 'Your mind is clear';
    switch (_phase) {
      case 'INHALE':
        return 'Breathe in slowly through your nose';
      case 'HOLD':
        return 'Hold your breath gently';
      case 'EXHALE':
        return 'Release slowly through your mouth';
      default:
        return '';
    }
  }
}
