// lib/features/history/screens/history_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:eco_quest/utils/app_colors.dart';
import 'package:eco_quest/features/history/services/history_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text(
          'Histori',
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _historyService.getHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada riwayat transaksi.'));
          }

          final historyDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: historyDocs.length,
            itemBuilder: (context, index) {
              final doc = historyDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              // Format tanggal agar lebih cantik
              String formattedDate = 'Tanggal tidak tersedia';
              if (data['createdAt'] != null) {
                final timestamp = data['createdAt'] as Timestamp;
                formattedDate = DateFormat(
                  'd MMMM yyyy | HH:mm',
                ).format(timestamp.toDate());
              }

              return _buildHistoryCard(
                type: data['type'] ?? 'earn',
                title: data['title'] ?? 'Aktivitas tidak diketahui',
                date: formattedDate,
                points: data['points'] ?? 0,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard({
    required String type,
    required String title,
    required String date,
    required int points,
  }) {
    final bool isNegative = points < 0 || type == 'spend' || type == 'penalty';

    final Color pointColor = isNegative
        ? Colors.red.shade400
        : const Color(0xFF3B4A3F); // Warna hijau tema app

    String pointText;
    if (points < 0) {
      pointText = '$points Points';
    } else if (isNegative) {
      pointText = '-$points Points';
    } else {
      pointText = '+$points Points';
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            Text(
              pointText,
              style: TextStyle(
                color: pointColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
