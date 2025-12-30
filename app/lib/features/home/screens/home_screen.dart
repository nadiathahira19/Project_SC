// lib/features/home/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_quest/features/notifications/screens/notifications_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eco_quest/utils/app_colors.dart';
import 'package:eco_quest/features/home/services/home_service.dart';
import 'package:eco_quest/features/authentication/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeService _homeService = HomeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _homeService.getCurrentUserData(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FirebaseAuth.instance.signOut();
              });
              return const Center(
                child: Text('Data user tidak ditemukan, silahkan login ulang.'),
              );
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;

            if (userData['status'] == 'banned') {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Akun Anda telah dibekukan oleh Admin."),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 5),
                    ),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              });
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              );
            }

            final String userName =
                (userData['username'] != null &&
                    userData['username'].isNotEmpty)
                ? userData['username']
                : userData['displayName'] ?? userData['fullName'] ?? 'User';

            final int userPoints = userData['points'] ?? 0;

            String rawPhotoUrl =
                userData['photoUrl'] ?? 'https://i.pravatar.cc/150?u=default';
            if (rawPhotoUrl.startsWith('http://')) {
              rawPhotoUrl = rawPhotoUrl.replaceFirst('http://', 'https://');
            }
            final String userImageUrl = rawPhotoUrl;

            final int streakCountFromDB = userData['streakCount'] ?? 0;
            final Timestamp? lastTimestamp = userData['lastStreakTimestamp'];

            int displayStreak = 0;

            if (lastTimestamp != null) {
              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);
              final yesterdayStart = DateTime(now.year, now.month, now.day - 1);
              final lastScanDate = lastTimestamp.toDate();

              if (lastScanDate.isAfter(todayStart) ||
                  lastScanDate.isAfter(yesterdayStart)) {
                displayStreak = streakCountFromDB;
              }
            }

            final int scanBurstCount = userData['scanBurstCount'] ?? 0;
            final Timestamp? lastBurstTime = userData['lastBurstStartTime'];

            int staminaLeft = 5 - scanBurstCount;

            if (lastBurstTime != null) {
              final now = DateTime.now();
              final diff = now.difference(lastBurstTime.toDate());

              if (diff.inHours >= 1) {
                staminaLeft = 5;
              }
            }

            if (staminaLeft < 0) staminaLeft = 0;

            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Profile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: NetworkImage(userImageUrl),
                                onBackgroundImageError: (_, __) {},
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Halo, $userName!',
                                      style: const TextStyle(
                                        color: AppColors.primaryText,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text(
                                      'Selamat datang kembali',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          ),
                          icon: const Icon(
                            Icons.notifications_none_outlined,
                            color: AppColors.primaryText,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Points',
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                    Text(
                      '$userPoints Points',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Aclonica',
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bolt,
                                color: Colors.orange.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Energi Scan",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "$staminaLeft/5",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: staminaLeft == 0
                                      ? Colors.red
                                      : Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (index) {
                              bool isActive = index < staminaLeft;
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  height: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: isActive
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Streak Card
                    _buildStreakCard(displayStreak),

                    const SizedBox(height: 24),

                    // Leaderboard Title
                    const Text(
                      'Leaderboard',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Leaderboard List
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _homeService.getLeaderboardUsers(),
                        builder: (context, leaderboardSnapshot) {
                          if (leaderboardSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (!leaderboardSnapshot.hasData ||
                              leaderboardSnapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Jadilah yang pertama!'),
                              ),
                            );
                          }

                          final leaderboardUsers =
                              leaderboardSnapshot.data!.docs;

                          return Column(
                            children: List.generate(leaderboardUsers.length, (
                              index,
                            ) {
                              final doc = leaderboardUsers[index];
                              final leaderData =
                                  doc.data() as Map<String, dynamic>;
                              final String leaderName =
                                  (leaderData['username'] != null &&
                                      leaderData['username'].isNotEmpty)
                                  ? leaderData['username']
                                  : leaderData['displayName'] ??
                                        leaderData['fullName'] ??
                                        'User Tanpa Nama';
                              final rank = index + 1;

                              String leaderPhotoUrl =
                                  leaderData['photoUrl'] ??
                                  'https://i.pravatar.cc/150?u=${doc.id}';
                              if (leaderPhotoUrl.startsWith('http://')) {
                                leaderPhotoUrl = leaderPhotoUrl.replaceFirst(
                                  'http://',
                                  'https://',
                                );
                              }

                              return _buildLeaderboardTile(
                                leaderName,
                                '${leaderData['points'] ?? 0} Pts',
                                rank,
                                leaderPhotoUrl,
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeaderboardTile(
    String name,
    String points,
    int rank,
    String imageUrl,
  ) {
    Widget rankWidget;
    if (rank <= 3) {
      rankWidget = Image.asset('assets/images/trophy_$rank.png', width: 24);
    } else {
      rankWidget = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$rank',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          rankWidget,
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: NetworkImage(imageUrl),
            onBackgroundImageError: (_, __) {},
          ),
        ],
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Text(
        points,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildStreakCard(int streakCount) {
    String title;
    String subtitle;
    String emoji;
    if (streakCount > 0) {
      title = "$streakCount Hari Beruntun!";
      subtitle = "Bagus! Terus scan sampah setiap hari.";
      emoji = "🔥";
    } else {
      title = "Mulai Streak Pertamamu";
      subtitle = "Scan sampah pertamamu hari ini untuk memulai.";
      emoji = "👍";
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD9E0D1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
