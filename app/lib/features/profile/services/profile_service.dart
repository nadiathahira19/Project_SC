// lib/features/profile/services/profile_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<DocumentSnapshot> getUserData() async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception("User tidak login.");
    return _firestore.collection('users').doc(user.uid).get();
  }

  Future<String> uploadProfilePicture(File image) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

    final cloudinary = CloudinaryPublic(cloudName, uploadPreset);

    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        image.path,
        resourceType: CloudinaryResourceType.Image,
      ),
    );

    return response.secureUrl;
  }

  Future<void> updateUserProfile({
    required String fullName,
    required String address,
    required String username,
    String? newPhotoUrl,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception("User tidak login.");

    final dataToUpdate = {
      'fullName': fullName,
      'address': address,
      'username': username,
      if (newPhotoUrl != null) 'photoUrl': newPhotoUrl,
    };
    await _firestore.collection('users').doc(user.uid).update(dataToUpdate);
  }

  Future<void> updateUserAccount({required String phone}) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception("User tidak login.");
    await _firestore.collection('users').doc(user.uid).update({'phone': phone});
  }

  Future<void> removeProfilePicture() async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception("User tidak login.");

    final String defaultAvatarUrl = dotenv.env['DEFAULT_AVATAR_URL'] ?? '';

    // Update field photoUrl di Firestore kembali ke URL default
    await _firestore.collection('users').doc(user.uid).update({
      'photoUrl': defaultAvatarUrl,
    });
  }

  Future<void> updateUserPassword(String newPassword) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception("User tidak login.");

    // Cek apakah password baru tidak kosong
    if (newPassword.isNotEmpty && newPassword != '********') {
      await user.updatePassword(newPassword);
    }
  }
}
