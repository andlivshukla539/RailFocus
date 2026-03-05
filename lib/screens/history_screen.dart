// lib/screens/history_screen.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — JOURNEY HISTORY SCREEN
//  Theme: Grand Station Travel Ledger
//
//  FEATURES:
//  ─────────────────────────────────────────────────────────────
//  • All past sessions in ticket-style cards
//  • Lifetime stats summary
//  • Filter by completion status
//  • Filter by route
//  • Relative date formatting
//  • Empty state for new users
//  • Staggered entrance animations
//  • Pull to refresh
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/route_model.dart';
import '../models/session_model.dart';
import '../router/app_router.dart';
import '../services/storage_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_box.dart';

// ═══════════════════════════════════════════════════════════════
// PALETTE
// ═══════════════════════════════════════════════════════════════

class _P {
  static const ink = Color(0xFF07090F);
  static const panel = Color(0xFF131620);
  static const surface = Color(0xFF1A1E2C);
  static const brass = Color(0xFFD4A853);
  static const brassLt = Color(0xFFF0CC7A);
  static const brassDk = Color(0xFF8A6930);
  static const cream = Color(0xFFF5EDDB);
  static const t2 = Color(0xFF9A8E78);
  static const t3 = Color(0xFF564E40);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
}

// ═══════════════════════════════════════════════════════════════
// FILTER ENUM
// ═══════════════════════════════════════════════════════════════

enum HistoryFilter { all, completed, stopped }

// ═══════════════════════════════════════════════════════════════
// MAIN HISTORY SCREEN
// ═══════════════════════════════════════════════════════════════

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  // ── Data ───────────────────────────────────────────────────
  final _storage = StorageService();
  List<JourneySession> _allSessions = [];
  List<JourneySession> _filteredSessions = [];

  // ── Stats ──────────────────────────────────────────────────
  int _totalSessions = 0;
  double _totalHours = 0;
  int _streak = 0;
  int _completedCount = 0;
  Map<String, int> _heatmapData = {};
  bool _isLoading = true;

  // ── Filters ────────────────────────────────────────────────
  HistoryFilter _filter = HistoryFilter.all;
  String? _selectedRoute;

  // ── Animation ──────────────────────────────────────────────
  late AnimationController _headerCtrl;
  late AnimationController _listCtrl;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _loadData();
    _startAnimations();
  }

  void _loadData() {
    _allSessions = _storage.getAllSessions();
    _totalSessions = _storage.getTotalSessions();
    _totalHours = _storage.getTotalHours();
    _streak = _storage.getStreak();
    _completedCount = _allSessions.where((s) => s.completed).length;
    _heatmapData = _storage.getDailyFocusMap(days: 91);
    _isLoading = false;

    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      _filteredSessions =
          _allSessions.where((session) {
            // Filter by completion status
            if (_filter == HistoryFilter.completed && !session.completed) {
              return false;
            }
            if (_filter == HistoryFilter.stopped && session.completed) {
              return false;
            }

            // Filter by route
            if (_selectedRoute != null && session.routeName != _selectedRoute) {
              return false;
            }

            return true;
          }).toList();
    });
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _headerCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _listCtrl.forward();
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    _loadData();
    _listCtrl.reset();
    _listCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _listCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<bool> _confirmDelete(JourneySession session) async {
    HapticFeedback.mediumImpact();
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder:
          (_) => Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _P.panel,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFB83838).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFB83838),
                      size: 36,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'DELETE JOURNEY?',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _P.cream,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Remove "${session.routeName}" from your travel ledger?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 14,
                        color: _P.t2,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context, false),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: _P.surface,
                              ),
                              child: Center(
                                child: Text(
                                  'KEEP',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    color: _P.cream,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context, true),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: const Color(0xFFB83838),
                              ),
                              child: Center(
                                child: Text(
                                  'DELETE',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
    return result ?? false;
  }

  void _deleteSession(JourneySession session) {
    HapticFeedback.heavyImpact();
    _storage.deleteSession(session.id);
    _loadData();

    // Show undo snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Journey deleted',
          style: GoogleFonts.cormorantGaramond(color: _P.cream),
        ),
        backgroundColor: _P.panel,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: _P.brass,
          onPressed: () {
            // Re-save the session
            _storage.saveSession(session);
            _loadData();
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _P.ink,
        body: Stack(
          children: [
            // Layer 1: Ambient glow
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _glowCtrl,
                builder:
                    (_, __) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.5),
                          radius: 1.4,
                          colors: [
                            _P.brass.withValues(
                              alpha: 0.03 + _glowCtrl.value * 0.03,
                            ),
                            _P.ink,
                          ],
                        ),
                      ),
                    ),
              ),
            ),

            // Layer 2: Main content
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        // Header with back button
                        _buildHeader(),
                        const SizedBox(height: 20),
                        // Stats summary
                        _buildStatsSummary(),
                        const SizedBox(height: 16),
                        // Heatmap calendar
                        _FocusHeatmap(data: _heatmapData),
                        const SizedBox(height: 16),
                        // Filters
                        _buildFilters(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  
                  // Journey list
                  if (_isLoading)
                    const SliverFillRemaining(
                      child: ShimmerList(itemCount: 4, itemHeight: 90),
                    )
                  else if (_filteredSessions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverFillRemaining(
                      child: _buildJourneyList(),
                    ),
                ],
              ),
            ),

            // Vignette
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.0,
                      colors: [
                        Colors.transparent,
                        _P.ink.withValues(alpha: 0.4),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerCtrl,
      builder: (_, child) {
        final opacity = _headerCtrl.value.clamp(0.0, 1.0);
        final slide = (1 - _headerCtrl.value) * 20;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(offset: Offset(0, -slide), child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _P.surface,
                  border: Border.all(color: _P.brass.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: _P.cream,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JOURNEY',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _P.cream,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'HISTORY',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: _P.t2,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Journal icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_P.brassLt, _P.brass, _P.brassDk],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _P.brass.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: _P.ink,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Summary ──────────────────────────────────────────

  Widget _buildStatsSummary() {
    return AnimatedBuilder(
      animation: _headerCtrl,
      builder: (_, child) {
        final opacity = ((_headerCtrl.value - 0.3) / 0.7).clamp(0.0, 1.0);

        return Opacity(opacity: opacity, child: child);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: _P.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _P.brass.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(
                value: '$_totalSessions',
                label: 'JOURNEYS',
                icon: Icons.train_rounded,
              ),
              _divider(),
              _MiniStat(
                value: _totalHours.toStringAsFixed(1),
                label: 'HOURS',
                icon: Icons.hourglass_bottom_rounded,
              ),
              _divider(),
              _MiniStat(
                value: '$_streak',
                label: 'STREAK',
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFFF6030),
              ),
              _divider(),
              _MiniStat(
                value: '$_completedCount',
                label: 'COMPLETED',
                icon: Icons.check_circle_rounded,
                iconColor: _P.success,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: _P.brass.withValues(alpha: 0.1),
    );
  }

  // ── Filters ────────────────────────────────────────────────

  Widget _buildFilters() {
    return AnimatedBuilder(
      animation: _headerCtrl,
      builder: (_, child) {
        final opacity = ((_headerCtrl.value - 0.5) / 0.5).clamp(0.0, 1.0);

        return Opacity(opacity: opacity, child: child);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // Status filters
              _FilterChip(
                label: 'ALL',
                isSelected: _filter == HistoryFilter.all,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _filter = HistoryFilter.all);
                  _applyFilter();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'COMPLETED',
                isSelected: _filter == HistoryFilter.completed,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _filter = HistoryFilter.completed);
                  _applyFilter();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'STOPPED',
                isSelected: _filter == HistoryFilter.stopped,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _filter = HistoryFilter.stopped);
                  _applyFilter();
                },
              ),

              const SizedBox(width: 16),

              // Route filter dropdown
              _RouteFilterDropdown(
                selectedRoute: _selectedRoute,
                sessions: _allSessions,
                onChanged: (route) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRoute = route);
                  _applyFilter();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Journey List ───────────────────────────────────────────

  Widget _buildJourneyList() {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: _P.brass,
      backgroundColor: _P.panel,
      child: AnimatedBuilder(
        animation: _listCtrl,
        builder: (_, __) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: _filteredSessions.length,
            itemBuilder: (_, index) {
              final delay = (index * 0.08).clamp(0.0, 0.7);
              final itemProgress = ((_listCtrl.value - delay) / (1 - delay))
                  .clamp(0.0, 1.0);
              // Spring-style overshoot curve
              final curved = Curves.elasticOut.transform(itemProgress);
              final opacity = itemProgress.clamp(0.0, 1.0);
              final slide = (1 - curved) * 40;
              final scale = 0.92 + curved * 0.08;

              final session = _filteredSessions[index];

              return Opacity(
                opacity: opacity,
                child: Transform(
                  alignment: Alignment.center,
                  transform:
                      Matrix4.identity()
                        ..translate(0.0, slide)
                        ..scale(scale, scale, 1.0),
                  child: Dismissible(
                    key: ValueKey(session.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(session),
                    onDismissed: (_) => _deleteSession(session),
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB83838).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFB83838).withValues(alpha: 0.3),
                        ),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'DELETE',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB83838),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFB83838),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    child: _JourneyCard(session: session, index: index),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: AnimatedBuilder(
        animation: _listCtrl,
        builder: (_, child) {
          final opacity = _listCtrl.value.clamp(0.0, 1.0);
          return Opacity(opacity: opacity, child: child);
        },
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Empty icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _P.surface,
                  border: Border.all(color: _P.brass.withValues(alpha: 0.15)),
                ),
                child: Icon(
                  _allSessions.isEmpty
                      ? Icons.explore_outlined
                      : Icons.filter_alt_off_rounded,
                  color: _P.brass.withValues(alpha: 0.4),
                  size: 44,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                _allSessions.isEmpty
                    ? 'NO JOURNEYS YET'
                    : 'NO MATCHING JOURNEYS',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _P.cream,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                _allSessions.isEmpty
                    ? 'Your travel ledger awaits.\nBook your first journey to begin.'
                    : 'Try adjusting your filters\nto see more journeys.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: _P.t2,
                  height: 1.5,
                ),
              ),

              if (_allSessions.isEmpty) ...[
                const SizedBox(height: 32),

                // Book journey button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.go(AppRouter.booking);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_P.brassLt, _P.brass, _P.brassDk],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _P.brass.withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: _P.ink, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'BOOK JOURNEY',
                          style: GoogleFonts.spaceMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _P.ink,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_allSessions.isNotEmpty && _filteredSessions.isEmpty) ...[
                const SizedBox(height: 24),

                // Clear filters button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _filter = HistoryFilter.all;
                      _selectedRoute = null;
                    });
                    _applyFilter();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _P.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _P.brass.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      'CLEAR FILTERS',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        color: _P.brass,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MINI STAT WIDGET
// ═══════════════════════════════════════════════════════════════

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? iconColor;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor ?? _P.brass, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _P.cream,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 7,
            color: _P.t3,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FILTER CHIP
// ═══════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _P.brass.withValues(alpha: 0.15) : _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? _P.brass.withValues(alpha: 0.5)
                    : _P.brass.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isSelected ? _P.brass : _P.t2,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ROUTE FILTER DROPDOWN
// ═══════════════════════════════════════════════════════════════

class _RouteFilterDropdown extends StatelessWidget {
  final String? selectedRoute;
  final List<JourneySession> sessions;
  final void Function(String?) onChanged;

  const _RouteFilterDropdown({
    required this.selectedRoute,
    required this.sessions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Get unique routes from sessions
    final routes = sessions.map((s) => s.routeName).toSet().toList();

    return GestureDetector(
      onTap: () => _showRouteSelector(context, routes),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              selectedRoute != null
                  ? _P.brass.withValues(alpha: 0.15)
                  : _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selectedRoute != null
                    ? _P.brass.withValues(alpha: 0.5)
                    : _P.brass.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedRoute ?? 'ALL ROUTES',
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: selectedRoute != null ? _P.brass : _P.t2,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: selectedRoute != null ? _P.brass : _P.t2,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showRouteSelector(BuildContext context, List<String> routes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: _P.panel,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _P.brass.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  'SELECT ROUTE',
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _P.brass,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 20),

                // All routes option
                _RouteOption(
                  routeName: null,
                  isSelected: selectedRoute == null,
                  onTap: () {
                    onChanged(null);
                    Navigator.pop(ctx);
                  },
                ),

                // Individual routes
                ...routes.map(
                  (route) => _RouteOption(
                    routeName: route,
                    isSelected: selectedRoute == route,
                    onTap: () {
                      onChanged(route);
                      Navigator.pop(ctx);
                    },
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}

class _RouteOption extends StatelessWidget {
  final String? routeName;
  final bool isSelected;
  final VoidCallback onTap;

  const _RouteOption({
    required this.routeName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final route =
        routeName != null
            ? RouteModel.fromId(_routeIdFromName(routeName!))
            : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _P.brass.withValues(alpha: 0.1) : _P.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? _P.brass.withValues(alpha: 0.4)
                    : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            if (route != null)
              Text(route.emoji, style: const TextStyle(fontSize: 20))
            else
              const Icon(Icons.public_rounded, color: _P.t2, size: 20),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                routeName?.toUpperCase() ?? 'ALL ROUTES',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _P.cream : _P.t2,
                  letterSpacing: 1,
                ),
              ),
            ),

            if (isSelected)
              const Icon(Icons.check_rounded, color: _P.brass, size: 18),
          ],
        ),
      ),
    );
  }

  String _routeIdFromName(String name) {
    // Convert route name back to ID
    return name.toLowerCase().replaceAll(' ', '_');
  }
}

// ═══════════════════════════════════════════════════════════════
// JOURNEY CARD
// ═══════════════════════════════════════════════════════════════

class _JourneyCard extends StatelessWidget {
  final JourneySession session;
  final int index;

  const _JourneyCard({required this.session, required this.index});

  // Get route model for styling
  RouteModel? get _route {
    final id = session.routeName.toLowerCase().replaceAll(' ', '_');
    return RouteModel.fromId(id);
  }

  Color get _accentColor => _route?.accentColor ?? _P.brass;

  String get _emoji => _route?.emoji ?? '🚂';

  String get _formattedDate {
    final now = DateTime.now();
    final diff = now.difference(session.startTime);

    if (diff.inDays == 0) {
      // Today
      final hour = session.startTime.hour;
      final minute = session.startTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return 'Today, $displayHour:$minute $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 18,
      blur: 10,
      tint: const Color(0x12F5EDDB),
      borderColor: _accentColor.withValues(alpha: 0.18),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Accent bar left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                color: session.completed ? _accentColor : _P.warning,
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      // Route emoji
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Route name and status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.routeName.toUpperCase(),
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _P.cream,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        session.completed
                                            ? _P.success.withValues(alpha: 0.15)
                                            : _P.warning.withValues(
                                              alpha: 0.15,
                                            ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        session.completed
                                            ? Icons.check_rounded
                                            : Icons.pause_rounded,
                                        size: 10,
                                        color:
                                            session.completed
                                                ? _P.success
                                                : _P.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        session.completed
                                            ? 'COMPLETED'
                                            : 'STOPPED',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              session.completed
                                                  ? _P.success
                                                  : _P.warning,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Duration
                                Text(
                                  session.formattedDuration,
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    color: _P.t2,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: _P.t3,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formattedDate,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 13,
                          color: _P.t2,
                        ),
                      ),
                    ],
                  ),

                  // Goal (if exists)
                  if (session.goal != null && session.goal!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _P.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 14,
                            color: _accentColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              session.goal!,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: _P.cream.withValues(alpha: 0.8),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Mood (if exists)
                  if (session.mood != null && session.mood!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Mood: ',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            color: _P.t3,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          session.mood!,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 13,
                            color: _P.t2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Ticket notch decoration
            Positioned(
              right: -8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _P.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FOCUS HEATMAP — GitHub-style contribution grid (last 91 days)
// ═══════════════════════════════════════════════════════════════

class _FocusHeatmap extends StatelessWidget {
  final Map<String, int> data;
  const _FocusHeatmap({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    const weeks = 13;
    const cellSize = 10.0;
    const gap = 2.5;

    // Find max for normalization
    final maxMin = data.values.fold<int>(1, (a, b) => a > b ? a : b);

    // Day labels
    final dayLabels = ['M', '', 'W', '', 'F', '', ''];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _P.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _P.brass.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'FOCUS MAP',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _P.brass,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${weeks * 7} days',
                  style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    color: _P.t3,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day labels column
                Column(
                  children: List.generate(
                    7,
                    (d) => Container(
                      height: cellSize + gap,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        dayLabels[d],
                        style: GoogleFonts.spaceMono(fontSize: 7, color: _P.t3),
                      ),
                    ),
                  ),
                ),

                // Grid
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      children: List.generate(weeks, (w) {
                        return Column(
                          children: List.generate(7, (d) {
                            final daysAgo = (weeks - 1 - w) * 7 + (6 - d);
                            final date = now.subtract(Duration(days: daysAgo));
                            final key =
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                            final mins = data[key] ?? 0;
                            final intensity =
                                mins > 0
                                    ? (mins / maxMin).clamp(0.15, 1.0)
                                    : 0.0;

                            return Padding(
                              padding: const EdgeInsets.all(gap / 2),
                              child: Container(
                                width: cellSize,
                                height: cellSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2.5),
                                  color:
                                      intensity > 0
                                          ? _P.brass.withValues(
                                            alpha: intensity * 0.8,
                                          )
                                          : _P.surface.withValues(alpha: 0.5),
                                ),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Less ',
                  style: GoogleFonts.spaceMono(fontSize: 7, color: _P.t3),
                ),
                ...List.generate(
                  5,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.5),
                      color:
                          i == 0
                              ? _P.surface.withValues(alpha: 0.5)
                              : _P.brass.withValues(
                                alpha: (i / 4).clamp(0.15, 0.8),
                              ),
                    ),
                  ),
                ),
                Text(
                  ' More',
                  style: GoogleFonts.spaceMono(fontSize: 7, color: _P.t3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
