// lib/features/authentication/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _defaultAvatarUrl => dotenv.env['DEFAULT_AVATAR_URL'] ?? '';

  Future<User?> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    final UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final User? user = result.user;

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': fullName,
        'displayName': fullName,
        'email': email,
        'points': 0,
        'photoUrl': _defaultAvatarUrl,
        'createdAt': Timestamp.now(),
        'streakCount': 0,
        'lastStreakTimestamp': null,
        'status': 'active',
        'role': 'user',
        'scanBurstCount': 0,
        'lastBurstStartTime': null,
      });
    }
    return user;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    final UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User? user = result.user;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data['status'] == 'banned') {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'user-banned',
            message: 'Akun Anda telah dibekukan oleh Admin.',
          );
        }
      }
    }
    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (data['status'] == 'banned') {
            await _auth.signOut();
            await GoogleSignIn().signOut();
            throw FirebaseAuthException(
              code: 'user-banned',
              message: 'Akun dibekukan Admin.',
            );
          }
        }

        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'fullName': user.displayName ?? 'User Google',
            'displayName': user.displayName ?? 'User Google',
            'email': user.email,
            'points': 0,
            'photoUrl': user.photoURL ?? _defaultAvatarUrl,
            'createdAt': Timestamp.now(),
            'streakCount': 0,
            'lastStreakTimestamp': null,
            'status': 'active',
            'role': 'user',
            'scanBurstCount': 0,
            'lastBurstStartTime': null,
          });
        }
      }

      return userCredential;
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'user-banned') {
        rethrow;
      }
      print("Error saat login dengan Google: $e");
      return null;
    }
  }

  Future<String> updateUserPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null || user.email == null) {
      return "Gagal: User tidak ditemukan.";
    }

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      return "sukses";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return "Gagal: Password lama yang Anda masukkan salah.";
      } else if (e.code == 'weak-password') {
        return "Gagal: Password baru terlalu lemah (minimal 6 karakter).";
      }
      return "Gagal: Terjadi kesalahan. ${e.message}";
    }
  }
}
