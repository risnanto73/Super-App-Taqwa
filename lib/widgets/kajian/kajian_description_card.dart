import 'package:flutter/material.dart';

class KajianDescriptionCard extends StatelessWidget {
  final Map<String, String> video;

  const KajianDescriptionCard({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          video['title']!,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          video['ustadz']!,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Text(
          video['description']!,
          textAlign: TextAlign.justify,
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }
}
