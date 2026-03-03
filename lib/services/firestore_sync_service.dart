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

  /// Check if cloud data exists and is newer, then restore
  Future<bool> restoreIfNeeded() async {
    try {
      final doc = _userDoc;
      if (doc == null) return false;

      final snapshot = await doc.get();
      if (!snapshot.exists) return false;

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return false;

      // Check if local is empty (fresh install)
      final localSessions = _storage.getTotalSessions();
      if (localSessions > 0) {
        debugPrint('☁️ Firestore: Local data exists, skipping restore');
        return false;
      }

      // Restore stats
      final stats = data['stats'] as Map<String, dynamic>?;
      if (stats != null) {
        final bricks = stats['bricks'] as int? ?? 0;
        if (bricks > 0) {
          await _storage.addBricks(bricks);
        }
        debugPrint('☁️ Firestore: Stats restored');
      }

      debugPrint('☁️ Firestore: Restore complete');
      return true;
    } catch (e) {
      debugPrint('🔴 Firestore restore error: $e');
      return false;
    }
  }
}
