// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';
import '../../services/auth_service.dart';
import '../../theme/luxe_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;
  _Btn? _activeBtn;

  void _setLoading(_Btn btn) {
    if (mounted) setState(() { _loading = true; _activeBtn = btn; _error = null; });
  }

  void _setError(String msg) {
    if (mounted) setState(() { _loading = false; _activeBtn = null; _error = msg; });
  }

  void _clearLoading() {
    if (mounted) setState(() { _loading = false; _activeBtn = null; });
  }

  Future<void> _googleSignIn() async {
    _setLoading(_Btn.google);
    try {
      final result = await AuthService.instance.signInWithGoogle();
      if (result == null) {
        _clearLoading(); // user cancelled
        return;
      }
      if (mounted) context.go(AppRouter.home);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Google exception: $e');
    } finally {
      if (mounted && _activeBtn == _Btn.google) _clearLoading();
    }
  }

  Future<void> _guestSignIn() async {
    _setLoading(_Btn.guest);
    debugPrint('🎫 Guest: calling signInAnonymously...');
    try {
      await AuthService.instance.signInAnonymously();
      debugPrint('🎫 Guest: signInAnonymously returned, isLocalGuest=${AuthService.instance.isLocalGuest}');
      if (mounted) {
        debugPrint('🎫 Guest: navigating to home...');
        context.go(AppRouter.home);
      }
    } on AuthException catch (e) {
      debugPrint('🎫 Guest: AuthException: ${e.code} ${e.message}');
      _setError(e.message);
    } catch (e) {
      debugPrint('🎫 Guest: raw exception: $e');
      _setError('Guest exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxeColors.obsidian,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ── Logo ─────────────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LuxeColors.velvet,
                  border: Border.all(
                    color: LuxeColors.gold.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: LuxeColors.gold.withValues(alpha: 0.15),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🚂', style: TextStyle(fontSize: 36)),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'RAILFOCUS',
                style: GoogleFonts.cinzel(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: LuxeColors.champagne,
                  letterSpacing: 6,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Your focus journey awaits',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: LuxeColors.textMuted,
                  letterSpacing: 1,
                ),
              ),

              const Spacer(flex: 2),

              // ── Error ─────────────────────────────────────────────────────
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCF6679).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFCF6679).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFCF6679),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 14,
                            color: const Color(0xFFCF6679),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Continue with Google ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _googleSignIn,
                  icon: _activeBtn == _Btn.google
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: LuxeColors.obsidian,
                          ),
                        )
                      : const Icon(
                          Icons.g_mobiledata_rounded,
                          size: 26,
                          color: LuxeColors.obsidian,
                        ),
                  label: Text(
                    _activeBtn == _Btn.google ? 'Signing in...' : 'Continue with Google',
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: LuxeColors.obsidian,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuxeColors.gold,
                    disabledBackgroundColor: LuxeColors.gold.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Continue as Guest ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _guestSignIn,
                  icon: _activeBtn == _Btn.guest
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: LuxeColors.textMuted,
                          ),
                        )
                      : const Icon(
                          Icons.person_outline_rounded,
                          size: 22,
                          color: LuxeColors.textMuted,
                        ),
                  label: Text(
                    _activeBtn == _Btn.guest ? 'Loading...' : 'Continue as Guest',
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: LuxeColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: LuxeColors.gold.withValues(alpha: 0.2),
                    ),
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // ── Footer note ───────────────────────────────────────────────
              Text(
                'Guest journeys are saved locally on this device',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 12,
                  color: LuxeColors.textMuted.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Btn { google, guest }
