import 'package:flutter/material.dart';

class QuranAudioPlayerCard extends StatelessWidget {
  final String selectedQari;
  final Map<String, String> qariList;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;
  final bool isRepeatMode;
  final bool isShuffleMode;
  final Function(String?) onQariChanged;
  final Function(double) onSeek;
  final VoidCallback onStop;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleRepeat;
  final VoidCallback onToggleShuffle;
  final String Function(Duration) formatDuration;

  const QuranAudioPlayerCard({
    super.key,
    required this.selectedQari,
    required this.qariList,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    required this.isRepeatMode,
    required this.isShuffleMode,
    required this.onQariChanged,
    required this.onSeek,
    required this.onStop,
    required this.onPlayPause,
    required this.onToggleRepeat,
    required this.onToggleShuffle,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.headphones, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  "Putar Surat Lengkap",
                  style: TextStyle(color: Colors.green[800], fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedQari,
              decoration: const InputDecoration(labelText: "Pilih Qari"),
              items: qariList.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: onQariChanged,
            ),
            Slider(
              activeColor: Colors.green[700],
              value: currentPosition.inSeconds.toDouble(),
              max: totalDuration.inSeconds.toDouble() > 0
                  ? totalDuration.inSeconds.toDouble()
                  : 1,
              onChanged: onSeek,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDuration(currentPosition)),
                Text(formatDuration(totalDuration)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.stop, color: Colors.red),
                  onPressed: onStop,
                ),
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: Colors.green,
                    size: 48,
                  ),
                  onPressed: onPlayPause,
                ),
                IconButton(
                  icon: Icon(
                    Icons.repeat,
                    color: isRepeatMode ? Colors.green : Colors.grey,
                  ),
                  onPressed: onToggleRepeat,
                ),
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: isShuffleMode ? Colors.green : Colors.grey,
                  ),
                  onPressed: onToggleShuffle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
