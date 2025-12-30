// lib/features/authentication/screens/splash_screen.dart

import 'dart:async';
import 'package:eco_quest/features/authentication/screens/login_screen.dart';
import 'package:eco_quest/features/main/screens/main_screen.dart';
import 'package:eco_quest/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        children: [
          // Awan Atas
          Positioned(
            top: 0,
            left: 0,
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/images/clouds_top.png',
                width: screenWidth * 1,
                color: AppColors.cloudBaseColor,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Awan Bawah
          Positioned(
            bottom: 0,
            right: 0,
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/images/clouds_bottom.png',
                width: screenWidth * 1,
                color: AppColors.cloudBaseColor,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Logo Tengah
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: screenWidth * 0.8,
            ),
          ),

          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryButton),
            ),
          ),
        ],
      ),
    );
  }
}
