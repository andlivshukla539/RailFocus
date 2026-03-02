import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'router/app_router.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'theme/luxe_theme.dart';
import 'widgets/error_boundary.dart';

void main() async {
  // ══════════════════════════════════════════════════════════
  // STEP 1: ENSURE FLUTTER IS READY
  // ══════════════════════════════════════════════════════════
  WidgetsFlutterBinding.ensureInitialized();

  // ══════════════════════════════════════════════════════════
  // STEP 1.5: ERROR HANDLING
  // ══════════════════════════════════════════════════════════
  ErrorBoundary.setupGlobalErrorHandler();

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🔴 Flutter Error: ${details.exception}');
    debugPrint('   Stack: ${details.stack}');
  };

  GoogleFonts.config.allowRuntimeFetching = false;

  // ══════════════════════════════════════════════════════════
  // STEP 2: ENABLE HIGHEST REFRESH RATE
  // ══════════════════════════════════════════════════════════
  try {
    await FlutterDisplayMode.setHighRefreshRate();
    debugPrint('✓ High refresh rate enabled');
  } catch (e) {
    debugPrint('ℹ High refresh rate not available: $e');
  }

  // ══════════════════════════════════════════════════════════
  // STEP 3: CONFIGURE SYSTEM UI
  // ══════════════════════════════════════════════════════════
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: LuxeColors.obsidian,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // ══════════════════════════════════════════════════════════
  // STEP 4: LOCK TO PORTRAIT MODE
  // ══════════════════════════════════════════════════════════
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ══════════════════════════════════════════════════════════
  // STEP 5: INITIALIZE HIVE LOCAL STORAGE
  // ══════════════════════════════════════════════════════════
  await Hive.initFlutter();

  // ══════════════════════════════════════════════════════════
  // STEP 6: OPEN STORAGE BOXES
  // ══════════════════════════════════════════════════════════
  await Future.wait([
    Hive.openBox('stats'),
    Hive.openBox('sessions'),
  ]);

  debugPrint('✓ Storage initialized');

  // ══════════════════════════════════════════════════════════
  // STEP 7: INITIALIZE AUDIO SERVICE
  // ══════════════════════════════════════════════════════════
  AudioService();
  debugPrint('🔊 RailFocus: Audio service ready');

  // ══════════════════════════════════════════════════════════
  // STEP 8: INITIALIZE NOTIFICATION SERVICE
  // ══════════════════════════════════════════════════════════
  try {
    await NotificationService.init();
    debugPrint('🔔 RailFocus: Notification service ready');
  } catch (e) {
    debugPrint('🔴 RailFocus: Notification init failed (non-fatal): $e');
  }

  // ══════════════════════════════════════════════════════════
  // STEP 9: LOAD ONBOARDING STATUS (BEFORE runApp!)
  // ══════════════════════════════════════════════════════════
  // This MUST happen before runApp() so the router's
  // synchronous redirect can check it without awaiting.
  final prefs = await SharedPreferences.getInstance();
  onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  debugPrint('✓ Onboarding completed: $onboardingCompleted');

  // ══════════════════════════════════════════════════════════
  // STEP 10: LAUNCH THE APP
  // ══════════════════════════════════════════════════════════
  runApp(const RailFocusApp());
}

// ══════════════════════════════════════════════════════════════
// ROOT APP WIDGET
// ══════════════════════════════════════════════════════════════

class RailFocusApp extends StatelessWidget {
  const RailFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RailFocus',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _LuxeScrollBehavior(),
      theme: _buildLuxeTheme(),
      routerConfig: appRouter,
      showPerformanceOverlay: false,
    );
  }

  ThemeData _buildLuxeTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: LuxeColors.obsidian,
      colorScheme: const ColorScheme.dark(
        primary: LuxeColors.gold,
        secondary: LuxeColors.champagne,
        tertiary: LuxeColors.roseGold,
        surface: LuxeColors.obsidian,
        surfaceContainerHighest: LuxeColors.velvet,
        error: Color(0xFFCF6679),
        onPrimary: LuxeColors.obsidian,
        onSecondary: LuxeColors.obsidian,
        onSurface: LuxeColors.champagne,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: LuxeColors.champagne, size: 22),
        titleTextStyle: TextStyle(
          fontFamily: 'Cinzel', fontSize: 16,
          fontWeight: FontWeight.w700,
          color: LuxeColors.champagne, letterSpacing: 2.0,
        ),
      ),
      cardTheme: CardThemeData(
        color: LuxeColors.velvet, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: LuxeColors.gold.withValues(alpha: 0.1)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LuxeColors.gold,
          foregroundColor: LuxeColors.obsidian,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(
            fontFamily: 'Cinzel', fontSize: 14,
            fontWeight: FontWeight.w700, letterSpacing: 2.0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LuxeColors.gold,
          textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w600, letterSpacing: 1.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LuxeColors.velvet,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: LuxeColors.gold.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LuxeColors.gold, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          color: LuxeColors.champagne.withValues(alpha: 0.4),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: LuxeColors.velvet, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: LuxeColors.gold.withValues(alpha: 0.2)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: LuxeColors.velvet, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LuxeColors.charcoal,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter', color: LuxeColors.champagne,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: LuxeColors.gold.withValues(alpha: 0.1), thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,
      highlightColor: LuxeColors.gold.withValues(alpha: 0.1),
      splashColor: LuxeColors.gold.withValues(alpha: 0.2),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Cinzel', fontSize: 32, fontWeight: FontWeight.w700,
          color: LuxeColors.champagne, letterSpacing: 1.0,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Cinzel', fontSize: 28, fontWeight: FontWeight.w700,
          color: LuxeColors.champagne, letterSpacing: 1.0,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Cinzel', fontSize: 24, fontWeight: FontWeight.w700,
          color: LuxeColors.champagne, letterSpacing: 1.0,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Cinzel', fontSize: 20, fontWeight: FontWeight.w600,
          color: LuxeColors.champagne,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Cinzel', fontSize: 18, fontWeight: FontWeight.w600,
          color: LuxeColors.champagne, letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600,
          color: LuxeColors.champagne,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400,
          color: LuxeColors.champagne, height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400,
          color: LuxeColors.textSecondary, height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400,
          color: LuxeColors.textMuted,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700,
          color: LuxeColors.champagne, letterSpacing: 1.5,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600,
          color: LuxeColors.textMuted, letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CUSTOM SCROLL BEHAVIOR
// ══════════════════════════════════════════════════════════════

class _LuxeScrollBehavior extends ScrollBehavior {
  const _LuxeScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      decelerationRate: ScrollDecelerationRate.fast,
    );
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context,
      Widget child,
      ScrollableDetails details,
      ) {
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}