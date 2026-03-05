// lib/widgets/achievement_popup.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — ACHIEVEMENT UNLOCK POPUP
//  A dramatic golden overlay shown when a new achievement unlocks.
//  Auto-dismisses after 3.5s or on tap.
// ═══════════════════════════════════════════════════════════════


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/achievement_model.dart';
import '../services/audio_service.dart';

/// Shows a dramatic achievement-unlock overlay on top of the current screen.
/// Usage: AchievementPopup.show(context, achievement);
class AchievementPopup {
  AchievementPopup._();

  static OverlayEntry? _current;

  static void show(BuildContext context, Achievement achievement) {
    dismiss();
    HapticFeedback.heavyImpact();
    AudioService().playImportantClick();

    final overlay = Overlay.of(context);
    _current = OverlayEntry(
      builder:
          (_) =>
              _AchievementOverlay(achievement: achievement, onDismiss: dismiss),
    );
    overlay.insert(_current!);
  }

  static void dismiss() {
    _current?.remove();
    _current = null;
  }
}

class _AchievementOverlay extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const _AchievementOverlay({
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<_AchievementOverlay> createState() => _AchievementOverlayState();
}

class _AchievementOverlayState extends State<_AchievementOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _exitCtrl;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Auto dismiss after 3.5s
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) _dismiss();
    });
  }

  Future<void> _dismiss() async {
    await _exitCtrl.forward();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _glowCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_enterCtrl, _exitCtrl, _glowCtrl]),
      builder: (_, __) {
        final enter = Curves.easeOutBack.transform(
          _enterCtrl.value.clamp(0.0, 1.0),
        );
        final exit = _exitCtrl.value;
        final opacity = (enter * (1.0 - exit)).clamp(0.0, 1.0);
        final scale = (0.6 + enter * 0.4) * (1.0 - exit * 0.3);

        return GestureDetector(
          onTap: _dismiss,
          child: Material(
            color: Colors.black.withValues(alpha: 0.7 * opacity),
            child: Center(
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale.clamp(0.0, 1.5),
                  child: _buildCard(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    const brass = Color(0xFFD4A853);
    const brassLt = Color(0xFFF0CC7A);
    const brassDk = Color(0xFF8A6930);
    const ink = Color(0xFF07090F);
    const cream = Color(0xFFF5EDDB);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF131620),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: brass.withValues(alpha: 0.3 + _glowCtrl.value * 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: brass.withValues(alpha: 0.15 + _glowCtrl.value * 0.1),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trophy circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [brassLt, brass, brassDk]),
              boxShadow: [
                BoxShadow(
                  color: brass.withValues(alpha: 0.6),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.achievement.emoji,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // "ACHIEVEMENT UNLOCKED"
          Text(
            'ACHIEVEMENT UNLOCKED',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: brass,
              letterSpacing: 3,
            ),
          ),

          const SizedBox(height: 12),

          // Name
          Text(
            widget.achievement.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: cream,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            widget.achievement.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: cream.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // Decorative line
          Container(
            width: 50,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  brass.withValues(alpha: 0),
                  brass,
                  brass.withValues(alpha: 0),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'TAP TO DISMISS',
            style: GoogleFonts.spaceMono(
              fontSize: 8,
              color:
                  ink.withValues(alpha: 0.0) == ink
                      ? const Color(0xFF564E40)
                      : const Color(0xFF564E40),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

