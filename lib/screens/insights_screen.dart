// lib/screens/insights_screen.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — FOCUS INSIGHTS DASHBOARD
//  Analytics screen with charts, AI coaching, and patterns.
//  Theme: Brass + Dark, Cinzel headings, SpaceMono labels
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/storage_service.dart';
import '../services/ai_coach_service.dart';

// ═══════════════════════════════════════════════════════════════
// PALETTE
// ═══════════════════════════════════════════════════════════════

class _P {
  static const ink = Color(0xFF07090F);
  static const panel = Color(0xFF131620);
  static const surface = Color(0xFF1A1E2C);
  static const brass = Color(0xFFD4A853);
  static const cream = Color(0xFFF5EDDB);
  static const muted = Color(0xFF706A5C);
  static const purple = Color(0xFF9B85D4);
  static const green = Color(0xFF4CAF50);
  static const orange = Color(0xFFFF9800);
  static const red = Color(0xFFEF5350);
}

// ═══════════════════════════════════════════════════════════════
// INSIGHTS SCREEN
// ═══════════════════════════════════════════════════════════════

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _storage = StorageService();
  final _ai = AiCoachService.instance;

  // Data
  int _streak = 0;
  double _totalHours = 0;
  int _totalSessions = 0;
  int _todayMinutes = 0;
  List<int> _hourlyData = List.filled(24, 0);
  List<int> _weeklyData = List.filled(7, 0);
  Map<String, int> _routeData = {};
  int _avgSessionMinutes = 0;

  // AI
  List<String> _aiInsights = [];
  String _weeklyReport = '';
  bool _loadingAi = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadAi();
  }

  void _loadData() {
    final sessions = _storage.getAllSessions();
    final completed = sessions.where((s) => s.completed).toList();

    setState(() {
      _streak = _storage.getStreak();
      _totalHours = _storage.getTotalHours();
      _totalSessions = _storage.getTotalSessions();
      _todayMinutes = _storage.getTodayMinutes();

      // Hourly distribution
      _hourlyData = List.filled(24, 0);
      for (final s in completed) {
        _hourlyData[s.startTime.hour] += s.durationMinutes;
      }

      // Weekly distribution
      _weeklyData = List.filled(7, 0);
      for (final s in completed) {
        _weeklyData[(s.startTime.weekday - 1) % 7] += s.durationMinutes;
      }

      // Route breakdown
      _routeData = {};
      for (final s in completed) {
        _routeData[s.routeName] =
            (_routeData[s.routeName] ?? 0) + s.durationMinutes;
      }

      // Average session
      _avgSessionMinutes = completed.isEmpty
          ? 0
          : completed.fold<int>(0, (sum, s) => sum + s.durationMinutes) ~/
              completed.length;
    });
  }

  Future<void> _loadAi() async {
    try {
      final insights = await _ai.getAnalyticsInsights();
      final report = await _ai.getWeeklyReport();
      if (mounted) {
        setState(() {
          _aiInsights = insights;
          _weeklyReport = report;
          _loadingAi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiInsights = ['🚂 AI insights unavailable right now'];
          _weeklyReport = '';
          _loadingAi = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _P.cream),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'FOCUS INSIGHTS',
          style: GoogleFonts.cinzel(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _P.brass,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── AI Insights Card ──────────────────────────
            _buildAiInsightsCard()
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.05, end: 0),

            const SizedBox(height: 20),

            // ── Quick Stats ───────────────────────────────
            _buildQuickStats()
                .animate(delay: 100.ms)
                .fadeIn(duration: 500.ms),

            const SizedBox(height: 20),

            // ── Peak Hours Chart ──────────────────────────
            _sectionTitle('PEAK FOCUS HOURS'),
            const SizedBox(height: 12),
            _buildHourlyChart()
                .animate(delay: 200.ms)
                .fadeIn(duration: 500.ms)
                .slideX(begin: -0.05, end: 0),

            const SizedBox(height: 24),

            // ── Weekly Pattern ────────────────────────────
            _sectionTitle('WEEKLY PATTERN'),
            const SizedBox(height: 12),
            _buildWeeklyChart()
                .animate(delay: 300.ms)
                .fadeIn(duration: 500.ms),

            const SizedBox(height: 24),

            // ── Route Breakdown ───────────────────────────
            _sectionTitle('ROUTE BREAKDOWN'),
            const SizedBox(height: 12),
            _buildRouteBreakdown()
                .animate(delay: 400.ms)
                .fadeIn(duration: 500.ms),

            const SizedBox(height: 24),

            // ── AI Weekly Report ──────────────────────────
            if (_weeklyReport.isNotEmpty) ...[
              _sectionTitle('AI WEEKLY REPORT'),
              const SizedBox(height: 12),
              _buildWeeklyReportCard()
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.05, end: 0),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // SECTION TITLE
  // ══════════════════════════════════════

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _P.brass,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.spaceMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _P.muted,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // AI INSIGHTS CARD
  // ══════════════════════════════════════

  Widget _buildAiInsightsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1535), Color(0xFF131620)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'AI COACH',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _P.purple,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (_loadingAi)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: _P.purple.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (_loadingAi)
            Text(
              'Analyzing your focus patterns...',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: _P.cream.withValues(alpha: 0.5),
              ),
            )
          else
            ..._aiInsights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    insight,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 15,
                      color: _P.cream.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // QUICK STATS ROW
  // ══════════════════════════════════════

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statCard('🔥', '$_streak', 'STREAK', _P.orange),
        const SizedBox(width: 10),
        _statCard('⏰', '${_totalHours.toStringAsFixed(1)}h', 'TOTAL', _P.brass),
        const SizedBox(width: 10),
        _statCard('📊', '${_avgSessionMinutes}m', 'AVG', _P.purple),
        const SizedBox(width: 10),
        _statCard('🎯', '${_todayMinutes}m', 'TODAY', _P.green),
      ],
    );
  }

  Widget _statCard(String emoji, String value, String label, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _P.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.spaceMono(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _P.cream,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: _P.muted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // HOURLY CHART
  // ══════════════════════════════════════

  Widget _buildHourlyChart() {
    final maxVal = _hourlyData.reduce(math.max).clamp(1, 99999);
    // Find peak hour
    int peakHour = 0;
    for (int i = 1; i < 24; i++) {
      if (_hourlyData[i] > _hourlyData[peakHour]) peakHour = i;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _P.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.brass.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hourlyData[peakHour] > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '⚡ Peak: ${peakHour}:00 (${_hourlyData[peakHour]} min)',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  color: _P.brass,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (i) {
                final ratio = _hourlyData[i] / maxVal;
                final isPeak = i == peakHour && _hourlyData[i] > 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: ratio.clamp(0.03, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isPeak
                                    ? _P.brass
                                    : _hourlyData[i] > 0
                                        ? _P.brass.withValues(alpha: 0.4)
                                        : _P.surface.withValues(alpha: 0.5),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 6),

          // Hour labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final h in [0, 6, 12, 18, 23])
                Text(
                  '${h}h',
                  style: GoogleFonts.spaceMono(
                    fontSize: 7,
                    color: _P.muted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // WEEKLY PATTERN CHART
  // ══════════════════════════════════════

  Widget _buildWeeklyChart() {
    final maxVal = _weeklyData.reduce(math.max).clamp(1, 99999);
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = (DateTime.now().weekday - 1) % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _P.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.brass.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final ratio = _weeklyData[i] / maxVal;
          final isToday = i == today;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Minutes label
                  if (_weeklyData[i] > 0)
                    Text(
                      '${_weeklyData[i]}m',
                      style: GoogleFonts.spaceMono(
                        fontSize: 8,
                        color: isToday ? _P.brass : _P.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 4),

                  // Bar
                  Container(
                    height: (60 * ratio).clamp(4.0, 60.0),
                    decoration: BoxDecoration(
                      color: isToday
                          ? _P.brass
                          : _P.brass.withValues(
                              alpha: 0.2 + ratio * 0.5,
                            ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Day label
                  Text(
                    dayLabels[i],
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                      color: isToday ? _P.brass : _P.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════
  // ROUTE BREAKDOWN
  // ══════════════════════════════════════

  Widget _buildRouteBreakdown() {
    if (_routeData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _P.panel,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            'No sessions yet — start your first journey! 🚂',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: _P.muted,
            ),
          ),
        ),
      );
    }

    final sorted = _routeData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalMins = sorted.fold<int>(0, (sum, e) => sum + e.value);
    final colors = [_P.brass, _P.purple, _P.green, _P.orange, _P.red];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _P.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.brass.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: sorted.take(5).toList().asMap().entries.map((entry) {
          final i = entry.key;
          final route = entry.value;
          final pct = totalMins > 0 ? route.value / totalMins : 0.0;
          final color = colors[i % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        route.key,
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _P.cream,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${route.value}m (${(pct * 100).round()}%)',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: _P.surface,
                    color: color,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════
  // WEEKLY CONDUCTOR'S REPORT CARD + OVERLAY
  // ══════════════════════════════════════

  Widget _buildWeeklyReportCard() {
    return GestureDetector(
      onTap: () => _openConductorReport(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF241C08), Color(0xFF131308)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.brass.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: _P.brass.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF0CC7A), Color(0xFFD4A853)],
                ),
              ),
              child: const Center(
                child: Text('📋', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONDUCTOR\'S REPORT',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _P.brass,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This week\'s journey analysis',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: _P.cream.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_full_rounded, color: _P.brass.withValues(alpha: 0.7), size: 18),
          ],
        ),
      ),
    );
  }

  void _openConductorReport(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConductorReportOverlay(report: _weeklyReport),
    );
  }
}

// ══════════════════════════════════════
// CONDUCTOR'S REPORT OVERLAY WIDGET
// ══════════════════════════════════════
class _ConductorReportOverlay extends StatelessWidget {
  final String report;
  const _ConductorReportOverlay({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFF0E0C08),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A853).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Newspaper header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Divider(color: const Color(0xFFD4A853).withValues(alpha: 0.4))),
                    const SizedBox(width: 12),
                    Text(
                      '★',
                      style: TextStyle(
                        color: const Color(0xFFD4A853).withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Divider(color: const Color(0xFFD4A853).withValues(alpha: 0.4))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'THE LUXE RAIL GAZETTE',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF5EDDB),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Weekly Conductor\'s Report — Personal Edition',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF9A8E78),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: const Color(0xFFD4A853).withValues(alpha: 0.4)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FROM THE CONDUCTOR',
                      style: GoogleFonts.spaceMono(
                        fontSize: 7,
                        color: const Color(0xFF9A8E78),
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      _weekOf(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 7,
                        color: const Color(0xFF9A8E78),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Report body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.isEmpty
                        ? 'Your weekly journey analysis is being prepared...\n\nComplete a few more sessions and check back next week for a full conductor\'s report on your focus patterns.'
                        : report,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 18,
                      color: const Color(0xFFF5EDDB).withValues(alpha: 0.88),
                      height: 1.75,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Divider(color: const Color(0xFFD4A853).withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('🚂', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 10),
                      Text(
                        'The journey continues next week.',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF9A8E78),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _weekOf() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return 'Week of ${weekStart.day}/${weekStart.month}/${weekStart.year}';
  }
}
