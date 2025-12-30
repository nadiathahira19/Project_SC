// lib/features/authentication/screens/register_screen.dart

import 'package:eco_quest/features/authentication/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eco_quest/utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    const Color backgroundColor = AppColors.primaryBackground;
    const Color buttonColor = AppColors.primaryButton;
    const Color textFieldBackgroundColor = AppColors.textFieldBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
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

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: screenWidth * 0.8,
                    ),
                    const SizedBox(height: 30),

                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Nama',
                        filled: true,
                        fillColor: textFieldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        filled: true,
                        fillColor: textFieldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: _isPasswordObscure,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor: AppColors.textFieldBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordObscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _isPasswordObscure = !_isPasswordObscure,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: _isConfirmPasswordObscure,
                      decoration: InputDecoration(
                        hintText: 'Konfirmasi Password',
                        filled: true,
                        fillColor: AppColors.textFieldBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordObscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _isConfirmPasswordObscure =
                                !_isConfirmPasswordObscure,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                final scaffoldMessenger = ScaffoldMessenger.of(
                                  context,
                                );

                                setState(() => _isLoading = true);

                                final name = nameController.text.trim();
                                final email = emailController.text.trim();
                                final password = passwordController.text.trim();
                                final confirmPassword =
                                    confirmPasswordController.text.trim();

                                if (name.isEmpty ||
                                    email.isEmpty ||
                                    password.isEmpty) {
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Semua field wajib diisi!'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  setState(() => _isLoading = false);
                                  return;
                                }
                                if (password != confirmPassword) {
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password dan konfirmasi tidak cocok!',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  setState(() => _isLoading = false);
                                  return;
                                }

                                try {
                                  final authService = AuthService();
                                  final user = await authService
                                      .signUpWithEmail(email, password, name);
                                  if (user != null) {
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Pendaftaran berhasil! Silakan login.',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    navigator.pop();
                                  }
                                } on FirebaseAuthException catch (e) {
                                  String message = 'Terjadi kesalahan.';
                                  if (e.code == 'weak-password') {
                                    message =
                                        'Password terlalu lemah, minimal 6 karakter.';
                                  } else if (e.code == 'email-already-in-use') {
                                    message = 'Email ini sudah terdaftar.';
                                  } else if (e.code == 'invalid-email') {
                                    message = 'Format email tidak valid.';
                                  }
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  if (mounted)
                                    setState(() => _isLoading = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryButton,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Daftar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    GestureDetector(
                      onTap: () {
                        // Kembali ke halaman login
                        Navigator.of(context).pop();
                      },
                      child: Text.rich(
                        TextSpan(
                          text: 'Sudah punya akun? ',
                          style: const TextStyle(color: Colors.black54),
                          children: [
                            TextSpan(
                              text: 'Masuk Disini',
                              style: TextStyle(
                                color: buttonColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
