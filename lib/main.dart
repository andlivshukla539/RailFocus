
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; // ← ADD
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart'; // ← ADD (flutterfire generated)
import 'router/app_router.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'services/achievement_service.dart';
import 'theme/luxe_theme.dart';
import 'theme/app_theme.dart';
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


  // ══════════════════════════════════════════════════════════
  // STEP 1.7: INITIALIZE FIREBASE
  // ══════════════════════════════════════════════════════════
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('✓ Firebase initialized');

  // ── Google Sign-In: initialize before first use ─────────────────────────
  // serverClientId is read automatically from google-services.json on Android
  await GoogleSignIn.instance.initialize(
    serverClientId: '936071010532-k17ipcj65e2es46v2mtocvkac5hoofgs.apps.googleusercontent.com',
  );
  debugPrint('✓ Google Sign-In initialized');

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
  await Future.wait([Hive.openBox('stats'), Hive.openBox('sessions'), Hive.openBox('projects')]);

  await AchievementService.init();
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
  final prefs = await SharedPreferences.getInstance();
  onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  debugPrint('✓ Onboarding completed: $onboardingCompleted');

  // ══════════════════════════════════════════════════════════
  // STEP 10: LAUNCH THE APP
  // ══════════════════════════════════════════════════════════
  runApp(const RailFocusApp());
}


// --------------------------------------------------------------
// ROOT APP WIDGET
// --------------------------------------------------------------

class RailFocusApp extends StatelessWidget {
  const RailFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RailFocus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      showPerformanceOverlay: false,
    );

  }
}

