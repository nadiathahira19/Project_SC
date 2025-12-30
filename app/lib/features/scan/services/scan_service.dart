// lib/features/scan/services/scan_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Map<String, dynamic> _parseJson(String responseBody) {
  return jsonDecode(responseBody) as Map<String, dynamic>;
}

class ScanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int MAX_BURST = 5;
  static const int COOLDOWN_HOURS = 1;

  Future<String> processProofImage(XFile image) async {
    final User? user = _auth.currentUser;
    if (user == null) return "Gagal: User tidak login.";

    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userSnapshot = await userDocRef.get();
      final userData = userSnapshot.data() as Map<String, dynamic>? ?? {};

      int currentScanCount = userData['scanBurstCount'] ?? 0;
      Timestamp? lastBurstTime = userData['lastBurstStartTime'];

      final now = DateTime.now();
      bool shouldReset = false;

      if (lastBurstTime == null) {
        shouldReset = true;
      } else {
        final lastTime = lastBurstTime.toDate();
        final difference = now.difference(lastTime);
        if (difference.inHours >= COOLDOWN_HOURS) {
          shouldReset = true;
        }
      }

      if (!shouldReset && currentScanCount >= MAX_BURST) {
        final lastTime = lastBurstTime!.toDate();
        final unlockTime = lastTime.add(const Duration(hours: COOLDOWN_HOURS));
        final remaining = unlockTime.difference(now);

        final jam = remaining.inHours;
        final menit = remaining.inMinutes % 60;

        return "Gagal: Energi habis! Istirahat dulu, kembali dalam $jam jam $menit menit.";
      }
    } catch (e) {
      print("Error cek stamina: $e");
      return "Gagal: Terjadi kesalahan saat cek stamina.";
    }

    String label = 'tidak_dikenali';
    String dataUri;

    try {
      final bytes = await image.readAsBytes();
      String base64Image = base64Encode(bytes);
      dataUri = "data:image/jpeg;base64,$base64Image";
    } catch (e) {
      print("Error membaca file: $e");
      return "Gagal: Error saat membaca gambar.";
    }

    try {
      final String predictUrl =
          "https://0rigin4l-eco-quest.hf.space/gradio_api/call/predict";

      print("Mengirim pekerjaan ke: $predictUrl");
      final predictResponse = await http
          .post(
            Uri.parse(predictUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "data": [dataUri],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (predictResponse.statusCode != 200) {
        print("❌ Gagal submit: ${predictResponse.statusCode}");
        return "Gagal: Server menolak permintaan.";
      }

      final predictResult = await compute(_parseJson, predictResponse.body);

      if (predictResult.containsKey("data")) {
        label = predictResult["data"][0];
      } else if (predictResult.containsKey("event_id")) {
        final String eventId = predictResult["event_id"];
        final String streamUrl = "$predictUrl/$eventId";
        final completer = Completer<String>();

        final timer = Timer(const Duration(seconds: 60), () {
          if (!completer.isCompleted) {
            completer.completeError(
              "Gagal: Waktu verifikasi habis (60 detik).",
            );
          }
        });

        SSEClient.subscribeToSSE(
          method: SSERequestType.GET,
          url: streamUrl,
          header: {"Accept": "text/event-stream", "Cache-Control": "no-cache"},
        ).listen(
          (event) {
            if (event.event == "data" || event.event == "complete") {
              try {
                final data = jsonDecode(event.data!);
                String predictedLabel = "gagal_decode";
                if (data is List && data.isNotEmpty) {
                  predictedLabel = data[0];
                } else if (data is Map && data.containsKey("data")) {
                  predictedLabel = data["data"][0];
                }
                if (!completer.isCompleted) completer.complete(predictedLabel);
              } catch (e) {
                // ignore parsing error
              }
            }
          },
          onError: (e) {
            if (!completer.isCompleted) completer.completeError("Stream Error");
          },
        );

        try {
          label = await completer.future;
        } finally {
          timer.cancel();
        }
      }
    } catch (e) {
      print("Error API: $e");
      return "Gagal: Masalah koneksi AI.";
    }

    int pointsToAdd = 0;
    String detectedItem = "sampah tidak dikenal";
    label = label.trim();

    if (label == 'botol_kaca') {
      pointsToAdd = 90;
      detectedItem = "botol kaca";
    } else if (label == 'karton') {
      pointsToAdd = 50;
      detectedItem = "karton";
    } else if (label == 'botol_plastik') {
      pointsToAdd = 40;
      detectedItem = "botol plastik";
    } else if (label == 'kertas') {
      pointsToAdd = 45;
      detectedItem = "kertas";
    } else if (label == 'kaleng') {
      pointsToAdd = 60;
      detectedItem = "kaleng";
    }

    if (pointsToAdd == 0) {
      return "Gagal: Sampah '$label' tidak terdaftar.";
    }

    String imageUrl = "";
    try {
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

      if (cloudName.isNotEmpty && uploadPreset.isNotEmpty) {
        final cloudinary = CloudinaryPublic(
          cloudName,
          uploadPreset,
          cache: false,
        );
        final CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            image.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        imageUrl = response.secureUrl;
      }
    } catch (e) {
      print("Error upload Cloudinary: $e");
    }

    try {
      final userRef = _firestore.collection('users').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final data = snapshot.data() as Map<String, dynamic>;

        int currentPoints = data['points'] ?? 0;
        transaction.update(userRef, {'points': currentPoints + pointsToAdd});

        int currentBurst = data['scanBurstCount'] ?? 0;
        Timestamp? lastBurstTime = data['lastBurstStartTime'];
        final now = DateTime.now();

        if (lastBurstTime != null) {
          final diff = now.difference(lastBurstTime.toDate());

          if (diff.inHours >= COOLDOWN_HOURS) {
            currentBurst = 0;
            transaction.update(userRef, {
              'lastBurstStartTime': FieldValue.serverTimestamp(),
            });
          }
        } else {
          transaction.update(userRef, {
            'lastBurstStartTime': FieldValue.serverTimestamp(),
          });
        }

        transaction.update(userRef, {'scanBurstCount': currentBurst + 1});

        final historyRef = userRef.collection('history').doc();
        transaction.set(historyRef, {
          'title': 'Membuang $detectedItem',
          'points': pointsToAdd,
          'type': 'earn',
          'createdAt': FieldValue.serverTimestamp(),
          'imageUrl': imageUrl,
        });
      });

      await _updateStreakAndBonus(user);

      return "sukses:+$pointsToAdd Poin untuk $detectedItem!";
    } catch (e) {
      print("Error DB Transaction: $e");
      return "Gagal: Error saat menyimpan data.";
    }
  }

  Future<void> _updateStreakAndBonus(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    try {
      final doc = await userRef.get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      int currentStreak = data['streakCount'] ?? 0;
      Timestamp? lastTimestamp = data['lastStreakTimestamp'];

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final yesterdayStart = DateTime(now.year, now.month, now.day - 1);

      Map<String, dynamic> updates = {};
      int pointsFromBonus = 0;
      String? bonusHistoryTitle;

      if (lastTimestamp == null) {
        updates['streakCount'] = 1;
        updates['lastStreakTimestamp'] = FieldValue.serverTimestamp();
      } else {
        final lastScanDate = lastTimestamp.toDate();
        if (lastScanDate.isAfter(todayStart)) {
          return;
        } else if (lastScanDate.isAfter(yesterdayStart)) {
          final int newStreakCount = currentStreak + 1;
          updates['streakCount'] = FieldValue.increment(1);
          updates['lastStreakTimestamp'] = FieldValue.serverTimestamp();

          if (newStreakCount > 0 && newStreakCount % 30 == 0) {
            pointsFromBonus = (newStreakCount / 30).floor() * 50;
            bonusHistoryTitle = "Bonus Streak $newStreakCount Hari!";
            updates['points'] = FieldValue.increment(pointsFromBonus);
          }
        } else {
          updates['streakCount'] = 1;
          updates['lastStreakTimestamp'] = FieldValue.serverTimestamp();
        }
      }

      if (updates.isNotEmpty) {
        await userRef.update(updates);
      }

      if (pointsFromBonus > 0 && bonusHistoryTitle != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .add({
              'title': bonusHistoryTitle,
              'points': pointsFromBonus,
              'type': 'earn',
              'createdAt': FieldValue.serverTimestamp(),
              'imageUrl': '',
            });
      }
    } catch (e) {
      print("Error saat update streak: $e");
    }
  }
}
