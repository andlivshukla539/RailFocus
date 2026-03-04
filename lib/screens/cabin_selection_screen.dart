// lib/screens/cabin_selection_screen.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — PASSENGER CABIN SELECTION
//  The Social Lounge: users browse public focus cabins,
//  create their own, or join a private one with an invite code.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/cabin_service.dart';

// ──────────────────────────────────────────────────────────────
// PALETTE
// ──────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF07090F);
  static const panel = Color(0xFF131620);
  static const surface = Color(0xFF1A1E2C);
  static const brass = Color(0xFFD4A853);
  static const brassLt = Color(0xFFF0CC7A);
  static const brassDk = Color(0xFF8A6930);
  static const cream = Color(0xFFF5EDDB);
  static const t2 = Color(0xFF9A8E78);
  static const t3 = Color(0xFF564E40);
  static const green = Color(0xFF4CAF50);
}

class CabinSelectionScreen extends StatefulWidget {
  const CabinSelectionScreen({super.key});

  @override
  State<CabinSelectionScreen> createState() => _CabinSelectionScreenState();
}

class _CabinSelectionScreenState extends State<CabinSelectionScreen>
    with SingleTickerProviderStateMixin {
  final _service = CabinService.instance;
  late final TabController _tabs;

  final _nameCtrl = TextEditingController(text: 'Focus Cabin');
  final _codeCtrl = TextEditingController();
  bool _isPublic = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _createCabin() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final cabin = await _service.createCabin(
      name: _nameCtrl.text.trim(),
      isPublic: _isPublic,
    );
    setState(() => _loading = false);
    if (mounted) {
      Navigator.of(context).pop(cabin);
    }
  }

  Future<void> _joinByCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length < 4) return;
    setState(() => _loading = true);
    final cabin = await _service.joinByCode(code);
    setState(() => _loading = false);
    if (mounted) {
      if (cabin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1A1E2C),
            content: Text(
              'Invalid code — no cabin found.',
              style: GoogleFonts.spaceMono(fontSize: 11, color: _C.cream),
            ),
          ),
        );
      } else {
        Navigator.of(context).pop(cabin);
      }
    }
  }

  Future<void> _joinCabin(String cabinId) async {
    final ok = await _service.joinCabin(cabinId);
    if (mounted && ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _C.cream),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'PASSENGER CABINS',
          style: GoogleFonts.spaceMono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _C.brass,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _C.brass,
          labelColor: _C.brass,
          unselectedLabelColor: _C.t2,
          labelStyle: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5),
          tabs: const [
            Tab(text: 'PUBLIC CABINS'),
            Tab(text: 'CREATE / JOIN'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildPublicCabins(),
          _buildCreateOrJoin(),
        ],
      ),
    );
  }

  // ── Public cabin list ────────────────────────────────────────
  Widget _buildPublicCabins() {
    return StreamBuilder<List<CabinModel>>(
      stream: _service.publicCabinsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _C.brass, strokeWidth: 1.5),
          );
        }

        final cabins = snap.data ?? [];

        if (cabins.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏛️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'The station is quiet.',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: _C.cream,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to open a cabin.',
                  style: GoogleFonts.spaceMono(fontSize: 10, color: _C.t2),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: cabins.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _buildCabinCard(cabins[i]),
        );
      },
    );
  }

  Widget _buildCabinCard(CabinModel cabin) {
    final isActive = cabin.activeCount > 0;
    return GestureDetector(
      onTap: () => _joinCabin(cabin.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? _C.brass.withValues(alpha: 0.3)
                : _C.t3.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Avatar cluster
            SizedBox(
              width: 60,
              height: 36,
              child: Stack(
                children: [
                  ...cabin.passengers.take(3).toList().asMap().entries.map((e) {
                    return Positioned(
                      left: e.key * 18.0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _C.surface,
                          border: Border.all(color: _C.bg, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            e.value.avatar,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cabin.name,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _C.cream,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? _C.green : _C.t3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${cabin.activeCount} focusing now',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          color: isActive ? _C.green : _C.t2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [_C.brassLt, _C.brass],
                ),
              ),
              child: Text(
                'JOIN',
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _C.bg,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Create or Join by code ───────────────────────────────────
  Widget _buildCreateOrJoin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Create section ───────────────────────────────
          _sectionLabel('CREATE A CABIN'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _C.panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.brass.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name input
                Text(
                  'CABIN NAME',
                  style: GoogleFonts.spaceMono(fontSize: 8, color: _C.t2, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  style: GoogleFonts.cormorantGaramond(fontSize: 18, color: _C.cream),
                  cursorColor: _C.brass,
                  decoration: InputDecoration(
                    hintText: 'Focus Cabin',
                    hintStyle: GoogleFonts.cormorantGaramond(
                      fontSize: 18, color: _C.t3, fontStyle: FontStyle.italic,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _C.brass.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _C.brass.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _C.brass.withValues(alpha: 0.5)),
                    ),
                    filled: true,
                    fillColor: _C.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 16),

                // Visibility toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () { HapticFeedback.selectionClick(); setState(() => _isPublic = true); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _isPublic ? _C.brass.withValues(alpha: 0.15) : _C.surface,
                            border: Border.all(color: _isPublic ? _C.brass : _C.t3.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              Text('🌐', style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 4),
                              Text('Public', style: GoogleFonts.spaceMono(fontSize: 9, color: _isPublic ? _C.brass : _C.t2)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () { HapticFeedback.selectionClick(); setState(() => _isPublic = false); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: !_isPublic ? _C.brass.withValues(alpha: 0.15) : _C.surface,
                            border: Border.all(color: !_isPublic ? _C.brass : _C.t3.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              Text('🔒', style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 4),
                              Text('Private', style: GoogleFonts.spaceMono(fontSize: 9, color: !_isPublic ? _C.brass : _C.t2)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                GestureDetector(
                  onTap: _loading ? null : _createCabin,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [_C.brassLt, _C.brass, _C.brassDk],
                      ),
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _C.bg, strokeWidth: 2))
                          : Text(
                              'OPEN CABIN',
                              style: GoogleFonts.spaceMono(
                                fontSize: 11, fontWeight: FontWeight.w700, color: _C.bg, letterSpacing: 2,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Join by code section ─────────────────────────
          _sectionLabel('JOIN PRIVATE CABIN'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _C.panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.brass.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INVITE CODE',
                  style: GoogleFonts.spaceMono(fontSize: 8, color: _C.t2, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.spaceMono(fontSize: 18, color: _C.cream, letterSpacing: 4),
                        cursorColor: _C.brass,
                        maxLength: 6,
                        decoration: InputDecoration(
                          hintText: 'XXXXXX',
                          hintStyle: GoogleFonts.spaceMono(fontSize: 18, color: _C.t3, letterSpacing: 4),
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _C.brass.withValues(alpha: 0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _C.brass.withValues(alpha: 0.15)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _C.brass.withValues(alpha: 0.5)),
                          ),
                          filled: true,
                          fillColor: _C.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _loading ? null : _joinByCode,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(colors: [_C.brassLt, _C.brass]),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: _C.bg, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(color: _C.brass, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.spaceMono(fontSize: 9, fontWeight: FontWeight.w700, color: _C.t2, letterSpacing: 2),
        ),
      ],
    );
  }
}
