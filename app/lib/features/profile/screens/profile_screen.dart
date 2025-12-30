// lib/features/profile/screens/profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:eco_quest/utils/app_colors.dart';
import 'package:eco_quest/features/authentication/screens/login_screen.dart';
import 'package:eco_quest/features/authentication/services/auth_service.dart';
import 'package:eco_quest/features/profile/screens/account_settings_screen.dart';
import 'package:eco_quest/features/profile/screens/profile_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: currentUser == null
          ? const Center(child: Text('User tidak ditemukan.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data?.data() == null) {
                  return const Center(child: Text('Gagal memuat data profil.'));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final String fullName =
                    userData['fullName'] ?? 'Nama Tidak Ditemukan';
                final String email =
                    userData['email'] ?? 'Email Tidak Ditemukan';
                final String photoUrl =
                    userData['photoUrl'] ??
                    'https://i.pravatar.cc/300?u=default';

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(photoUrl),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Image.asset(
                            'assets/images/gift_box.png',
                            width: 30,
                            height: 30,
                          ),
                          title: const Text(
                            'Undang teman dan dapatkan 1.500 Points',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _showInviteFriendSheet(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildProfileMenuItem(
                              icon: Icons.person_outline,
                              title: 'Pengaturan Akun',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AccountSettingsScreen(),
                                ),
                              ),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _buildProfileMenuItem(
                              icon: Icons.settings_outlined,
                              title: 'Pengaturan Profil',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ProfileSettingsScreen(),
                                ),
                              ),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _buildProfileMenuItem(
                              icon: Icons.help_outline,
                              title: 'Pusat Bantuan',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildProfileMenuItem(
                          icon: Icons.logout,
                          title: 'Keluar',
                          textColor: Colors.red,
                          onTap: () => _showLogoutDialog(context),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = AppColors.primaryText,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _showInviteFriendSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _InviteFriendContent(),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await AuthService().signOut();

              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InviteFriendContent extends StatefulWidget {
  const _InviteFriendContent();

  @override
  State<_InviteFriendContent> createState() => _InviteFriendContentState();
}

class _InviteFriendContentState extends State<_InviteFriendContent> {
  bool _isCopied = false;

  void _copyLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    setState(() {
      _isCopied = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const String referralLink = 'ecoguest.com/reff/ragil12345';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Undang teman dan dapatkan bonus 1.500 Points',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dapatkan 1.500 points untuk setiap teman yang diundang untuk bergabung ke EcoQuest!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.textFieldBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _isCopied
                  ? const Text(
                      'Link berhasil disalin!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : const Text(
                      referralLink,
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Bagikan
          ElevatedButton(
            onPressed: () => Share.share(
              'Ayo gabung EcoQuest dan dapatkan poin! Gunakan link referral saya: $referralLink',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Bagikan Link',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: _isCopied ? null : () => _copyLink(referralLink),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Salin link',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
