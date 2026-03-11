import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class KajianVideoPlayer extends StatelessWidget {
  final YoutubePlayerController controller;

  const KajianVideoPlayer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: YoutubePlayer(controller: controller),
    );
  }
}
