import 'package:flutter/material.dart';
import 'package:bitaqwa/model/quran_models.dart';

class TafsirCard extends StatelessWidget {
  final Tafsir tafsir;

  const TafsirCard({super.key, required this.tafsir});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ayat ${tafsir.ayat}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(tafsir.teks, textAlign: TextAlign.justify),
          ],
        ),
      ),
    );
  }
}
