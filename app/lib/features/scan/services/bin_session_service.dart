// lib/features/scan/services/bin_session_service.dart

import 'package:geolocator/geolocator.dart';

class BinSessionService {
  static final BinSessionService _instance = BinSessionService._internal();
  factory BinSessionService() => _instance;
  BinSessionService._internal();

  String? _activeBinId;
  double? _binLat;
  double? _binLng;

  void setSession(String binId, double lat, double lng) {
    _activeBinId = binId;
    _binLat = lat;
    _binLng = lng;
    print("✅ Sesi Tong Sampah Tersimpan: $binId ($lat, $lng)");
  }

  void clearSession() {
    _activeBinId = null;
    _binLat = null;
    _binLng = null;
    print("♻️ Sesi Tong Sampah Direset.");
  }

  Future<bool> canSkipQR() async {
    if (_activeBinId == null || _binLat == null || _binLng == null) {
      return false;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    try {
      Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distanceInMeters = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        _binLat!,
        _binLng!,
      );

      print(
        "📍 Jarak ke sesi aktif: ${distanceInMeters.toStringAsFixed(1)} meter",
      );

      if (distanceInMeters <= 30) {
        return true;
      } else {
        clearSession();
        return false;
      }
    } catch (e) {
      print("Error cek lokasi: $e");
      return false;
    }
  }
}
