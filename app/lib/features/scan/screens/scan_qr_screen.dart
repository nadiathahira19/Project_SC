// lib/features/scan/screens/scan_qr_screen.dart

import 'package:flutter/material.dart';
import 'package:eco_quest/utils/app_colors.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'capture_proof_screen.dart';
import 'package:eco_quest/features/scan/services/bin_session_service.dart';

class ScanQrScreen extends StatefulWidget {
  final String selectedBinId;
  final String selectedBinName;
  final double selectedBinLat;
  final double selectedBinLon;

  const ScanQrScreen({
    super.key,
    required this.selectedBinId,
    required this.selectedBinName,
    required this.selectedBinLat,
    required this.selectedBinLon,
  });
  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen>
    with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanLocked = false;
  bool _isVerifying = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!controller.value.isInitialized) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        controller.stop();
        break;
      case AppLifecycleState.hidden:
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verifikasi Gagal'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Coba Lagi'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) setState(() => _isScanLocked = false);
    });
  }

  Future<void> _verifyQrAndLocation(String qrCode) async {
    if (!mounted) return;
    setState(() => _isVerifying = true);

    // Verifikasi QR
    if (qrCode != widget.selectedBinId) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      _showErrorDialog('QR Code anda tidak cocok...');
      return;
    }

    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      double distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        widget.selectedBinLat,
        widget.selectedBinLon,
      );

      if (distance <= 30) {
        BinSessionService().setSession(
          widget.selectedBinId,
          widget.selectedBinLat,
          widget.selectedBinLon,
        );
        // -----------------------------------

        if (!mounted) return;
        setState(() {
          _isVerifying = false;
          _isVerified = true;
        });
        await Future.delayed(const Duration(seconds: 1));
        await controller.stop();

        if (mounted) {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const CaptureProofScreen()),
          );
        }

        if (mounted) {
          setState(() => _isScanLocked = false);
          if (controller.value.isInitialized) {
            await controller.start();
          }
        }
      } else {
        if (!mounted) return;
        setState(() => _isVerifying = false);
        _showErrorDialog(
          'Anda terlalu jauh! Jarak Anda sekitar ${distance.toStringAsFixed(0)} meter.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      _showErrorDialog('Gagal mendapatkan lokasi GPS...');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanWindowSize = screenSize.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isScanLocked) return;
              final String? qrCode = capture.barcodes.first.rawValue;
              if (qrCode != null) {
                setState(() => _isScanLocked = true);
                _verifyQrAndLocation(qrCode);
              }
            },
          ),

          ClipPath(
            clipper: _InvertedRoundedRectangleClipper(
              scanWindowSize: scanWindowSize,
            ),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),

          Positioned(
            top: 16,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pindai kode QR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Arahkan kamera pada kode QR untuk ${widget.selectedBinName}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          Center(
            child: SizedBox(
              width: scanWindowSize,
              height: scanWindowSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: _QrScannerBorderPainter(),
                  ),
                  if (_isVerifying)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentColor,
                      ),
                    )
                  else if (_isVerified)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvertedRoundedRectangleClipper extends CustomClipper<Path> {
  final double scanWindowSize;

  _InvertedRoundedRectangleClipper({required this.scanWindowSize});

  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: size.center(Offset.zero),
            width: scanWindowSize,
            height: scanWindowSize,
          ),
          const Radius.circular(20),
        ),
      )
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _QrScannerBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.accentColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerSize = 40;

    // Top-left corner
    canvas.drawLine(const Offset(0, cornerSize), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(cornerSize, 0), paint);

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - cornerSize, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerSize),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(0, size.height - cornerSize),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(const Offset(0, 0), Offset(cornerSize, 0), paint);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerSize, size.height),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - cornerSize, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerSize),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
