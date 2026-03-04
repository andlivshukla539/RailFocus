// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — SETTINGS SCREEN
//  Theme: Station Master's Control Room
//
//  SECTIONS:
//    • Sound (mute, ambient volume, SFX volume)
//    • Display (wakelock toggle)
//    • Notifications (enable, daily reminder, reminder time)
//    • Data (clear history)
//    • About (version, credits)
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/wakelock_service.dart';
import '../router/app_router.dart';
import '../widgets/breathing_exercise.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// ═══════════════════════════════════════════════════════════════
// PALETTE
// ═══════════════════════════════════════════════════════════════

class _S {
  static const ink = Color(0xFF07090F);
  static const panel = Color(0xFF131620);
  static const surface = Color(0xFF1A1E2C);
  static const brass = Color(0xFFD4A853);
  static const brassLt = Color(0xFFF0CC7A);
  static const brassDk = Color(0xFF8A6930);
  static const cream = Color(0xFFF5EDDB);
  static const t2 = Color(0xFF9A8E78);
  static const t3 = Color(0xFF564E40);
  static const danger = Color(0xFFB83838);
  static const success = Color(0xFF4CAF50);
}

// ═══════════════════════════════════════════════════════════════
// SETTINGS SCREEN
// ═══════════════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final _audio = AudioService();
  final _storage = StorageService();

  // ── Settings State ─────────────────────────────────────────
  bool _notifsEnabled = true;
  bool _dailyEnabled = false;
  int _dailyHour = 9;
  int _dailyMinute = 0;
  bool _wakelockOn = true;
  bool _soundMuted = false;
  double _ambientVol = 0.5;
  double _sfxVol = 0.8;

  late final AnimationController _enterCtrl;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadPrefs();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifsEnabled = prefs.getBool(NotifPrefs.enabled) ?? true;
      _dailyEnabled = prefs.getBool(NotifPrefs.dailyEnabled) ?? false;
      _dailyHour = prefs.getInt(NotifPrefs.dailyHour) ?? 9;
      _dailyMinute = prefs.getInt(NotifPrefs.dailyMinute) ?? 0;
      _soundMuted = _audio.isMuted;
      _ambientVol = _audio.ambientVolume;
      _sfxVol = _audio.sfxVolume;
    });
    _wakelockOn = await WakelockService.getPreference();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _S.ink,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _enterCtrl,
            builder: (_, child) {
              final opacity = _enterCtrl.value.clamp(0.0, 1.0);
              return Opacity(opacity: opacity, child: child);
            },
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildSoundSection(),
                      const SizedBox(height: 20),
                      _buildDisplaySection(),
                      const SizedBox(height: 20),
                      _buildNotificationSection(),
                      const SizedBox(height: 20),
                      _buildDataSection(),
                      const SizedBox(height: 20),
                      _buildAboutSection(),
                    const SizedBox(height: 20),
                    _buildFeaturesSection(),
                  const SizedBox(height: 20),
                  _buildLogoutSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
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
                color: _S.surface,
                border: Border.all(color: _S.brass.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _S.cream,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SETTINGS',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _S.cream,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'CONTROL ROOM',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: _S.t2,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_S.brassLt, _S.brass, _S.brassDk],
              ),
            ),
            child: const Icon(Icons.settings_rounded, color: _S.ink, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Sound Section ──────────────────────────────────────────

  Widget _buildSoundSection() {
    return _Section(
      icon: Icons.music_note_rounded,
      title: 'SOUND',
      children: [
        _ToggleTile(
          icon:
              _soundMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          label: 'Master Audio',
          desc: _soundMuted ? 'All sounds muted' : 'Sounds enabled',
          value: !_soundMuted,
          onChanged: (val) async {
            HapticFeedback.lightImpact();
            await _audio.setMuted(!val);
            setState(() => _soundMuted = _audio.isMuted);
          },
        ),
        if (!_soundMuted) ...[
          _SliderTile(
            icon: Icons.train_rounded,
            label: 'Ambient Volume',
            value: _ambientVol,
            onChanged: (val) {
              setState(() => _ambientVol = val);
              _audio.setAmbientVolume(val);
            },
          ),
          _SliderTile(
            icon: Icons.notifications_active_rounded,
            label: 'Effects Volume',
            value: _sfxVol,
            onChanged: (val) {
              setState(() => _sfxVol = val);
              _audio.setSfxVolume(val);
            },
          ),
        ],
      ],
    );
  }

  // ── Display Section ────────────────────────────────────────

  Widget _buildDisplaySection() {
    return _Section(
      icon: Icons.display_settings_rounded,
      title: 'DISPLAY',
      children: [
        _ToggleTile(
          icon: Icons.light_mode_rounded,
          label: 'Keep Screen On',
          desc: 'Prevents screen sleep during focus',
          value: _wakelockOn,
          onChanged: (val) async {
            HapticFeedback.lightImpact();
            await WakelockService.setPreference(val);
            setState(() => _wakelockOn = val);
          },
        ),
      ],
    );
  }

  // ── Notification Section ───────────────────────────────────

  Widget _buildNotificationSection() {
    return _Section(
      icon: Icons.notifications_rounded,
      title: 'NOTIFICATIONS',
      children: [
        _ToggleTile(
          icon: Icons.circle_notifications_rounded,
          label: 'Notifications',
          desc: 'Session complete & streak alerts',
          value: _notifsEnabled,
          onChanged: (val) async {
            HapticFeedback.lightImpact();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(NotifPrefs.enabled, val);
            if (val) {
              await NotificationService.requestPermission();
            }
            setState(() => _notifsEnabled = val);
          },
        ),
        if (_notifsEnabled) ...[
          _ToggleTile(
            icon: Icons.alarm_rounded,
            label: 'Daily Reminder',
            desc: 'Reminds you to start a journey',
            value: _dailyEnabled,
            onChanged: (val) async {
              HapticFeedback.lightImpact();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(NotifPrefs.dailyEnabled, val);
              setState(() => _dailyEnabled = val);
              if (val) {
                await NotificationService.scheduleDailyReminder(
                  hour: _dailyHour,
                  minute: _dailyMinute,
                );
              } else {
                await NotificationService.cancelDailyReminder();
              }
            },
          ),
          if (_dailyEnabled)
            _TimeTile(
              icon: Icons.schedule_rounded,
              label: 'Reminder Time',
              hour: _dailyHour,
              minute: _dailyMinute,
              onChanged: (h, m) async {
                HapticFeedback.lightImpact();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt(NotifPrefs.dailyHour, h);
                await prefs.setInt(NotifPrefs.dailyMinute, m);
                setState(() {
                  _dailyHour = h;
                  _dailyMinute = m;
                });
                await NotificationService.scheduleDailyReminder(
                  hour: h,
                  minute: m,
                );
              },
            ),
        ],
      ],
    );
  }

  // ── Data Section ───────────────────────────────────────────

  Widget _buildDataSection() {
    return _Section(
      icon: Icons.storage_rounded,
      title: 'DATA',
      children: [
        _ActionTile(
          icon: Icons.analytics_outlined,
          label: 'View Analytics',
          desc: 'Detailed stats and charts',
          color: _S.brass,
          onTap: () => context.push(AppRouter.stats),
        ),
        _ActionTile(
          icon: Icons.download_rounded,
          label: 'Export Data (CSV)',
          desc: 'Download all session history',
          color: _S.brass,
          onTap: () => _exportCsv(),
        ),
        _ActionTile(
          icon: Icons.delete_outline_rounded,
          label: 'Clear Journey History',
          desc: 'Permanently delete all past sessions',
          color: _S.danger,
          onTap: () => _showClearDialog(),
        ),
      ],
    );
  }

  Future<void> _exportCsv() async {
    try {
      HapticFeedback.lightImpact();
      final csv = _storage.exportDataAsCsv();
      if (csv.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No data to export',
                style: GoogleFonts.cormorantGaramond(color: _S.cream),
              ),
              backgroundColor: _S.panel,
            ),
          );
        }
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/railfocus_export.csv');
      await file.writeAsString(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported to ${file.path}',
              style: GoogleFonts.cormorantGaramond(color: _S.cream),
            ),
            backgroundColor: _S.panel,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Export failed: $e',
              style: GoogleFonts.cormorantGaramond(color: _S.cream),
            ),
            backgroundColor: _S.danger,
          ),
        );
      }
    }
  }

  void _showClearDialog() {
    showDialog(
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
                  color: _S.panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _S.danger.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _S.danger.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: _S.danger,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'CLEAR ALL DATA?',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _S.cream,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This will permanently delete all journey history, '
                      'stats, and streaks. This cannot be undone.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 14,
                        color: _S.t2,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: _S.surface,
                              ),
                              child: Center(
                                child: Text(
                                  'CANCEL',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    color: _S.cream,
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
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              _storage.clearAll();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'All journey data cleared',
                                    style: GoogleFonts.cormorantGaramond(
                                      color: _S.cream,
                                    ),
                                  ),
                                  backgroundColor: _S.panel,
                                ),
                              );
                              setState(() {});
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: _S.danger,
                              ),
                              child: Center(
                                child: Text(
                                  'DELETE ALL',
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
  }

  // ── About Section ──────────────────────────────────────────

  Widget _buildAboutSection() {
    return _Section(
      icon: Icons.info_outline_rounded,
      title: 'ABOUT',
      children: [
        _InfoTile(label: 'App', value: 'RailFocus'),
        _InfoTile(label: 'Version', value: '1.0.0'),
        _InfoTile(label: 'Theme', value: 'Luxe Rail — Obsidian & Gilt'),
        _InfoTile(label: 'Made with', value: '❤️ Flutter & Dart'),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return _Section(
      title: 'FEATURES',
      icon: Icons.auto_awesome_rounded,
      children: [
        _FeatureTile(
          emoji: '📊',
          title: 'AI Focus Insights',
          subtitle: 'Analytics, coaching & weekly report',
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(AppRouter.insights);
          },
        ),
        const SizedBox(height: 8),
        _FeatureTile(
          emoji: '🚫',
          title: 'App Blocker',
          subtitle: 'Block distractions during focus',
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(AppRouter.appBlocker);
          },
        ),
        const SizedBox(height: 8),
        _FeatureTile(
          emoji: '🧘',
          title: 'Breathing Exercise',
          subtitle: '4-7-8 breathing to calm your mind',
          onTap: () {
            HapticFeedback.lightImpact();
            showGeneralDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.black87,
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (_, __, ___) => _BreathingDialog(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogoutSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              title: Text(
                'Sign Out',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF7E7CE),
                ),
              ),
              content: Text(
                'Are you sure you want to sign out?',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  color: const Color(0xFFF7E7CE).withValues(alpha: 0.7),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      color: const Color(0xFFF7E7CE).withValues(alpha: 0.5),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await AuthService.instance.signOut();
                    if (mounted) context.go(AppRouter.login);
                  },
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.red.withValues(alpha: 0.08),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.redAccent.withValues(alpha: 0.8),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'SIGN OUT',
                style: GoogleFonts.spaceMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent.withValues(alpha: 0.8),
                  letterSpacing: 2,
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
// SECTION CONTAINER
// ═══════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _S.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _S.brass.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Icon(icon, color: _S.brass, size: 16),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _S.brass,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _S.brass.withValues(alpha: 0.08)),
          // Children
          ...children,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOGGLE TILE
// ═══════════════════════════════════════════════════════════════

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.desc,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: value ? _S.brass : _S.t3, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _S.cream,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 12,
                    color: _S.t2,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _S.brass,
            activeTrackColor: _S.brass.withValues(alpha: 0.3),
            inactiveThumbColor: _S.t3,
            inactiveTrackColor: _S.surface,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SLIDER TILE
// ═══════════════════════════════════════════════════════════════

class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
      child: Row(
        children: [
          Icon(icon, color: _S.brass, size: 18),
          const SizedBox(width: 14),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 13,
                color: _S.cream,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: _S.brass,
                inactiveTrackColor: _S.surface,
                thumbColor: _S.cream,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: SliderComponentShape.noOverlay,
                trackHeight: 3,
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
            width: 36,
            child: Text(
              '${(value * 100).round()}%',
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceMono(fontSize: 10, color: _S.t2),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TIME PICKER TILE
// ═══════════════════════════════════════════════════════════════

class _TimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int hour;
  final int minute;
  final void Function(int h, int m) onChanged;

  const _TimeTile({
    required this.icon,
    required this.label,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$displayHour:${minute.toString().padLeft(2, '0')} $period';

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          builder: (ctx, child) {
            return Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: _S.brass,
                  onPrimary: _S.ink,
                  surface: _S.panel,
                  onSurface: _S.cream,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onChanged(picked.hour, picked.minute);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: _S.brass, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _S.cream,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _S.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _S.brass.withValues(alpha: 0.2)),
              ),
              child: Text(
                timeStr,
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _S.brass,
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
// ACTION TILE (for destructive actions)
// ═══════════════════════════════════════════════════════════════

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    desc,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 12,
                      color: _S.t2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// INFO TILE (read-only)
// ═══════════════════════════════════════════════════════════════

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.cormorantGaramond(fontSize: 14, color: _S.t2),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _S.cream,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FEATURE TILE
// ═══════════════════════════════════════════════════════════════

class _FeatureTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131620),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD4A853).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF5EDDB),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 12,
                      color: const Color(0xFF706A5C),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: const Color(0xFF706A5C).withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BREATHING DIALOG
// ═══════════════════════════════════════════════════════════════

class _BreathingDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BreathingExercise(
        onComplete: () => Navigator.of(context).pop(),
        onSkip: () => Navigator.of(context).pop(),
      ),
    );
  }
}
