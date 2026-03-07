// lib/services/firestore_sync_service.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — FIRESTORE SYNC SERVICE
//  Backs up user stats to Cloud Firestore so data survives
//  app reinstalls. Restores on fresh install.
//  Strategy: latest-timestamp wins for conflict resolution.
// ═══════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/session_model.dart';
import 'storage_service.dart';

class FirestoreSyncService {
  FirestoreSyncService._();
  static final instance = FirestoreSyncService._();

  final _fb = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = StorageService();

  /// Get the current user's document reference
  DocumentReference? get _userDoc {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _fb.collection('users').doc(user.uid);
  }

  // ══════════════════════════════════════
  // BACKUP (local → cloud)
  // ══════════════════════════════════════

  /// Sync current local stats to Firestore
  Future<void> backupStats() async {
    try {
      final doc = _userDoc;
      if (doc == null) return;

      final streak = _storage.getStreak();
      final totalHours = _storage.getTotalHours();
      final totalSessions = _storage.getTotalSessions();
      final bricks = _storage.getBricks();

      await doc.set({
        'stats': {
          'streak': streak,
          'totalHours': totalHours,
          'totalSessions': totalSessions,
          'bricks': bricks,
          'lastSync': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      debugPrint('☁️ Firestore: Stats backed up');
    } catch (e) {
      debugPrint('🔴 Firestore backup error: $e');
    }
  }

  /// Backup the most recent sessions (last 50)
  Future<void> backupSessions() async {
    try {
      final doc = _userDoc;
      if (doc == null) return;

      final sessions = _storage.getAllSessions().take(50).toList();
      final sessionMaps = sessions.map((s) => {
        'routeName': s.routeName,
        'durationMinutes': s.durationMinutes,
        'completed': s.completed,
        'startTime': s.startTime.toIso8601String(),
        'mood': s.mood,
        'goal': s.goal,
        'note': s.note,
      }).toList();

      await doc.set({
        'sessions': sessionMaps,
        'lastSessionSync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('☁️ Firestore: ${sessions.length} sessions backed up');
    } catch (e) {
      debugPrint('🔴 Firestore session backup error: $e');
    }
  }

  /// Full backup — stats + sessions
  Future<void> fullBackup() async {
    await backupStats();
    await backupSessions();
  }

  // ══════════════════════════════════════
  // RESTORE (cloud → local)
  // ══════════════════════════════════════

  /// Restores all user data (stats + sessions) from Firestore.
  /// Called after a successful login to bring back the user's progress.
  /// Only runs if local data is empty to avoid overwriting newer local data.
  Future<bool> restoreIfNeeded() async {
    try {
      final doc = _userDoc;
      if (doc == null) {
        debugPrint('☁️ Firestore: No user logged in, skipping restore');
        return false;
      }

      final snapshot = await doc.get();
      if (!snapshot.exists) {
        debugPrint('☁️ Firestore: No cloud data found for this user');
        return false;
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return false;

      // Only restore if local is completely empty.
      // This prevents overwriting data from a device that already has sessions.
      final localSessions = _storage.getTotalSessions();
      if (localSessions > 0) {
        debugPrint('☁️ Firestore: Local data exists ($localSessions sessions), skipping restore');
        return false;
      }

      bool restored = false;

      // ── Restore Stats ─────────────────────────────────────────
      final stats = data['stats'] as Map<String, dynamic>?;
      if (stats != null) {
        final streak = stats['streak'] as int? ?? 0;
        final totalSessions = stats['totalSessions'] as int? ?? 0;
        final totalHours = (stats['totalHours'] as num?)?.toDouble() ?? 0.0;
        final bricks = stats['bricks'] as int? ?? 0;

        final statsBox = Hive.box('stats');
        if (streak > 0) await statsBox.put('streak', streak);
        if (totalSessions > 0) await statsBox.put('totalSessions', totalSessions);
        // Convert hours back to minutes for storage
        if (totalHours > 0) await statsBox.put('totalMinutes', (totalHours * 60).round());
        if (bricks > 0) await _storage.addBricks(bricks);

        debugPrint('☁️ Firestore: Stats restored — streak=$streak, sessions=$totalSessions, hours=$totalHours');
        restored = true;
      }

      // ── Restore Sessions ──────────────────────────────────────
      final rawSessions = data['sessions'] as List<dynamic>?;
      if (rawSessions != null && rawSessions.isNotEmpty) {
        final sessionsBox = Hive.box('sessions');
        for (final raw in rawSessions) {
          try {
            final map = Map<String, dynamic>.from(raw as Map);
            // Firestore stores startTime as ISO string; fromMap expects milliseconds int
            if (map['startTime'] is String) {
              map['startTime'] = DateTime.parse(map['startTime'] as String).millisecondsSinceEpoch;
            }
            // Ensure required fields have sensible defaults
            map['id'] ??= DateTime.now().microsecondsSinceEpoch.toString();
            map['completed'] ??= false;
            map['durationMinutes'] ??= 0;
            map['routeName'] ??= '';
            final session = JourneySession.fromMap(map);
            await sessionsBox.add(session.toMap());
          } catch (e) {
            debugPrint('⚠️ Skipped malformed session during restore: $e');
          }
        }
        debugPrint('☁️ Firestore: ${rawSessions.length} sessions restored');
        restored = true;
      }

      if (restored) {
        debugPrint('☁️ Firestore: Full restore complete ✅');
      }
      return restored;
    } catch (e) {
      debugPrint('🔴 Firestore restore error: $e');
      return false;
    }
  }
}
