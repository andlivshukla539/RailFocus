// lib/screens/achievements_screen.dart
// ═══════════════════════════════════════════════════════════════
//  RAIL FOCUS — TROPHY ROOM
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/achievement_model.dart';
import '../services/achievement_service.dart';

// ═══════════════════════════════════════════════════════════════
// PALETTE
// ═══════════════════════════════════════════════════════════════

abstract class _P {
  static const bg = Color(0xFF06070E);
  static const card = Color(0xFF0C0E18);
  static const surface = Color(0xFF111320);
  static const rim = Color(0xFF1C1F2E);
  static const gold = Color(0xFFD4A855);
  static const goldLt = Color(0xFFEDCB80);
  static const cream = Color(0xFFEDE6D8);
  static const muted = Color(0xFF706A5C);
  static const dim = Color(0xFF3E3A32);
}

// ═══════════════════════════════════════════════════════════════
// ACHIEVEMENTS SCREEN
// ═══════════════════════════════════════════════════════════════

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  final _achievementService = AchievementService();
  late List<Achievement> _achievements;
  late AnimationController _shimmer;
  AchievementCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _achievements = _achievementService.getAll();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  List<Achievement> get _filtered {
    if (_selectedCategory == null) return _achievements;
    return _achievements.where((a) => a.category == _selectedCategory).toList();
  }

  int get _unlockedCount => _achievements.where((a) => a.isUnlocked).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildProgress()),
            SliverToBoxAdapter(child: _buildCategoryFilter()),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _AchievementCard(
                    achievement: _filtered[index],
                    shimmer: _shimmer,
                  ),
                  childCount: _filtered.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _P.surface,
                border: Border.all(color: _P.rim, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _P.cream,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TROPHY ROOM',
                  style: GoogleFonts.cinzel(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _P.gold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your journey milestones',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: _P.muted,
                  ),
                ),
              ],
            ),
          ),
          Text('🏆', style: const TextStyle(fontSize: 28)),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final total = _achievements.length;
    final unlocked = _unlockedCount;
    final progress = total > 0 ? unlocked / total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.rim, width: 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$unlocked / $total unlocked',
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    color: _P.cream,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    color: _P.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: _P.surface,
                color: _P.gold,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _CategoryChip(
              label: 'All',
              emoji: '✦',
              selected: _selectedCategory == null,
              onTap: () => setState(() => _selectedCategory = null),
            ),
            ...AchievementCategory.values.map(
              (cat) => _CategoryChip(
                label: cat.label,
                emoji: cat.emoji,
                selected: _selectedCategory == cat,
                onTap: () => setState(() => _selectedCategory = cat),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY CHIP
// ═══════════════════════════════════════════════════════════════

class _CategoryChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _P.gold.withValues(alpha: 0.15) : _P.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _P.gold : _P.rim,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  color: selected ? _P.gold : _P.muted,
                  letterSpacing: 1,
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
// ACHIEVEMENT CARD
// ═══════════════════════════════════════════════════════════════

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final AnimationController shimmer;

  const _AchievementCard({required this.achievement, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;

    return AnimatedBuilder(
      animation: shimmer,
      builder: (context, child) {
        final glowIntensity =
            unlocked
                ? (math.sin(shimmer.value * math.pi * 2) * 0.3 + 0.5)
                : 0.0;

        return Container(
          decoration: BoxDecoration(
            color: _P.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  unlocked
                      ? achievement.glowColor.withValues(
                        alpha: 0.4 + glowIntensity * 0.3,
                      )
                      : _P.rim,
              width: unlocked ? 1.5 : 1,
            ),
            boxShadow:
                unlocked
                    ? [
                      BoxShadow(
                        color: achievement.glowColor.withValues(
                          alpha: glowIntensity * 0.2,
                        ),
                        blurRadius: 16,
                        spreadRadius: -2,
                      ),
                    ]
                    : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji / Lock icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      unlocked
                          ? achievement.glowColor.withValues(alpha: 0.15)
                          : _P.surface,
                  border: Border.all(
                    color:
                        unlocked
                            ? achievement.glowColor.withValues(alpha: 0.4)
                            : _P.dim,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    unlocked ? achievement.emoji : '🔒',
                    style: TextStyle(
                      fontSize: 22,
                      color: unlocked ? null : _P.dim.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  unlocked ? achievement.name : '???',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: unlocked ? _P.cream : _P.dim,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 9,
                    color: unlocked ? _P.muted : _P.dim.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
