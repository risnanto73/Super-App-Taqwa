import 'package:flutter/material.dart';

class DoaCard extends StatelessWidget {
  final Map<String, String> doa;

  const DoaCard({super.key, required this.doa});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul dan kategori
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (doa['image'] != null)
                  Image.asset(
                    doa['image']!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doa['title'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'PoppinsSemiBold',
                          fontSize: 16,
                          color: Colors.amber,
                        ),
                      ),
                      if (doa['category'] != null)
                        Text(
                          "📂 ${doa['category']!}",
                          style: const TextStyle(
                            fontFamily: 'PoppinsRegular',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Teks Arab
            if (doa['arabicText'] != null)
              Text(
                doa['arabicText']!,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'ScheherazadeNew',
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
            const SizedBox(height: 10),

            // Terjemahan
            if (doa['translation'] != null)
              Text(
                doa['translation']!,
                style: const TextStyle(
                  fontFamily: 'PoppinsRegular',
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 8),

            // Referensi
            if (doa['reference'] != null)
              Text(
                "📚 ${doa['reference']!}",
                style: const TextStyle(
                  fontFamily: 'PoppinsItalic',
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
