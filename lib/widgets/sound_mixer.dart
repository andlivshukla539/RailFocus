// lib/widgets/sound_mixer.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — SOUND MIXER WIDGET
//  A bottom sheet with per-channel volume controls for
//  layering multiple ambient sounds during focus sessions.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/audio_service.dart';

// ═══════════════════════════════════════════════════════════════
// SOUND MIXER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════

class SoundMixerSheet extends StatefulWidget {
  const SoundMixerSheet({super.key});

  @override
  State<SoundMixerSheet> createState() => _SoundMixerSheetState();
}

class _SoundMixerSheetState extends State<SoundMixerSheet> {
  final _audio = AudioService();
  late double _ambientVol;
  late double _sfxVol;
  late bool _isMuted;

  @override
  void initState() {
    super.initState();
    _ambientVol = _audio.ambientVolume;
    _sfxVol = _audio.sfxVolume;
    _isMuted = _audio.isMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                const Text('🎧', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'SOUND MIXER',
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF7E7CE),
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                // Master mute
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await _audio.toggleMute();
                    setState(() => _isMuted = _audio.isMuted);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _isMuted
                          ? Colors.redAccent.withValues(alpha: 0.15)
                          : const Color(0xFF4CAF50).withValues(alpha: 0.15),
                    ),
                    child: Text(
                      _isMuted ? '🔇 MUTED' : '🔊 ON',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _isMuted ? Colors.redAccent : const Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Ambient volume
            _buildSlider(
              label: 'AMBIENT',
              emoji: '🏔️',
              value: _ambientVol,
              color: const Color(0xFF9B85D4),
              onChanged: (v) {
                setState(() => _ambientVol = v);
                _audio.setAmbientVolume(v);
              },
            ),

            const SizedBox(height: 16),

            // SFX volume
            _buildSlider(
              label: 'SFX',
              emoji: '🔔',
              value: _sfxVol,
              color: const Color(0xFFD4A574),
              onChanged: (v) {
                setState(() => _sfxVol = v);
                _audio.setSfxVolume(v);
              },
            ),

            const SizedBox(height: 16),

            // Divider
            Container(
              height: 1,
              color: const Color(0xFF2A2A3A),
            ),

            const SizedBox(height: 16),

            // Preset labels
            Text(
              'PRESETS',
              style: GoogleFonts.spaceMono(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF706A5C),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),

            // Preset buttons
            Row(
              children: [
                _presetButton('🌲 Forest', ambientVol: 0.4, sfxVol: 0.6),
                const SizedBox(width: 8),
                _presetButton('☕ Café', ambientVol: 0.3, sfxVol: 0.5),
                const SizedBox(width: 8),
                _presetButton('🎯 Zen', ambientVol: 0.2, sfxVol: 0.3),
                const SizedBox(width: 8),
                _presetButton('🔊 Loud', ambientVol: 0.8, sfxVol: 0.9),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required String emoji,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF706A5C),
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.15),
              thumbColor: color,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
              overlayColor: color.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.end,
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _presetButton(String label, {
    required double ambientVol,
    required double sfxVol,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _ambientVol = ambientVol;
            _sfxVol = sfxVol;
          });
          _audio.setAmbientVolume(ambientVol);
          _audio.setSfxVolume(sfxVol);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF1A1A2A),
            border: Border.all(
              color: const Color(0xFF2A2A3A),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF7E7CE).withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Show the sound mixer as a bottom sheet
void showSoundMixer(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const SoundMixerSheet(),
  );
}
