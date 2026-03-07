// lib/services/cabin_service.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — CO-WORKING CABIN SERVICE
//  Manages real-time "Passenger Cabins" — shared focus rooms
//  where users can focus alongside others.
//
//  Data model in Firestore:
//    cabins/{cabinId} = {
//      name: String,
//      isPublic: bool,
//      inviteCode: String?,
//      hostUid: String,
//      createdAt: Timestamp,
//      passengers: [ { uid, name, avatar, joinedAt, isActive } ]
//    }
// ═══════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CabinPassenger {
  final String uid;
  final String name;
  final String avatar;
  final bool isActive;

  const CabinPassenger({
    required this.uid,
    required this.name,
    required this.avatar,
    required this.isActive,
  });

  factory CabinPassenger.fromMap(Map<String, dynamic> m) => CabinPassenger(
        uid: m['uid'] as String? ?? '',
        name: m['name'] as String? ?? 'Traveller',
        avatar: m['avatar'] as String? ?? '🚂',
        isActive: m['isActive'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'avatar': avatar,
        'isActive': isActive,
        'joinedAt': FieldValue.serverTimestamp(),
      };
}

class CabinModel {
  final String id;
  final String name;
  final bool isPublic;
  final String hostUid;
  final String? inviteCode;
  final List<CabinPassenger> passengers;

  const CabinModel({
    required this.id,
    required this.name,
    required this.isPublic,
    required this.hostUid,
    this.inviteCode,
    required this.passengers,
  });

  factory CabinModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawPassengers = data['passengers'] as List<dynamic>? ?? [];
    return CabinModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Cabin',
      isPublic: data['isPublic'] as bool? ?? true,
      hostUid: data['hostUid'] as String? ?? '',
      inviteCode: data['inviteCode'] as String?,
      passengers: rawPassengers
          .whereType<Map<String, dynamic>>()
          .map(CabinPassenger.fromMap)
          .toList(),
    );
  }

  int get activeCount => passengers.where((p) => p.isActive).length;
}

class CabinService {
  CabinService._();
  static final instance = CabinService._();

  final _db = FirebaseFirestore.instance;
  String? _currentCabinId;

  String? get currentCabinId => _currentCabinId;

  // ── Get current user info ──────────────────────────────────
  Future<Map<String, String>> _getUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final String? passengerName = prefs.getString('passenger_name');
    final String name = (passengerName != null && passengerName.trim().isNotEmpty && passengerName != 'Traveller')
        ? passengerName.trim()
        : (user?.displayName?.split(' ').first ?? 'Traveller');
    const avatars = ['🚂', '🎩', '🌙', '⭐', '🌿', '💎', '🏔️', '🌊'];
    final avatar = avatars[name.hashCode.abs() % avatars.length];
    return {'uid': user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}', 'name': name, 'avatar': avatar};
  }

  // ── List public cabins ─────────────────────────────────────
  Stream<List<CabinModel>> publicCabinsStream() {
    return _db
        .collection('cabins')
        .where('isPublic', isEqualTo: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map(CabinModel.fromDoc).toList());
  }

  // ── Create a new cabin ─────────────────────────────────────
  Future<CabinModel?> createCabin({
    required String name,
    required bool isPublic,
  }) async {
    try {
      final info = await _getUserInfo();
      final inviteCode = isPublic ? null : _generateCode();

      final passenger = CabinPassenger(
        uid: info['uid']!,
        name: info['name']!,
        avatar: info['avatar']!,
        isActive: true,
      );

      final ref = await _db.collection('cabins').add({
        'name': name,
        'isPublic': isPublic,
        'hostUid': info['uid'],
        'inviteCode': inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
        'passengers': [passenger.toMap()],
      });

      _currentCabinId = ref.id;
      return CabinModel(
        id: ref.id,
        name: name,
        isPublic: isPublic,
        hostUid: info['uid']!,
        inviteCode: inviteCode,
        passengers: [passenger],
      );
    } catch (e) {
      debugPrint('🔴 Cabin create error: $e');
      return null;
    }
  }

  // ── Join a cabin ───────────────────────────────────────────
  Future<bool> joinCabin(String cabinId) async {
    try {
      final info = await _getUserInfo();
      final passenger = CabinPassenger(
        uid: info['uid']!,
        name: info['name']!,
        avatar: info['avatar']!,
        isActive: true,
      );

      // Remove from any other cabin first
      await leaveCabin();

      await _db.collection('cabins').doc(cabinId).update({
        'passengers': FieldValue.arrayUnion([passenger.toMap()]),
      });

      _currentCabinId = cabinId;
      return true;
    } catch (e) {
      debugPrint('🔴 Cabin join error: $e');
      return false;
    }
  }

  // ── Join by invite code ────────────────────────────────────
  Future<CabinModel?> joinByCode(String code) async {
    try {
      final snap = await _db
          .collection('cabins')
          .where('inviteCode', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final cabin = CabinModel.fromDoc(snap.docs.first);
      await joinCabin(cabin.id);
      return cabin;
    } catch (e) {
      debugPrint('🔴 Cabin code join error: $e');
      return null;
    }
  }

  // ── Leave the current cabin ────────────────────────────────
  Future<void> leaveCabin() async {
    if (_currentCabinId == null) return;
    try {
      final info = await _getUserInfo();
      final uid = info['uid']!;

      final doc = await _db.collection('cabins').doc(_currentCabinId!).get();
      if (!doc.exists) { _currentCabinId = null; return; }

      final cabin = CabinModel.fromDoc(doc);
      final updatedPassengers = cabin.passengers
          .where((p) => p.uid != uid)
          .map((p) => p.toMap())
          .toList();

      if (updatedPassengers.isEmpty) {
        // Last one out — delete the cabin
        await _db.collection('cabins').doc(_currentCabinId!).delete();
      } else {
        await _db.collection('cabins').doc(_currentCabinId!).update({
          'passengers': updatedPassengers,
        });
      }
    } catch (e) {
      debugPrint('🔴 Cabin leave error: $e');
    } finally {
      _currentCabinId = null;
    }
  }

  // ── Mark self as active/inactive in cabin ──────────────────
  Future<void> setActive(bool isActive) async {
    if (_currentCabinId == null) return;
    try {
      final info = await _getUserInfo();
      final doc = await _db.collection('cabins').doc(_currentCabinId!).get();
      if (!doc.exists) return;
      final cabin = CabinModel.fromDoc(doc);
      final updated = cabin.passengers.map((p) {
        if (p.uid == info['uid']) {
          return CabinPassenger(uid: p.uid, name: p.name, avatar: p.avatar, isActive: isActive).toMap();
        }
        return p.toMap();
      }).toList();
      await _db.collection('cabins').doc(_currentCabinId!).update({'passengers': updated});
    } catch (e) { /* silent */ }
  }

  // ── Stream current cabin ───────────────────────────────────
  Stream<CabinModel?> currentCabinStream() {
    if (_currentCabinId == null) return Stream.value(null);
    return _db
        .collection('cabins')
        .doc(_currentCabinId!)
        .snapshots()
        .map((doc) => doc.exists ? CabinModel.fromDoc(doc) : null);
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
