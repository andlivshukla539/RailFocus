// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — AUDIO SERVICE
//  Theme: Immersive Soundscape Engine
//
//  ARCHITECTURE:
//  ─────────────────────────────────────────────────────────────
//  • Two separate audio players: ambient (loops) + SFX (one-shot)
//  • Volume control with smooth fade in/out
//  • Mute toggle that remembers state
//  • Route-aware ambient selection (rain for Scotland, etc.)
//  • Singleton pattern — one instance shared across all screens
//
//  USAGE:
//    AudioService().playAmbient('train_ambient.mp3');
//    AudioService().playSfx('whistle.mp3');
//    AudioService().fadeOutAndStop();
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════
// AUDIO ASSET PATHS
// ═══════════════════════════════════════════════════════════════
// Centralized constants so we never mistype a file name.
// Every screen references these instead of raw strings.

class AudioAssets {
  AudioAssets._(); // Private constructor — can't instantiate

  // ── Ambient loops (long, looping background sounds) ────────
  static const String sleepAmbient = 'sounds/Sleep.mp3';
  static const String trainAmbient = 'sounds/train_ambient.mp3';

  // ── SFX (short, one-shot sounds) ───────────────────────────
  static const String whistle = 'sounds/whistle.mp3';
  static const String ticketStamp = 'sounds/ticket_stamp.mp3';
  static const String arrivalBell = 'sounds/arrival_bell.mp3';
  static const String click = 'sounds/click.mp3';

  // ── Route-specific ambient mapping ─────────────────────────
  // User prefers Sleep.mp3 for all focus sessions.
  static String ambientForRoute(String routeId) {
    return sleepAmbient;
  }
}

// ═══════════════════════════════════════════════════════════════
// AUDIO SERVICE (SINGLETON)
// ═══════════════════════════════════════════════════════════════
// Singleton pattern: only ONE instance of AudioService exists.
//
// WHY SINGLETON?
// If two screens each created their own AudioService, we'd have
// TWO ambient players fighting each other. Singleton ensures
// one shared service controls all audio app-wide.
//
// HOW IT WORKS:
//   AudioService()  ← always returns the SAME instance
//   AudioService._internal()  ← the real constructor, called ONCE

class AudioService {
  // ── Singleton Setup ────────────────────────────────────────
  // _instance holds the one-and-only AudioService object.
  static final AudioService _instance = AudioService._internal();

  // Factory constructor — returns the existing _instance every time.
  // This means `AudioService()` never creates a NEW object.
  factory AudioService() => _instance;

  // The real (private) constructor — runs only ONCE when _instance is created.
  AudioService._internal() {
    _initPlayers();
  }

  // ── Players ────────────────────────────────────────────────
  // Two separate AudioPlayer instances so ambient and SFX
  // can play simultaneously without interrupting each other.

  late final AudioPlayer _ambientPlayer; // Loops: train sounds, rain
  late final AudioPlayer _sfxPlayer; // One-shots: whistle, bell, click

  // ── State ──────────────────────────────────────────────────

  bool _isMuted = false; // Master mute toggle
  double _ambientVolume = 0.5; // Ambient volume (0.0 to 1.0)
  double _sfxVolume = 0.8; // SFX volume (louder than ambient)
  bool _isAmbientPlaying = false;
  Timer? _fadeTimer; // Used for smooth fade in/out

  // ── Getters ────────────────────────────────────────────────
  // Public read-only access to state. Screens can check these
  // to update their UI (e.g., show mute icon).

  bool get isMuted => _isMuted;
  bool get isAmbientPlaying => _isAmbientPlaying;
  double get ambientVolume => _ambientVolume;
  double get sfxVolume => _sfxVolume;

  // ══════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═════��════════════════════════════════════════════════════

  void _initPlayers() {
    _ambientPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();

    // Set the release mode for ambient to LOOP — it replays automatically.
    _ambientPlayer.setReleaseMode(ReleaseMode.loop);

    // SFX plays once and stops — this is the default (ReleaseMode.release),
    // but we set it explicitly for clarity.
    _sfxPlayer.setReleaseMode(ReleaseMode.release);

    debugPrint('🔊 AudioService: Players initialized');
  }

  // ══════════════════════════════════════════════════════════
  // AMBIENT AUDIO (Looping background sounds)
  // ══════════════════════════════════════════════════════════

  /// Starts playing an ambient sound on loop.
  /// [assetPath] should be from AudioAssets (e.g., AudioAssets.trainAmbient).
  /// [fadeIn] = whether to gradually increase volume from 0 (smooth start).
  Future<void> playAmbient(String assetPath, {bool fadeIn = true}) async {
    try {
      // Stop any currently playing ambient first.
      await stopAmbient();

      // If muted, still "load" the track but don't actually play.
      // This way, unmuting later can resume seamlessly.
      if (_isMuted) {
        debugPrint('🔇 AudioService: Muted — ambient loaded but silent');
        return;
      }

      // AssetSource tells audioplayers to look in the Flutter assets folder.
      // The path is relative to the assets/ directory.
      final source = AssetSource(assetPath);

      if (fadeIn) {
        // Start at zero volume, then gradually increase.
        await _ambientPlayer.setVolume(0.0);
        await _ambientPlayer.play(source);
        _isAmbientPlaying = true;

        // Fade in over 2 seconds.
        _fadeToVolume(_ambientPlayer, _ambientVolume, duration: 2000);
      } else {
        // Instant start at full ambient volume.
        await _ambientPlayer.setVolume(_ambientVolume);
        await _ambientPlayer.play(source);
        _isAmbientPlaying = true;
      }

      debugPrint('🔊 AudioService: Ambient playing →  $assetPath');
    } catch (e) {
      // Don't crash the app if audio fails — just log it.
      // Audio is enhancement, not critical functionality.
      debugPrint('🔴 AudioService: Failed to play ambient → $e');
    }
  }

  /// Starts the correct ambient sound for a specific route.
  /// Called by FocusScreen when the session begins.
  Future<void> playAmbientForRoute(String routeId) async {
    final assetPath = AudioAssets.ambientForRoute(routeId);
    await playAmbient(assetPath);
  }

  /// Stops ambient audio with an optional fade-out.
  /// [fadeOut] = gradually decrease volume before stopping (smooth end).
  Future<void> stopAmbient({bool fadeOut = true}) async {
    // Cancel any ongoing fade operation.
    _fadeTimer?.cancel();

    if (!_isAmbientPlaying) return; // Nothing to stop

    try {
      if (fadeOut && !_isMuted) {
        // Fade out over 1.5 seconds, THEN stop.
        await _fadeToVolume(_ambientPlayer, 0.0, duration: 1500);
        await _ambientPlayer.stop();
      } else {
        // Instant stop.
        await _ambientPlayer.stop();
      }

      _isAmbientPlaying = false;
      debugPrint('🔊 AudioService: Ambient stopped');
    } catch (e) {
      debugPrint('🔴 AudioService: Failed to stop ambient → $e');
      _isAmbientPlaying = false;
    }
  }

  /// Pauses ambient audio (e.g., when app goes to background).
  /// Can be resumed with resumeAmbient().
  Future<void> pauseAmbient() async {
    if (!_isAmbientPlaying || _isMuted) return;

    try {
      await _ambientPlayer.pause();
      debugPrint('🔊 AudioService: Ambient paused');
    } catch (e) {
      debugPrint('🔴 AudioService: Failed to pause ambient → $e');
    }
  }

  /// Resumes paused ambient audio.
  Future<void> resumeAmbient() async {
    if (!_isAmbientPlaying || _isMuted) return;

    try {
      await _ambientPlayer.resume();
      debugPrint('🔊 AudioService: Ambient resumed');
    } catch (e) {
      debugPrint('🔴 AudioService: Failed to resume ambient → $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  // SFX AUDIO (Short one-shot sounds)
  // ══════════════════════════════════════════════════════════

  /// Plays a short sound effect once.
  /// [assetPath] should be from AudioAssets (e.g., AudioAssets.whistle).
  /// SFX plays ON TOP of ambient — they don't interfere.
  Future<void> playSfx(String assetPath) async {
    // Respect mute — no sounds at all when muted.
    if (_isMuted) return;

    try {
      // Stop any currently playing SFX (e.g., if user taps rapidly).
      await _sfxPlayer.stop();

      // Set SFX volume and play.
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource(assetPath));

      debugPrint('🔊 AudioService: SFX → $assetPath');
    } catch (e) {
      // Audio failure is never app-breaking — just log.
      debugPrint('🔴 AudioService: Failed to play SFX → $e');
    }
  }

  // ── Convenience methods for common SFX ─────────────────

  /// 🚂 Train whistle — boarding departure moment.
  Future<void> playWhistle() => playSfx(AudioAssets.whistle);

  /// 🎫 Ticket stamp — boarding ritual scan animation.
  Future<void> playTicketStamp() => playSfx(AudioAssets.ticketStamp);

  /// 🔔 Arrival bell — session complete celebration.
  Future<void> playArrivalBell() => playSfx(AudioAssets.arrivalBell);

  /// 🖱️ UI click — uses Android/iOS native system sound.
  /// No MP3 file needed! Works on all devices.
  Future<void> playClick() async {
    if (_isMuted) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// 🌟 Important click — system click + medium haptic for key moments.
  /// Use for: booking confirm, session start, achievement unlock.
  Future<void> playImportantClick() async {
    if (_isMuted) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
  }

  // ══════════════════════════════════════════════════════════
  // VOLUME CONTROLS
  // ══════════════════════════════════════════════════════════

  /// Sets the ambient volume (0.0 to 1.0).
  /// Immediately applies to the running ambient player.
  Future<void> setAmbientVolume(double volume) async {
    // .clamp() ensures the value stays between 0.0 and 1.0.
    // Prevents bugs from sliders going out of range.
    _ambientVolume = volume.clamp(0.0, 1.0);

    if (!_isMuted && _isAmbientPlaying) {
      await _ambientPlayer.setVolume(_ambientVolume);
    }
  }

  /// Sets the SFX volume (0.0 to 1.0).
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  // ══════════════════════════════════════════════════════════
  // MUTE TOGGLE
  // ══════════════════════════════════════════════════════════

  /// Toggles mute on/off. Returns the new mute state.
  /// When muted: ambient paused, SFX blocked.
  /// When unmuted: ambient resumed, SFX allowed.
  Future<bool> toggleMute() async {
    _isMuted = !_isMuted;

    if (_isMuted) {
      // Muting — pause the ambient player entirely
      if (_isAmbientPlaying) {
        try {
          await _ambientPlayer.pause();
        } catch (_) {}
      }
      debugPrint('🔇 AudioService: MUTED');
    } else {
      // Unmuting — resume ambient and restore volume
      if (_isAmbientPlaying) {
        try {
          await _ambientPlayer.setVolume(_ambientVolume);
          await _ambientPlayer.resume();
        } catch (_) {}
      }
      debugPrint('🔊 AudioService: UNMUTED');
    }

    return _isMuted;
  }

  /// Explicitly set mute state (used when loading saved preference).
  Future<void> setMuted(bool muted) async {
    if (_isMuted == muted) return; // No change needed
    await toggleMute(); // Toggle to the desired state
  }

  // ══════════════════════════════════════════════════════════
  // FADE ENGINE
  // ════════════��═════════════════════════════════════════════
  // Smoothly transitions volume from current level to target.
  // Used for fade-in (start of session) and fade-out (end).
  //
  // HOW IT WORKS:
  // We use a Timer.periodic that fires every 50ms, nudging
  // the volume slightly toward the target. This creates a
  // smooth, cinematic volume transition.

  Future<void> _fadeToVolume(
    AudioPlayer player,
    double targetVolume, {
    int duration = 1500, // Total fade duration in milliseconds
  }) async {
    // Cancel any previous fade on this player.
    _fadeTimer?.cancel();

    // Get the current volume as our starting point.
    // We track ambient volume ourselves since audioplayers
    // doesn't expose a reliable getter on all platforms.
    double currentVolume =
        player == _ambientPlayer
            ? (await _ambientPlayer.getCurrentPosition() != null
                ? _ambientVolume
                : 0.0)
            : _sfxVolume;

    // Calculate how many steps and how much to change per step.
    const int stepMs = 50; // Update every 50 milliseconds
    final int steps = (duration / stepMs).round(); // Total number of steps
    final double delta =
        (targetVolume - currentVolume) / steps; // Change per step

    int currentStep = 0;

    // Completer lets us return a Future that resolves when the fade finishes.
    final completer = Completer<void>();

    _fadeTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      currentStep++;
      currentVolume += delta;

      // Clamp to prevent overshoot (floating point arithmetic isn't perfect).
      currentVolume = currentVolume.clamp(0.0, 1.0);

      player.setVolume(currentVolume);

      if (currentStep >= steps) {
        // Fade complete — set exact target volume and stop the timer.
        player.setVolume(targetVolume);
        timer.cancel();
        _fadeTimer = null;

        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    return completer.future;
  }

  // ══════════════════════════════════════════════════════════
  // CLEANUP
  // ���═════════════════════════════════════════════════════════

  /// Releases all audio resources. Call when the app is closing.
  /// In practice, this is rarely needed since the OS cleans up,
  /// but it's good hygiene.
  Future<void> dispose() async {
    _fadeTimer?.cancel();
    await _ambientPlayer.dispose();
    await _sfxPlayer.dispose();
    debugPrint('🔊 AudioService: Disposed');
  }
}
