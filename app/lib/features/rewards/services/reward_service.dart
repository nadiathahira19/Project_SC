// lib/features/rewards/services/reward_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getRewardsStream() {
    return _firestore
        .collection('rewards')
        .where('stock', isGreaterThan: 0)
        .orderBy('points', descending: false)
        .snapshots();
  }

  Future<String> claimReward({
    required String rewardId,
    required String rewardTitle,
    required int pointsNeeded,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return "Gagal: Kamu harus login untuk klaim hadiah.";
    }

    final DocumentReference userRef = _firestore
        .collection('users')
        .doc(user.uid);
    final DocumentReference rewardRef = _firestore
        .collection('rewards')
        .doc(rewardId);

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        DocumentSnapshot rewardSnapshot = await transaction.get(rewardRef);

        if (!userSnapshot.exists || !rewardSnapshot.exists) {
          throw Exception("User atau Reward tidak ditemukan.");
        }

        int currentPoints = userSnapshot.get('points');
        int currentStock = rewardSnapshot.get('stock');

        if (currentStock <= 0) {
          throw Exception("Maaf, stok hadiah sudah habis.");
        }
        if (currentPoints < pointsNeeded) {
          throw Exception("Maaf, poin kamu tidak cukup.");
        }

        transaction.update(userRef, {'points': currentPoints - pointsNeeded});
        transaction.update(rewardRef, {'stock': currentStock - 1});

        final DocumentReference historyRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .doc();
        transaction.set(historyRef, {
          'title': 'Klaim $rewardTitle',
          'points': pointsNeeded,
          'type': 'spend',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      return "sukses";
    } catch (e) {
      return e.toString();
    }
  }
}
