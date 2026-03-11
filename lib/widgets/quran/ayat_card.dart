import 'package:flutter/material.dart';
import '../../model/quran_models.dart';

class AyatCard extends StatelessWidget {
  final Ayat ayat;
  final bool isActive;
  final bool isFullSurahPlaying;
  final double progress;
  final bool isBookmarked;
  final VoidCallback onPlay;
  final VoidCallback onBookmark;

  const AyatCard({
    super.key,
    required this.ayat,
    required this.isActive,
    required this.isFullSurahPlaying,
    required this.progress,
    required this.isBookmarked,
    required this.onPlay,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? (isFullSurahPlaying ? Colors.green[100] : Colors.blue[50])
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: Colors.green.withAlpha(64),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            ayat.teksArab,
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'ScheherazadeNew', fontSize: 24),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              ayat.teksLatin,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(ayat.teksIndonesia),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(Colors.green.shade400),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ayat ${ayat.nomorAyat}",
                style: const TextStyle(color: Colors.grey),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? Colors.amber[700] : Colors.black54,
                    ),
                    onPressed: onBookmark,
                  ),
                  IconButton(
                    icon: Icon(
                      isActive
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: isActive ? Colors.green[800] : Colors.black54,
                      size: 32,
                    ),
                    onPressed: onPlay,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
