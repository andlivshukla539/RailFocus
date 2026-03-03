// lib/screens/share_card_screen.dart
// ═══════════════════════════════════════════════════════════════
//  RAIL FOCUS — SHAREABLE SESSION CARD
// ═══════════════════════════════════════════════════════════════

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../services/storage_service.dart';

// ═══════════════════════════════════════════════════════════════
// PALETTE
// ═══════════════════════════════════════════════════════════════

abstract class _P {
  static const bg = Color(0xFF06070E);
  static const card = Color(0xFF0A0C16);
  static const surface = Color(0xFF111320);
  static const rim = Color(0xFF1C1F2E);
  static const gold = Color(0xFFD4A855);
  static const goldLt = Color(0xFFEDCB80);
  static const cream = Color(0xFFEDE6D8);
  static const muted = Color(0xFF706A5C);
  static const copper = Color(0xFFB8824A);
}

// ═══════════════════════════════════════════════════════════════
// SHARE CARD SCREEN
// ═══════════════════════════════════════════════════════════════

class ShareCardScreen extends StatefulWidget {
  final String routeName;
  final String routeEmoji;
  final int durationMinutes;
  final DateTime sessionDate;
  final String? mood;
  final String? goal;

  const ShareCardScreen({
    super.key,
    required this.routeName,
    required this.routeEmoji,
    required this.durationMinutes,
    required this.sessionDate,
    this.mood,
    this.goal,
  });

  @override
  State<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends State<ShareCardScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  final _storage = StorageService();
  bool _sharing = false;
  late AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Future<void> _shareCard() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    HapticFeedback.mediumImpact();

    try {
      // Capture the card as an image
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/railfocus_journey.png');
      await file.writeAsBytes(pngBytes);

      // Share
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '🚂 Just completed a ${widget.durationMinutes}min focus journey on ${widget.routeName}! #RailFocus',
      );
    } catch (e) {
      debugPrint('Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share: $e'),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = _storage.getStreak();
    final totalHours = _storage.getTotalHours();

    return Scaffold(
      backgroundColor: _P.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOut),
          child: Column(
            children: [
              _buildHeader(),
              const Spacer(flex: 1),
              // The card to capture
              RepaintBoundary(
                key: _cardKey,
                child: _buildCard(streak, totalHours),
              ),
              const Spacer(flex: 1),
              _buildShareButton(),
              const SizedBox(height: 24),
            ],
          ),
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
          Text(
            'SHARE JOURNEY',
            style: GoogleFonts.cinzel(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _P.gold,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int streak, double totalHours) {
    final dateStr =
        '${widget.sessionDate.day}/${widget.sessionDate.month}/${widget.sessionDate.year}';
    final durationStr =
        widget.durationMinutes >= 60
            ? '${widget.durationMinutes ~/ 60}h ${widget.durationMinutes % 60}m'
            : '${widget.durationMinutes}m';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E1018), Color(0xFF0A0C16), Color(0xFF0F0E18)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _P.gold.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _P.gold.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo / branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🚂', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'RAIL FOCUS',
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _P.gold,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Decorative divider
          Container(
            width: 60,
            height: 1,
            color: _P.gold.withValues(alpha: 0.3),
          ),

          const SizedBox(height: 20),

          // Route emoji
          Text(widget.routeEmoji, style: const TextStyle(fontSize: 52)),

          const SizedBox(height: 12),

          // Route name
          Text(
            widget.routeName.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _P.cream,
              letterSpacing: 3,
            ),
          ),

          const SizedBox(height: 6),

          // Date
          Text(
            dateStr,
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              color: _P.muted,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: 60,
            height: 1,
            color: _P.gold.withValues(alpha: 0.3),
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CardStat(emoji: '⏱️', value: durationStr, label: 'Duration'),
              _CardStat(emoji: '🔥', value: '$streak', label: 'Streak'),
              _CardStat(
                emoji: '⏰',
                value: '${totalHours.toStringAsFixed(1)}h',
                label: 'Total',
              ),
            ],
          ),

          if (widget.goal != null && widget.goal!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _P.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"${widget.goal}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: _P.cream.withValues(alpha: 0.7),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTap: _shareCard,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  _sharing
                      ? [
                        _P.copper.withValues(alpha: 0.5),
                        _P.gold.withValues(alpha: 0.5),
                      ]
                      : [_P.copper, _P.gold],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _P.gold.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_sharing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Color(0xFF06070E),
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(
                  Icons.share_rounded,
                  color: Color(0xFF06070E),
                  size: 18,
                ),
              const SizedBox(width: 10),
              Text(
                _sharing ? 'SHARING...' : 'SHARE JOURNEY',
                style: GoogleFonts.cinzel(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF06070E),
                  letterSpacing: 3,
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
// CARD STAT WIDGET
// ═══════════════════════════════════════════════════════════════

class _CardStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _CardStat({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: 16,
            color: _P.gold,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 8,
            color: _P.muted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
