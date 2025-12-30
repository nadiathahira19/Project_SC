// lib/main.dart

import 'package:eco_quest/features/authentication/screens/splash_screen.dart';
import 'package:eco_quest/utils/app_colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoQuest',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        fontFamily: 'Mulish',
        scaffoldBackgroundColor: AppColors.primaryBackground,
        primaryColor: AppColors.primaryButton,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryButton),
        useMaterial3: true,
      ),

      home: const SplashScreen(),
    );
  }
}
