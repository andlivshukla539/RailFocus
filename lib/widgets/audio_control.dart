// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — AUDIO CONTROL WIDGET
//  Theme: Brass Volume Toggle
//
//  A floating circular button that toggles mute/unmute.
//  Designed to sit in the corner of the Focus Screen,
//  but can be placed on any screen.
//
//  USAGE:
//    const AudioControlButton()   ← that's it!
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_service.dart';
import '../widgets/sound_mixer.dart';

// ═══════════════════════════════════════════════════════════════
// PALETTE (matches history_screen.dart _P pattern)
// ═══════════════════════════════════════════════════════════════

class _C {
  static const ink = Color(0xFF07090F);
  static const panel = Color(0xFF131620);
  static const surface = Color(0xFF1A1E2C);
  static const brass = Color(0xFFD4A853);
  static const cream = Color(0xFFF5EDDB);
  static const t2 = Color(0xFF9A8E78);
}

// ═══════════════════════════════════════════════════════════════
// COMPACT MUTE BUTTON
// ═══════════════════════════════════════════════════════════════
// A simple circular button — tap to toggle mute.
// Shows a speaker icon when unmuted, muted icon when muted.

class AudioControlButton extends StatefulWidget {
  /// Optional size override (default 44px — good touch target).
  final double size;

  const AudioControlButton({super.key, this.size = 44});

  @override
  State<AudioControlButton> createState() => _AudioControlButtonState();
}

class _AudioControlButtonState extends State<AudioControlButton>
    with SingleTickerProviderStateMixin {
  // Access the singleton audio service.
  final _audio = AudioService();

  // Animation controller for the icon transition (speaker ↔ muted).
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      // If already muted on init, start in the "muted" position.
      value: _audio.isMuted ? 1.0 : 0.0,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // Handle tap — toggle mute and animate the icon.
  Future<void> _onTap() async {
    // Haptic feedback for premium feel.
    HapticFeedback.lightImpact();

    // Toggle mute state in the audio service.
    final isMuted = await _audio.toggleMute();

    // Animate the icon: forward = muted, reverse = unmuted.
    if (isMuted) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }

    // Rebuild to update visual state.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isMuted = _audio.isMuted;

    return GestureDetector(
      onTap: _onTap,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showSoundMixer(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          // Circle shape.
          shape: BoxShape.circle,

          // Background changes subtly based on mute state.
          color:
              isMuted
                  ? _C
                      .surface // Dimmer when muted
                  : _C.panel, // Slightly brighter when active
          // Border — brass accent when unmuted, subtle when muted.
          border: Border.all(
            color:
                isMuted
                    ? _C.t2.withValues(alpha: 0.2)
                    : _C.brass.withValues(alpha: 0.3),
            width: 1,
          ),

          // Subtle glow when audio is active (unmuted).
          boxShadow:
              isMuted
                  ? [] // No glow when muted
                  : [
                    BoxShadow(
                      color: _C.brass.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
        ),

        // The icon — animates between speaker and muted speaker.
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            // Key forces AnimatedSwitcher to animate when icon changes.
            key: ValueKey(isMuted),
            color: isMuted ? _C.t2 : _C.brass,
            size: widget.size * 0.45, // Icon is ~45% of button size
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXPANDED AUDIO CONTROL (for Settings Screen — future use)
// ═══════════════════════════════════════════════════════════════
// A larger control with volume sliders for ambient and SFX.
// We'll use this in Phase 9 (Settings Screen).

class AudioControlPanel extends StatefulWidget {
  const AudioControlPanel({super.key});

  @override
  State<AudioControlPanel> createState() => _AudioControlPanelState();
}

class _AudioControlPanelState extends State<AudioControlPanel> {
  final _audio = AudioService();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.brass.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Title ──────────────────────────────
          Row(
            children: [
              const Icon(Icons.music_note_rounded, color: _C.brass, size: 18),
              const SizedBox(width: 10),
              Text(
                'SOUND',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _C.brass,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              // Mute toggle on the right
              const AudioControlButton(size: 36),
            ],
          ),

          const SizedBox(height: 20),

          // ── Ambient Volume Slider ─────────────────────
          _VolumeSlider(
            label: 'AMBIENT',
            icon: Icons.train_rounded,
            value: _audio.ambientVolume,
            isMuted: _audio.isMuted,
            onChanged: (val) {
              setState(() {});
              _audio.setAmbientVolume(val);
            },
          ),

          const SizedBox(height: 16),

          // ── SFX Volume Slider ─────────────────────────
          _VolumeSlider(
            label: 'EFFECTS',
            icon: Icons.notifications_active_rounded,
            value: _audio.sfxVolume,
            isMuted: _audio.isMuted,
            onChanged: (val) {
              setState(() {});
              _audio.setSfxVolume(val);
            },
          ),
        ],
      ),
    );
  }
}

// ── Volume Slider Sub-Widget ─────────────────────────────────

class _VolumeSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final bool isMuted;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.isMuted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon
        Icon(
          icon,
          color: isMuted ? _C.t2.withValues(alpha: 0.3) : _C.brass,
          size: 16,
        ),

        const SizedBox(width: 10),

        // Label
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: isMuted ? _C.t2.withValues(alpha: 0.3) : _C.t2,
              letterSpacing: 1,
            ),
          ),
        ),

        // Slider
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              // Track (the line the thumb slides on).
              activeTrackColor:
                  isMuted ? _C.t2.withValues(alpha: 0.2) : _C.brass,
              inactiveTrackColor: _C.surface,
              trackHeight: 3,

              // Thumb (the draggable circle).
              thumbColor: isMuted ? _C.t2 : _C.cream,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),

              // No overlay (the ripple when dragging).
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              // Disable slider when muted (visual feedback).
              onChanged: isMuted ? null : onChanged,
            ),
          ),
        ),

        // Percentage display
        SizedBox(
          width: 32,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.right,
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              color: isMuted ? _C.t2.withValues(alpha: 0.3) : _C.t2,
            ),
          ),
        ),
      ],
    );
  }
}
