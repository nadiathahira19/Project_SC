// lib/features/scan/screens/confirm_proof_screen.dart

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:eco_quest/features/scan/services/scan_service.dart';
import 'package:eco_quest/utils/app_colors.dart';

class ConfirmProofScreen extends StatefulWidget {
  final XFile image;

  const ConfirmProofScreen({super.key, required this.image});

  @override
  State<ConfirmProofScreen> createState() => _ConfirmProofScreenState();
}

class _ConfirmProofScreenState extends State<ConfirmProofScreen> {
  bool _isLoading = false;

  Future<void> _handleKirimBukti() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final scanService = ScanService();
      final String result = await scanService.processProofImage(widget.image);

      if (result.startsWith("sukses:")) {
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Berhasil!"),
            content: Text(result.substring(7)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text("Selesai"),
              ),
            ],
          ),
        );
      } else {
        throw Exception(result);
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = "Terjadi kesalahan.";
      String errorDetails = e.toString().replaceAll("Exception: ", "");

      if (errorDetails.contains("TimeoutException") ||
          errorDetails.contains("Waktu verifikasi habis")) {
        errorMessage = "Waktu verifikasi habis.";
        errorDetails = "Server mungkin sedang sibuk. Silakan coba lagi.";
      } else if (errorDetails.startsWith("Gagal:")) {
        errorMessage = errorDetails;
        errorDetails = "Pastikan gambar jelas dan coba lagi.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage, style: TextStyle(fontWeight: FontWeight.bold)),
              if (errorMessage != errorDetails) Text(errorDetails),
            ],
          ),
        ),
      );

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Konfirmasi Bukti',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.file(File(widget.image.path), fit: BoxFit.contain),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isLoading ? _buildLoadingWidget() : _buildButtonWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Mengupload dan memverifikasi...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Ulangi'),
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Tombol Kirim Bukti
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Kirim Bukti'),
            onPressed: _handleKirimBukti,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryButton,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
