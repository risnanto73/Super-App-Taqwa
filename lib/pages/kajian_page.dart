import 'package:flutter/material.dart';
import '../data/data_kajian.dart';
import '../widgets/kajian/kajian_card.dart';

class KajianPage extends StatelessWidget {
  const KajianPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kajian Islami"), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return KajianCard(video: video, index: index);
        },
      ),
    );
  }
}
