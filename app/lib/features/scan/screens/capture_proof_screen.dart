// lib\features\scan\screens\capture_proof_screen.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'confirm_proof_screen.dart';

class CaptureProofScreen extends StatefulWidget {
  const CaptureProofScreen({super.key});

  @override
  State<CaptureProofScreen> createState() => _CaptureProofScreenState();
}

class _CaptureProofScreenState extends State<CaptureProofScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Error init kamera: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _ambilGambar() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      setState(() => _isTakingPicture = true);
      final image = await _controller!.takePicture();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConfirmProofScreen(image: image)),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal mengambil gambar')));
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isCameraInitialized && _controller != null
          ? LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.previewSize!.height,
                        height: _controller!.value.previewSize!.width,
                        child: CameraPreview(_controller!),
                      ),
                    ),

                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _MinimalViewfinderPainter(),
                    ),

                    SafeArea(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          const Text(
                            'Pindai Sampah',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _isTakingPicture ? null : _ambilGambar,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _isTakingPicture ? 70 : 80,
                              height: _isTakingPicture ? 70 : 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.9),
                                  width: 4,
                                ),
                                color: _isTakingPicture
                                    ? Colors.grey[300]
                                    : Colors.white,
                              ),
                              child: _isTakingPicture
                                  ? const Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.black,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      margin: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ],
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _MinimalViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double boxWidth = size.width * 0.8;
    final double boxHeight = size.height * 0.45;

    final Rect boxRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: boxWidth,
      height: boxHeight,
    );

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLen = 40;

    void drawCorner(
      double x1,
      double y1,
      double x2,
      double y2,
      double x3,
      double y3,
    ) {
      final path = Path()
        ..moveTo(x1, y1)
        ..lineTo(x2, y2)
        ..lineTo(x3, y3);
      canvas.drawPath(path, paint);
    }

    // Kiri atas
    drawCorner(
      boxRect.left,
      boxRect.top + cornerLen,
      boxRect.left,
      boxRect.top,
      boxRect.left + cornerLen,
      boxRect.top,
    );
    // Kanan atas
    drawCorner(
      boxRect.right - cornerLen,
      boxRect.top,
      boxRect.right,
      boxRect.top,
      boxRect.right,
      boxRect.top + cornerLen,
    );
    // Kiri bawah
    drawCorner(
      boxRect.left,
      boxRect.bottom - cornerLen,
      boxRect.left,
      boxRect.bottom,
      boxRect.left + cornerLen,
      boxRect.bottom,
    );
    // Kanan bawah
    drawCorner(
      boxRect.right - cornerLen,
      boxRect.bottom,
      boxRect.right,
      boxRect.bottom,
      boxRect.right,
      boxRect.bottom - cornerLen,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
