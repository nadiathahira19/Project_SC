// lib/features/home/services/home_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<DocumentSnapshot> getCurrentUserData() {
    final User? user = _auth.currentUser;
    if (user != null) {
      return _firestore.collection('users').doc(user.uid).snapshots();
    }
    return const Stream.empty();
  }

  Stream<QuerySnapshot> getLeaderboardUsers() {
    return _firestore
        .collection('users')
        .orderBy('points', descending: true)
        .limit(5)
        .snapshots();
  }
}
