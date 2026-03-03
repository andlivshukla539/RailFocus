import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool isLocalGuest = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null || isLocalGuest;
  bool get isAnonymous => (currentUser?.isAnonymous ?? false) || isLocalGuest;

  // ─── Email & Password ────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.isNotEmpty) {
        await cred.user?.updateDisplayName(displayName.trim());
        await cred.user?.reload();
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }

  // ─── Google ───────────────────────────────────────────────────────────────

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();
      // authentication is a synchronous getter in google_sign_in ^7.0
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      // User cancelled or sign-in was dismissed — not a hard error
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthException(
        code: 'google-failed',
        message: 'Google sign-in failed: ${e.description}',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (_) {
      throw const AuthException(
        code: 'google-failed',
        message: 'Google sign-in failed. Please try again.',
      );
    }
  }

  // ─── Anonymous / Guest ────────────────────────────────────────────────────

  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      // Any Firebase failure → fall back to offline local guest mode
      debugPrint('🎫 Anonymous auth failed ($e), using local guest mode');
      isLocalGuest = true;
      return null;
    }
  }

  /// Upgrades a guest account → full email account.
  /// All Hive data (stats, sessions, achievements) is preserved.
  Future<UserCredential> upgradeGuestWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final user = currentUser;
      if (user == null || !user.isAnonymous) {
        throw const AuthException(
          code: 'not-anonymous',
          message: 'No guest account to upgrade.',
        );
      }
      final cred = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      final result = await user.linkWithCredential(cred);
      if (displayName != null && displayName.isNotEmpty) {
        await result.user?.updateDisplayName(displayName.trim());
      }
      return result;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      isLocalGuest = false;
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      debugPrint('signOut non-fatal: $e');
    }
  }

  Future<void> updateDisplayName(String name) async {
    await currentUser?.updateDisplayName(name.trim());
    await currentUser?.reload();
  }

  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class AuthException implements Exception {
  final String code;
  final String message;
  const AuthException({required this.code, required this.message});

  factory AuthException.fromFirebase(FirebaseAuthException e) =>
      AuthException(code: e.code, message: '${_msg(e.code)} \n[Code: ${e.code}]');

  static String _msg(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'requires-recent-login':
        return 'Please sign in again to continue.';
      case 'credential-already-in-use':
        return 'This account is already linked.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
