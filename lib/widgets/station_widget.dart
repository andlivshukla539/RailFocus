// lib/widgets/station_widget.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — STATION BUILDING WIDGET
//  A visual station that evolves from a simple platform to a
//  grand terminus as the user earns bricks through focus sessions.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
// STATION LEVEL DATA
// ═══════════════════════════════════════════════════════════════

class _StationLevel {
  final String name;
  final String emoji;
  final Color color;
  final int bricksNeeded; // cumulative threshold

  const _StationLevel({
    required this.name,
    required this.emoji,
    required this.color,
    required this.bricksNeeded,
  });
}

const List<_StationLevel> _levels = [
  _StationLevel(name: 'Empty Lot', emoji: '🏗️', color: Color(0xFF3E3A32), bricksNeeded: 0),
  _StationLevel(name: 'Wooden Platform', emoji: '🪵', color: Color(0xFF8B6914), bricksNeeded: 5),
  _StationLevel(name: 'Small Halt', emoji: '🚏', color: Color(0xFF6D8B74), bricksNeeded: 15),
  _StationLevel(name: 'Rural Station', emoji: '🏠', color: Color(0xFF5B9BD5), bricksNeeded: 30),
  _StationLevel(name: 'Town Depot', emoji: '🏘️', color: Color(0xFFD4963A), bricksNeeded: 50),
  _StationLevel(name: 'City Station', emoji: '🏢', color: Color(0xFFB8824A), bricksNeeded: 80),
  _StationLevel(name: 'Metro Hub', emoji: '🏙️', color: Color(0xFF9B85D4), bricksNeeded: 120),
  _StationLevel(name: 'Grand Station', emoji: '🏛️', color: Color(0xFFDAA520), bricksNeeded: 180),
  _StationLevel(name: 'Central Terminal', emoji: '🎭', color: Color(0xFFE040FB), bricksNeeded: 250),
  _StationLevel(name: 'Imperial Station', emoji: '👑', color: Color(0xFFFFD700), bricksNeeded: 350),
  _StationLevel(name: 'Grand Terminus', emoji: '🌟', color: Color(0xFFF7E7CE), bricksNeeded: 500),
];

// ═══════════════════════════════════════════════════════════════
// STATION WIDGET
// ═══════════════════════════════════════════════════════════════

class StationWidget extends StatelessWidget {
  final int bricks;
  final int level;
  final int bricksForNext;

  const StationWidget({
    super.key,
    required this.bricks,
    required this.level,
    required this.bricksForNext,
  });

  @override
  Widget build(BuildContext context) {
    final stationData = _levels[level.clamp(0, _levels.length - 1)];
    final nextData = level < _levels.length - 1
        ? _levels[level + 1]
        : null;
    final progress = bricksForNext > 0
        ? ((bricks - stationData.bricksNeeded) /
            (bricksForNext - stationData.bricksNeeded))
            .clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF141420),
        border: Border.all(
          color: stationData.color.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: stationData.color.withValues(alpha: 0.08),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ────────────────────────────────────
          Row(
            children: [
              // Station visual
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stationData.color.withValues(alpha: 0.15),
                  border: Border.all(
                    color: stationData.color.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: stationData.color.withValues(alpha: 0.2),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    stationData.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'YOUR STATION',
                          style: GoogleFonts.spaceMono(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF706A5C),
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'LVL $level',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: stationData.color,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stationData.name,
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF7E7CE),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Progress bar ──────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFF2A2A3A),
              valueColor: AlwaysStoppedAnimation(stationData.color),
            ),
          ),

          const SizedBox(height: 6),

          // ── Brick count + next level ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🧱', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  Text(
                    '$bricks bricks',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: stationData.color.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              if (nextData != null)
                Text(
                  'Next: ${nextData.name} (${nextData.bricksNeeded}🧱)',
                  style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    color: const Color(0xFF706A5C),
                  ),
                )
              else
                Text(
                  '✨ MAX LEVEL',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFD700),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
