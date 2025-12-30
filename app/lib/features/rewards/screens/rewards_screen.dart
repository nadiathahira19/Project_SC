// lib/features/rewards/screens/rewards_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_quest/utils/app_colors.dart';
import 'package:eco_quest/features/rewards/services/reward_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final RewardService _rewardService = RewardService();

  void _claimReward(String rewardId, String rewardTitle, int points) {
    final mainContext = context;
    showDialog(
      context: mainContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Penukaran'),
          content: Text(
            'Kamu akan menukarkan $points poin untuk mendapatkan "$rewardTitle". Lanjutkan?',
          ),
          actions: <Widget>[
            // Tombol Batal
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            // Tombol Lanjutkan
            TextButton(
              child: const Text(
                'Lanjutkan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                final scaffoldMessenger = ScaffoldMessenger.of(mainContext);
                final navigator = Navigator.of(mainContext);

                showDialog(
                  context: mainContext,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final result = await _rewardService.claimReward(
                  rewardId: rewardId,
                  rewardTitle: rewardTitle,
                  pointsNeeded: points,
                );

                navigator.pop();
                if (!mounted) return;

                if (result == "sukses") {
                  showDialog(
                    context: mainContext,
                    builder: (context) => AlertDialog(
                      title: const Text('Berhasil!'),
                      content: Text('Kamu berhasil mengklaim $rewardTitle.'),
                      actions: [
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () => navigator.pop(),
                        ),
                      ],
                    ),
                  );
                } else {
                  final errorMessage = result.replaceFirst('Exception: ', '');
                  showDialog(
                    context: mainContext,
                    builder: (context) => AlertDialog(
                      title: const Text('Gagal'),
                      content: Text(errorMessage),
                      actions: [
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () => navigator.pop(),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final String userName =
                (userData['username'] != null &&
                    userData['username'].isNotEmpty)
                ? userData['username']
                : userData['displayName'] ?? userData['fullName'] ?? 'User';
            final int userPoints = userData['points'] ?? 0;
            final String userImageUrl =
                userData['photoUrl'] ?? 'https://i.pravatar.cc/150?u=default';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage(userImageUrl),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Halo, $userName!',
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1E6DC),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total points didapatkan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$userPoints Points',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: -20,
                            child: Image.asset(
                              'assets/images/gift.png',
                              height: 100,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Hadiah',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _rewardService.getRewardsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('Saat ini tidak ada hadiah tersedia.'),
                        );
                      }
                      final rewards = snapshot.data!.docs;
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: rewards.length,
                        itemBuilder: (context, index) {
                          final rewardData =
                              rewards[index].data() as Map<String, dynamic>;
                          final rewardId = rewards[index].id;

                          final int rewardPoints = rewardData['points'] ?? 0;
                          final String rewardTitle =
                              rewardData['title'] ?? 'Tanpa Judul';

                          final bool canClaim = userPoints >= rewardPoints;

                          return _buildRewardItem(
                            title: rewardTitle,
                            points: rewardPoints,
                            canClaim: canClaim,
                            onTap: () {
                              _claimReward(rewardId, rewardTitle, rewardPoints);
                            },
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRewardItem({
    required String title,
    required int points,
    required bool canClaim,
    required VoidCallback onTap,
  }) {
    final bool isButtonEnabled = canClaim;
    final Color buttonColor = isButtonEnabled
        ? AppColors.primaryButton
        : Colors.grey;
    final VoidCallback? onPressedAction = isButtonEnabled ? onTap : null;
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isButtonEnabled ? Colors.white : Colors.white.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              Icons.card_giftcard,
              size: 40,
              color: isButtonEnabled ? AppColors.primaryText : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$points Points',
                    style: TextStyle(
                      color: isButtonEnabled ? Colors.black54 : Colors.red,
                      fontWeight: isButtonEnabled ? null : FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onPressedAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: isButtonEnabled ? 2 : 0,
              ),
              child: const Text('Tukar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
