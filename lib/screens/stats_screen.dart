// lib/screens/stats_screen.dart
// ═══════════════════════════════════════════════════════════════
//  RAIL FOCUS — ANALYTICS DASHBOARD
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/storage_service.dart';

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

// Route colors for pie chart
const _kRouteColors = [
  Color(0xFFFFB7C5), // Tokyo
  Color(0xFF5B9BD5), // Swiss
  Color(0xFF6D8B74), // Scottish
  Color(0xFFD4963A), // Darjeeling
  Color(0xFF00D9FF), // Norwegian
  Color(0xFFE8A87C), // Trans-Siberian
  Color(0xFFB05E78), // Orient Express
  Color(0xFFFFD700), // Indian Pacific
];

// ═══════════════════════════════════════════════════════════════
// STATS SCREEN
// ═══════════════════════════════════════════════════════════════

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  final _storage = StorageService();
  bool _isWeekly = true;
  late AnimationController _enter;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildQuickStats()),
              SliverToBoxAdapter(child: _buildPeriodToggle()),
              SliverToBoxAdapter(child: _buildBarChart()),
              SliverToBoxAdapter(child: _buildRouteBreakdown()),
              SliverToBoxAdapter(child: _buildHeatmap()),
              SliverToBoxAdapter(child: _buildTimeOfDay()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────

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
                  'ANALYTICS',
                  style: GoogleFonts.cinzel(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _P.gold,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'Your focus journey in numbers',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: _P.muted,
                  ),
                ),
              ],
            ),
          ),
          Text('📊', style: const TextStyle(fontSize: 28)),
        ],
      ),
    );
  }

  // ── Quick Stats Cards ──────────────────────────────────────

  Widget _buildQuickStats() {
    final totalHours = _storage.getTotalHours();
    final totalSessions = _storage.getTotalSessions();
    final streak = _storage.getStreak();
    final bestStreak = _storage.getBestStreak();
    final completionRate = _storage.getCompletionRate();
    final bestHour = _storage.getMostProductiveHour();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              _StatCard(
                emoji: '⏱️',
                label: 'Total Hours',
                value: totalHours.toStringAsFixed(1),
              ),
              _StatCard(
                emoji: '🚂',
                label: 'Journeys',
                value: '$totalSessions',
              ),
              _StatCard(emoji: '🔥', label: 'Streak', value: '$streak days'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatCard(
                emoji: '🏆',
                label: 'Best Streak',
                value: '$bestStreak days',
              ),
              _StatCard(
                emoji: '✅',
                label: 'Completion',
                value: '${completionRate.toInt()}%',
              ),
              _StatCard(
                emoji: '🌟',
                label: 'Peak Hour',
                value: '${bestHour.toString().padLeft(2, '0')}:00',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Period Toggle ──────────────────────────────────────────

  Widget _buildPeriodToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Text(
            'FOCUS MINUTES',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: _P.muted,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          _TogglePill(
            leftLabel: 'Week',
            rightLabel: 'Month',
            isLeft: _isWeekly,
            onToggle: () => setState(() => _isWeekly = !_isWeekly),
          ),
        ],
      ),
    );
  }

  // ── Bar Chart ──────────────────────────────────────────────

  Widget _buildBarChart() {
    final data =
        _isWeekly ? _storage.getWeeklyStats() : _storage.getMonthlyStats();
    final maxY =
        data.isEmpty ? 60.0 : (data.reduce(math.max) * 1.2).clamp(30.0, 500.0);

    final labels =
        _isWeekly
            ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            : List.generate(30, (i) => i % 5 == 0 ? '${30 - i}d' : '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        height: 200,
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.rim, width: 1),
        ),
        child: BarChart(
          BarChartData(
            maxY: maxY,
            barGroups: List.generate(
              data.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i],
                    width: _isWeekly ? 20 : 5,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [_P.gold.withValues(alpha: 0.6), _P.goldLt],
                    ),
                  ),
                ],
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget:
                      (value, meta) => Text(
                        '${value.toInt()}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 8,
                          color: _P.dim,
                        ),
                      ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= labels.length)
                      return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        labels[idx],
                        style: GoogleFonts.spaceMono(
                          fontSize: 8,
                          color: _P.dim,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine:
                  (value) => FlLine(
                    color: _P.rim.withValues(alpha: 0.3),
                    strokeWidth: 0.5,
                  ),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => _P.surface,
                tooltipRoundedRadius: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()} min',
                    GoogleFonts.spaceMono(color: _P.gold, fontSize: 11),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Route Breakdown (Pie Chart) ────────────────────────────

  Widget _buildRouteBreakdown() {
    final byRoute = _storage.getSessionsByRoute();
    if (byRoute.isEmpty) return const SizedBox();

    final total = byRoute.values.fold(0, (a, b) => a + b);
    final entries =
        byRoute.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.rim, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ROUTES TRAVELED',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: _P.muted,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 28,
                        sections: List.generate(entries.length, (i) {
                          final pct = entries[i].value / total * 100;
                          return PieChartSectionData(
                            value: entries[i].value.toDouble(),
                            color: _kRouteColors[i % _kRouteColors.length],
                            radius: 36,
                            title: '${pct.toInt()}%',
                            titleStyle: GoogleFonts.spaceMono(
                              fontSize: 9,
                              color: _P.bg,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        entries.length.clamp(0, 5),
                        (i) => _LegendItem(
                          color: _kRouteColors[i % _kRouteColors.length],
                          label: entries[i].key,
                          value: '${entries[i].value}m',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Heatmap Calendar ───────────────────────────────────────

  Widget _buildHeatmap() {
    final dailyData = _storage.getDailyFocusMap(days: 91); // ~13 weeks
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.rim, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FOCUS HEATMAP',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: _P.muted,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width - 64, 90),
                painter: _HeatmapPainter(dailyData: dailyData, now: now),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Less ',
                  style: GoogleFonts.spaceMono(fontSize: 8, color: _P.dim),
                ),
                ...List.generate(
                  5,
                  (i) => Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: _heatColor(i / 4),
                    ),
                  ),
                ),
                Text(
                  ' More',
                  style: GoogleFonts.spaceMono(fontSize: 8, color: _P.dim),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Time of Day Distribution ───────────────────────────────

  Widget _buildTimeOfDay() {
    final tod = _storage.getSessionsByTimeOfDay();
    final total = tod.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox();

    final labels = {
      'morning': '🌅 Morning',
      'afternoon': '☀️ Afternoon',
      'evening': '🌆 Evening',
      'night': '🌙 Night',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.rim, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TIME OF DAY',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: _P.muted,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            ...tod.entries.map((e) {
              final pct = total > 0 ? e.value / total : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        labels[e.key] ?? e.key,
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          color: _P.cream,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: _P.surface,
                          color: _P.gold,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${e.value}',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          color: _P.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STAT CARD
// ═══════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _P.rim, width: 1),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.spaceMono(
                fontSize: 14,
                color: _P.cream,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 8,
                color: _P.muted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOGGLE PILL
// ═══════════════════════════════════════════════════════════════

class _TogglePill extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool isLeft;
  final VoidCallback onToggle;

  const _TogglePill({
    required this.leftLabel,
    required this.rightLabel,
    required this.isLeft,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onToggle();
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.rim, width: 1),
        ),
        child: Row(
          children: [
            _pillSide(leftLabel, isLeft),
            _pillSide(rightLabel, !isLeft),
          ],
        ),
      ),
    );
  }

  Widget _pillSide(String label, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? _P.gold.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(
          fontSize: 10,
          color: active ? _P.gold : _P.dim,
          fontWeight: active ? FontWeight.w700 : FontWeight.normal,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LEGEND ITEM
// ═══════════════════════════════════════════════════════════════

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceMono(fontSize: 9, color: _P.cream),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceMono(fontSize: 9, color: _P.muted),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HEATMAP PAINTER
// ═══════════════════════════════════════════════════════════════

Color _heatColor(double intensity) {
  if (intensity <= 0) return const Color(0xFF111320);
  if (intensity < 0.25) return const Color(0xFF2A2418);
  if (intensity < 0.50) return const Color(0xFF4A3820);
  if (intensity < 0.75) return const Color(0xFF7A5828);
  return const Color(0xFFD4A855);
}

class _HeatmapPainter extends CustomPainter {
  final Map<String, int> dailyData;
  final DateTime now;

  _HeatmapPainter({required this.dailyData, required this.now});

  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 10.0;
    const gap = 2.0;
    const rows = 7; // days of week

    final maxVal = dailyData.values.fold(0, math.max).clamp(1, 999);

    // Start from 91 days ago
    for (int day = 0; day < 91; day++) {
      final date = now.subtract(Duration(days: 90 - day));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final value = dailyData[key] ?? 0;
      final intensity = value / maxVal;

      final col = day ~/ rows;
      final row = day % rows;

      final rect = Rect.fromLTWH(
        col * (cellSize + gap),
        row * (cellSize + gap),
        cellSize,
        cellSize,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = _heatColor(intensity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) =>
      old.dailyData != dailyData;
}
