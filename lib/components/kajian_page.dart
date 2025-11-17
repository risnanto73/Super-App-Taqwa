import 'package:flutter/material.dart';
import 'detail_kajian_page.dart';
import '../data/data_kajian.dart';

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

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailKajianPage(video: video),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 5,
              shadowColor: Colors.black12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Thumbnail
                  Hero(
                    tag: "thumbnail_$index",
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                      child: Image.asset(
                        video["thumbnail"]!,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video['title']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          video['ustadz']!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
