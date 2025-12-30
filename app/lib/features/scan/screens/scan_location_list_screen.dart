// lib/features/scan/screens/scan_location_list_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:eco_quest/utils/app_colors.dart';
import 'package:eco_quest/features/scan/screens/scan_qr_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanLocationListScreen extends StatefulWidget {
  const ScanLocationListScreen({super.key});

  @override
  State<ScanLocationListScreen> createState() => _ScanLocationListScreenState();
}

class _ScanLocationListScreenState extends State<ScanLocationListScreen> {
  bool _isLoading = true;
  String _loadingMessage = 'Mendapatkan lokasimu...';
  List<Map<String, dynamic>> _nearbyBins = [];

  @override
  void initState() {
    super.initState();
    _fetchNearbyBins();
  }

  Future<void> _fetchNearbyBins() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Memeriksa izin lokasi...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _loadingMessage =
              'Layanan lokasi tidak aktif. Tolong nyalakan GPS-mu.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _loadingMessage =
                'Gagal memuat data: Kamu menolak izin untuk mengakses lokasi.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) _showPermissionDeniedDialog();
        setState(() {
          _loadingMessage =
              'Izin lokasi ditolak permanen. Aktifkan via pengaturan.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _loadingMessage = 'Mendapatkan lokasimu...';
      });
      final Position userPosition = await Geolocator.getCurrentPosition();

      setState(() {
        _loadingMessage = 'Mencari tong sampah terdekat...';
      });
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('trash_bins')
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _loadingMessage = 'Tidak ada data tong sampah di database.';
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> binsWithDistance = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data != null &&
            data.containsKey('binId') &&
            data.containsKey('name') &&
            data.containsKey('location')) {
          final GeoPoint binLocation = data['location'];
          double distanceInMeters = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            binLocation.latitude,
            binLocation.longitude,
          );

          binsWithDistance.add({
            'id': data['binId'],
            'name': data['name'],
            'distance': distanceInMeters,
            'lat': binLocation.latitude,
            'lon': binLocation.longitude,
          });
        } else {
          print(
            "Peringatan: Dokumen dengan ID ${doc.id} dilewati karena datanya tidak lengkap.",
          );
        }
      }

      binsWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        _nearbyBins = binsWithDistance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadingMessage = 'Gagal memuat data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Izin Lokasi Dibutuhkan'),
        content: const Text(
          'Aplikasi ini butuh akses lokasimu untuk menemukan tong sampah terdekat. Tolong aktifkan izin lokasi di pengaturan aplikasi.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Buka Pengaturan'),
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text(
          'Pilih Lokasi Tong Sampah',
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_loadingMessage),
                ],
              ),
            )
          : _nearbyBins.isEmpty
          ? Center(
              child: Text(
                _loadingMessage.isNotEmpty
                    ? _loadingMessage
                    : 'Tidak ada tong sampah ditemukan.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _nearbyBins.length,
              itemBuilder: (context, index) {
                final bin = _nearbyBins[index];
                final distance = bin['distance'] < 1000
                    ? '${bin['distance'].toStringAsFixed(0)} meter'
                    : '${(bin['distance'] / 1000).toStringAsFixed(1)} km';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      bin['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Jarak: $distance'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ScanQrScreen(
                            selectedBinId: bin['id'],
                            selectedBinName: bin['name'],
                            selectedBinLat: bin['lat'],
                            selectedBinLon: bin['lon'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
