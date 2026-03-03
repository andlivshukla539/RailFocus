// lib/widgets/daily_challenge_card.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — DAILY CHALLENGE CARD
//  Shows the daily challenge with progress and brick reward.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/daily_challenge.dart';

class DailyChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final bool isCompleted;
  final double progress; // 0.0 → 1.0

  const DailyChallengeCard({
    super.key,
    required this.challenge,
    required this.isCompleted,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isCompleted
        ? const Color(0xFF4CAF50)
        : const Color(0xFFD4A574);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF141420),
        border: Border.all(
          color: accentColor.withValues(alpha: isCompleted ? 0.4 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.12),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                isCompleted ? '✅' : challenge.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Challenge info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'DAILY CHALLENGE',
                      style: GoogleFonts.spaceMono(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: accentColor.withValues(alpha: 0.6),
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '+${challenge.brickReward} 🧱',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isCompleted
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFD4A574),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  challenge.title,
                  style: GoogleFonts.cinzel(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF7E7CE),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCompleted ? 'Completed! Bricks awarded.' : challenge.subtitle,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 11,
                    color: const Color(0xFFF7E7CE).withValues(alpha: 0.5),
                    fontStyle: isCompleted ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: const Color(0xFF2A2A3A),
                      valueColor: AlwaysStoppedAnimation(accentColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
