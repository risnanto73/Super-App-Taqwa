import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class DetailKajianPage extends StatefulWidget {
  final Map<String, String> video;

  const DetailKajianPage({super.key, required this.video});

  @override
  State<DetailKajianPage> createState() => _DetailKajianPageState();
}

class _DetailKajianPageState extends State<DetailKajianPage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();

    // Ambil Video ID dari URL YouTube
    final videoId = YoutubePlayer.convertUrlToId(widget.video['url']!);

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? "",
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(controller: _controller),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.video['title']!)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player YouTube
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: player,
                ),

                const SizedBox(height: 20),

                // Judul
                Text(
                  widget.video['title']!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Ustadz
                Text(
                  widget.video['ustadz']!,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 16),

                // Deskripsi
                Text(
                  widget.video['description']!,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
