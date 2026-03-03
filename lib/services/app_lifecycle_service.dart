// ═══════════════════════════════════════════════════════════════
//  APP LIFECYCLE SERVICE
//  Handles background/foreground transitions gracefully.
//  Pauses timers, stops audio, saves state when app goes to bg.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Mixin for any screen that needs lifecycle awareness.
/// Add to your State class: `with AppLifecycleAware`
mixin AppLifecycleAware<T extends StatefulWidget> on State<T> {
  late final AppLifecycleListener _lifecycleListener;

  bool _isInBackground = false;
  bool get isInBackground => _isInBackground;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        _isInBackground = true;
        onBackground();
      },
      onInactive: () {
        _isInBackground = true;
        onBackground();
      },
      onResume: () {
        _isInBackground = false;
        onForeground();
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  /// Override in your screen to pause timers, stop audio, etc.
  void onBackground() {}

  /// Override in your screen to resume timers, refresh data, etc.
  void onForeground() {}
}
