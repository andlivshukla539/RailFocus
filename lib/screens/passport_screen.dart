// lib/screens/passport_screen.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — FOCUS PASSPORT
//  A visual stamp collection — earn stamps for focus milestones.
//  Each stamp is themed after a real train route & destination.
// ═══════════════════════════════════════════════════════════════

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../services/storage_service.dart';
import '../theme/luxe_theme.dart';

// ═══════════════════════════════════════════════════════════════
// PASSPORT STAMP MODEL
// ═══════════════════════════════════════════════════════════════

class PassportStamp {
  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final bool Function(int sessions, double hours, int streak, int bestStreak, int routes) check;

  const PassportStamp({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.check,
  });
}

// ═══════════════════════════════════════════════════════════════
// ALL STAMPS — 12 collectible stamps
// ═══════════════════════════════════════════════════════════════

final List<PassportStamp> allStamps = [
  // ── Journey milestones ──
  PassportStamp(
    id: 'first_journey',
    emoji: '🎫',
    title: 'First Ticket',
    subtitle: 'Complete 1 session',
    color: const Color(0xFFD4A574),
    check: (s, h, st, bs, r) => s >= 1,
  ),
  PassportStamp(
    id: 'frequent_traveler',
    emoji: '🚂',
    title: 'Frequent Traveller',
    subtitle: 'Complete 10 sessions',
    color: const Color(0xFF5B9BD5),
    check: (s, h, st, bs, r) => s >= 10,
  ),
  PassportStamp(
    id: 'seasoned_voyager',
    emoji: '🧳',
    title: 'Seasoned Voyager',
    subtitle: 'Complete 50 sessions',
    color: const Color(0xFF6D8B74),
    check: (s, h, st, bs, r) => s >= 50,
  ),
  PassportStamp(
    id: 'legendary_conductor',
    emoji: '👑',
    title: 'Legendary Conductor',
    subtitle: 'Complete 100 sessions',
    color: const Color(0xFFDAA520),
    check: (s, h, st, bs, r) => s >= 100,
  ),

  // ── Hours milestones ──
  PassportStamp(
    id: 'dawn_departure',
    emoji: '🌅',
    title: 'Dawn Departure',
    subtitle: 'Focus for 1 hour total',
    color: const Color(0xFFFFB7C5),
    check: (s, h, st, bs, r) => h >= 1,
  ),
  PassportStamp(
    id: 'mountain_pass',
    emoji: '🏔️',
    title: 'Mountain Pass',
    subtitle: 'Focus for 10 hours total',
    color: const Color(0xFF8FC4E8),
    check: (s, h, st, bs, r) => h >= 10,
  ),
  PassportStamp(
    id: 'transcontinental',
    emoji: '🌍',
    title: 'Transcontinental',
    subtitle: 'Focus for 50 hours total',
    color: const Color(0xFF00D9FF),
    check: (s, h, st, bs, r) => h >= 50,
  ),

  // ── Streak milestones ──
  PassportStamp(
    id: 'iron_will',
    emoji: '🔥',
    title: 'Iron Will',
    subtitle: '3-day streak',
    color: const Color(0xFFFF6B35),
    check: (s, h, st, bs, r) => bs >= 3,
  ),
  PassportStamp(
    id: 'unstoppable',
    emoji: '⚡',
    title: 'Unstoppable',
    subtitle: '7-day streak',
    color: const Color(0xFFFFD700),
    check: (s, h, st, bs, r) => bs >= 7,
  ),
  PassportStamp(
    id: 'eternal_express',
    emoji: '💎',
    title: 'Eternal Express',
    subtitle: '30-day streak',
    color: const Color(0xFFE040FB),
    check: (s, h, st, bs, r) => bs >= 30,
  ),

  // ── Explorer milestones ──
  PassportStamp(
    id: 'explorer',
    emoji: '🗺️',
    title: 'Explorer',
    subtitle: 'Travel 3 unique routes',
    color: const Color(0xFFD4963A),
    check: (s, h, st, bs, r) => r >= 3,
  ),
  PassportStamp(
    id: 'world_tour',
    emoji: '🌟',
    title: 'World Tour',
    subtitle: 'Travel all routes',
    color: const Color(0xFFF7E7CE),
    check: (s, h, st, bs, r) => r >= 5,
  ),
];

// ═══════════════════════════════════════════════════════════════
// PALETTE
// ═══════════════════════════════════════════════════════════════

class _P {
  _P._();
  static const ink = Color(0xFF0A0A0F);
  static const card = Color(0xFF141420);
  static const cream = Color(0xFFF7E7CE);
  static const brass = Color(0xFFD4A574);
  static const dim = Color(0xFF2A2A3A);
}

// ═══════════════════════════════════════════════════════════════
// PASSPORT SCREEN
// ═══════════════════════════════════════════════════════════════

class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});
  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen>
    with SingleTickerProviderStateMixin {
  final _storage = StorageService();
  final _passportKey = GlobalKey();

  int _sessions = 0;
  double _hours = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _routes = 0;
  int _unlocked = 0;

  late AnimationController _enterCtrl;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _load();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  void _load() {
    _sessions = _storage.getTotalSessions();
    _hours = _storage.getTotalHours();
    _streak = _storage.getStreak();
    _bestStreak = _storage.getBestStreak();
    _routes = _storage.getRoutesTraveled();
    _unlocked = allStamps
        .where((s) => s.check(_sessions, _hours, _streak, _bestStreak, _routes))
        .length;
    if (mounted) setState(() {});
  }

  Future<void> _sharePassport() async {
    try {
      HapticFeedback.mediumImpact();

      final boundary = _passportKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/railfocus_passport.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🛂 My RailFocus Passport — $_unlocked/${allStamps.length} stamps collected! 🚂',
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _P.ink,
        body: SafeArea(
          child: FadeTransition(
            opacity: _enterCtrl,
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildHeader(),
                const SizedBox(height: 8),
                _buildProgressBar(),
                const SizedBox(height: 16),
                Expanded(
                  child: RepaintBoundary(
                    key: _passportKey,
                    child: Container(
                      color: _P.ink,
                      child: _buildStampGrid(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _P.dim.withValues(alpha: 0.5),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: _P.cream, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FOCUS PASSPORT',
                  style: GoogleFonts.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _P.cream,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_unlocked of ${allStamps.length} stamps collected',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: _P.brass.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _sharePassport,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _P.brass.withValues(alpha: 0.15),
                border: Border.all(color: _P.brass.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.share_rounded,
                  color: _P.brass, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ────────────────────────────────────────────

  Widget _buildProgressBar() {
    final progress = allStamps.isEmpty ? 0.0 : _unlocked / allStamps.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: _P.dim,
              valueColor: AlwaysStoppedAnimation(
                _unlocked == allStamps.length
                    ? const Color(0xFFFFD700)
                    : _P.brass,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% complete',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  color: _P.cream.withValues(alpha: 0.4),
                ),
              ),
              if (_unlocked == allStamps.length)
                Text(
                  '✨ MASTER TRAVELLER',
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
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

  // ── Stamp grid ──────────────────────────────────────────────

  Widget _buildStampGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: allStamps.length,
      itemBuilder: (context, index) {
        final stamp = allStamps[index];
        final earned = stamp.check(
            _sessions, _hours, _streak, _bestStreak, _routes);
        return _StampCard(
          stamp: stamp,
          earned: earned,
          index: index,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STAMP CARD
// ═══════════════════════════════════════════════════════════════

class _StampCard extends StatelessWidget {
  final PassportStamp stamp;
  final bool earned;
  final int index;

  const _StampCard({
    required this.stamp,
    required this.earned,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: earned ? _P.card : _P.card.withValues(alpha: 0.5),
        border: Border.all(
          color: earned
              ? stamp.color.withValues(alpha: 0.5)
              : _P.dim.withValues(alpha: 0.3),
          width: earned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: earned
                ? stamp.color.withValues(alpha: 0.15)
                : Colors.transparent,
            blurRadius: earned ? 20 : 0,
            spreadRadius: earned ? -2 : 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Earned glow overlay
          if (earned)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      stamp.color.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stamp circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: earned
                        ? stamp.color.withValues(alpha: 0.15)
                        : _P.dim.withValues(alpha: 0.3),
                    border: Border.all(
                      color: earned
                          ? stamp.color.withValues(alpha: 0.6)
                          : _P.dim.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    boxShadow: earned
                        ? [
                            BoxShadow(
                              color: stamp.color.withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      earned ? stamp.emoji : '🔒',
                      style: TextStyle(
                        fontSize: earned ? 28 : 22,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  stamp.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cinzel(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: earned
                        ? _P.cream
                        : _P.cream.withValues(alpha: 0.3),
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 4),

                // Subtitle
                Text(
                  stamp.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: earned
                        ? stamp.color.withValues(alpha: 0.7)
                        : _P.cream.withValues(alpha: 0.2),
                  ),
                ),

                if (earned) ...[
                  const SizedBox(height: 6),
                  Text(
                    '✓ STAMPED',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: stamp.color.withValues(alpha: 0.6),
                      letterSpacing: 2,
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
