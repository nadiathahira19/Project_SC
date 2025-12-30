// lib/features/main/screens/main_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eco_quest/features/home/screens/home_screen.dart';
import 'package:eco_quest/features/rewards/screens/rewards_screen.dart';
import 'package:eco_quest/features/scan/screens/scan_location_list_screen.dart';
import 'package:eco_quest/features/history/screens/history_screen.dart';
import 'package:eco_quest/features/profile/screens/profile_screen.dart';
import 'package:eco_quest/features/scan/services/bin_session_service.dart';
import 'package:eco_quest/features/scan/screens/capture_proof_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    RewardsScreen(),
    ScanLocationListScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      _handleScanButton();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _handleScanButton() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? {};

      int scanBurstCount = data['scanBurstCount'] ?? 0;
      Timestamp? lastBurstTime = data['lastBurstStartTime'];

      if (lastBurstTime != null) {
        final now = DateTime.now();
        final diff = now.difference(lastBurstTime.toDate());
        if (diff.inHours >= 1) {
          scanBurstCount = 0;
        }
      }

      if (scanBurstCount >= 5) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("⚡ Energi habis! Coba lagi dalam 4 jam."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      bool canSkip = await BinSessionService().canSkipQR();

      if (!mounted) return;
      Navigator.pop(context);

      if (canSkip) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📍 Lokasi terverifikasi! Langsung buka kamera."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CaptureProofScreen()),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ScanLocationListScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("Error scan check: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),

      floatingActionButton: FloatingActionButton(
        onPressed: _handleScanButton,
        backgroundColor: const Color(0xFF008269),
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Sisi Kiri
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MaterialButton(
                    minWidth: 40,
                    onPressed: () => _onItemTapped(0),
                    child: Icon(
                      _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                      color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
                    ),
                  ),
                  MaterialButton(
                    minWidth: 40,
                    onPressed: () => _onItemTapped(1),
                    child: Icon(
                      _selectedIndex == 1
                          ? Icons.card_giftcard
                          : Icons.card_giftcard_outlined,
                      color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
                    ),
                  ),
                ],
              ),
              // Sisi Kanan
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MaterialButton(
                    minWidth: 40,
                    onPressed: () => _onItemTapped(3),
                    child: Icon(
                      _selectedIndex == 3
                          ? Icons.history
                          : Icons.history_outlined,
                      color: _selectedIndex == 3 ? Colors.blue : Colors.grey,
                    ),
                  ),
                  MaterialButton(
                    minWidth: 40,
                    onPressed: () => _onItemTapped(4),
                    child: Icon(
                      _selectedIndex == 4 ? Icons.person : Icons.person_outline,
                      color: _selectedIndex == 4 ? Colors.blue : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
