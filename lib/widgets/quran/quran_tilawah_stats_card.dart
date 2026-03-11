import 'package:flutter/material.dart';

class QuranTilawahStatsCard extends StatelessWidget {
  final int totalAyatRead;
  final Duration totalWaktuTilawah;
  final DateTime? lastRead;

  const QuranTilawahStatsCard({
    super.key,
    required this.totalAyatRead,
    required this.totalWaktuTilawah,
    required this.lastRead,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text(
                  "📖 Ayat Dibaca",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text("$totalAyatRead"),
              ],
            ),
            Column(
              children: [
                const Text(
                  "⏱️ Waktu",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text("${totalWaktuTilawah.inMinutes} menit"),
              ],
            ),
            Column(
              children: [
                const Text(
                  "📅 Terakhir",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  lastRead != null
                      ? "${lastRead!.day}/${lastRead!.month}"
                      : "-",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
