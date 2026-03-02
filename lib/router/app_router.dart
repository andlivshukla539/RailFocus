import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/route_model.dart';
import '../screens/focus_screen.dart' show FocusScreen;
import '../screens/home_screen.dart' show HomeScreen;
import '../screens/booking_screen.dart' show BookingScreen;
import '../screens/boarding_screen.dart' show BoardingRitualScreen;
import '../screens/arrival_screen.dart' show ArrivalScreen;
import '../screens/history_screen.dart' show HistoryScreen;
import '../screens/onboarding_screen.dart' show OnboardingScreen;
import '../screens/settings_screen.dart' show SettingsScreen;
import '../screens/splash_screen.dart' show SplashScreen;

class AppRouter {
  AppRouter._();

  static const String splash     = '/splash';
  static const String home       = '/';
  static const String booking    = '/booking';
  static const String boarding   = '/boarding';
  static const String focus      = '/focus';
  static const String arrival    = '/arrival';
  static const String history    = '/history';
  static const String onboarding = '/onboarding';
  static const String settings   = '/settings';

  static const String splashName     = 'splash';
  static const String homeName       = 'home';
  static const String bookingName    = 'booking';
  static const String boardingName   = 'boarding';
  static const String focusName      = 'focus';
  static const String arrivalName    = 'arrival';
  static const String historyName    = 'history';
  static const String onboardingName = 'onboarding';
  static const String settingsName   = 'settings';
}

enum TransitionType {
  fadeSlideUp,
  fadeSlideRight,
  fadeScale,
  fade,
  trainDeparture,
  trainArrival,
  slideFromRight,
}

CustomTransitionPage<T> _buildLuxeTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  TransitionType type = TransitionType.fadeSlideUp,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      switch (type) {
        case TransitionType.fadeSlideUp:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08), end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        case TransitionType.fadeSlideRight:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0), end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        case TransitionType.fadeScale:
          return ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        case TransitionType.fade:
          return FadeTransition(opacity: curved, child: child);
        case TransitionType.trainDeparture:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0), end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation, curve: Curves.easeOutExpo,
            )),
            child: FadeTransition(opacity: animation, child: child),
          );
        case TransitionType.trainArrival:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.3, 0), end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation, curve: Curves.easeOutBack,
            )),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            ),
          );
        case TransitionType.slideFromRight:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0), end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation, curve: Curves.easeInOutCubic,
            )),
            child: child,
          );
      }
    },
  );
}

bool onboardingCompleted = false;

void markOnboardingDone() {
  onboardingCompleted = true;
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRouter.splash,
  debugLogDiagnostics: true,

  redirect: (context, state) {
    final loc = state.matchedLocation;
    if (loc == AppRouter.splash) return null;
    if (!onboardingCompleted && loc != AppRouter.onboarding) {
      return AppRouter.onboarding;
    }
    if (onboardingCompleted && loc == AppRouter.onboarding) {
      return AppRouter.home;
    }
    return null;
  },

  errorBuilder: (context, state) => ErrorScreen(error: state.error),

  routes: [
    // ═══ SPLASH ═══
    GoRoute(
      path: AppRouter.splash,
      name: AppRouter.splashName,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: SplashScreen(
          onComplete: () => appRouter.go(AppRouter.home),
        ),
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    ),

    // ═══ HOME ═══
    GoRoute(
      path: AppRouter.home,
      name: AppRouter.homeName,
      pageBuilder: (context, state) => _buildLuxeTransition(
        context: context, state: state,
        child: const HomeScreen(),
        type: TransitionType.fade,
      ),
    ),

    // ═══ ONBOARDING ═══
    GoRoute(
      path: AppRouter.onboarding,
      name: AppRouter.onboardingName,
      pageBuilder: (context, state) => _buildLuxeTransition(
        context: context, state: state,
        child: const OnboardingScreen(),
        type: TransitionType.fade,
      ),
    ),

    // ═══ SETTINGS ═══
    GoRoute(
      path: AppRouter.settings,
      name: AppRouter.settingsName,
      pageBuilder: (context, state) => _buildLuxeTransition(
        context: context, state: state,
        child: const SettingsScreen(),
        type: TransitionType.slideFromRight,
      ),
    ),

    // ═══ BOOKING ═══
    GoRoute(
      path: AppRouter.booking,
      name: AppRouter.bookingName,
      pageBuilder: (context, state) => _buildLuxeTransition(
        context: context, state: state,
        child: const BookingScreen(),
        type: TransitionType.fadeSlideUp,
      ),
    ),

    // ═══ BOARDING — READS extra DATA ═══
    GoRoute(
      path: AppRouter.boarding,
      name: AppRouter.boardingName,
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        return _buildLuxeTransition(
          context: context, state: state,
          child: BoardingRitualScreen(
            route: data?['route'] as RouteModel?,
            mood: data?['mood'] as String?,
            goal: data?['goal'] as String?,
            durationMinutes: data?['durationMinutes'] as int?,
          ),
          type: TransitionType.fadeScale,
        );
      },
    ),

    // ═══ FOCUS — READS extra DATA ═══
    GoRoute(
      path: AppRouter.focus,
      name: AppRouter.focusName,
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        return _buildLuxeTransition(
          context: context, state: state,
          child: FocusScreen(
            route: data?['route'] as RouteModel?,
            mood: data?['mood'] as String?,
            goal: data?['goal'] as String?,
            durationMinutes: data?['durationMinutes'] as int?,
          ),
          type: TransitionType.trainDeparture,
        );
      },
    ),

    // ═══ ARRIVAL — Uses existing constructor (no named params) ═══
    GoRoute(
      path: AppRouter.arrival,
      name: AppRouter.arrivalName,
      pageBuilder: (context, state) {
        return _buildLuxeTransition(
          context: context, state: state,
          child: const ArrivalScreen(),
          type: TransitionType.trainArrival,
        );
      },
    ),

    // ═══ HISTORY ═══
    GoRoute(
      path: AppRouter.history,
      name: AppRouter.historyName,
      pageBuilder: (context, state) => _buildLuxeTransition(
        context: context, state: state,
        child: const HistoryScreen(),
        type: TransitionType.fadeSlideRight,
      ),
    ),
  ],
);

class ErrorScreen extends StatelessWidget {
  final Exception? error;
  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3), width: 2,
                  ),
                ),
                child: const Icon(Icons.train_outlined, size: 48, color: Colors.red),
              ),
              const SizedBox(height: 32),
              const Text('DERAILED',
                style: TextStyle(
                  fontFamily: 'Cinzel', fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF7E7CE), letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 12),
              Text('This route doesn\'t exist',
                style: TextStyle(
                  fontFamily: 'Cormorant Garamond', fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFF7E7CE).withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => context.go(AppRouter.home),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFFF7E7CE), Color(0xFFD4A574), Color(0xFF8B6914),
                    ]),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4A574).withValues(alpha: 0.4),
                        blurRadius: 20, spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home_rounded, color: Color(0xFF0A0A0F), size: 20),
                      SizedBox(width: 12),
                      Text('RETURN TO STATION',
                        style: TextStyle(
                          fontFamily: 'Cinzel', fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A0A0F), letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension NavigationExtension on BuildContext {
  void goToBooking() => push(AppRouter.booking);
  void goToBoarding({Map<String, dynamic>? sessionData}) {
    push(AppRouter.boarding, extra: sessionData);
  }
  void goToFocus({required Map<String, dynamic> sessionData}) {
    go(AppRouter.focus, extra: sessionData);
  }
  void goToArrival({required Map<String, dynamic> completionData}) {
    go(AppRouter.arrival, extra: completionData);
  }
  void goToHistory() => push(AppRouter.history);
  void goToSettings() => push(AppRouter.settings);
  void goHome() => go(AppRouter.home);
}