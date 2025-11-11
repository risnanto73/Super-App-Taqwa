import 'package:bitaqwa/model/quran_models.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuranTafsirPage extends StatefulWidget {
  final int suratId;
  const QuranTafsirPage({super.key, required this.suratId});

  @override
  State<QuranTafsirPage> createState() => _QuranTafsirPageState();
}

class _QuranTafsirPageState extends State<QuranTafsirPage> {
  List<Tafsir> tafsirList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTafsir();
  }

  Future<void> fetchTafsir() async {
    final response = await http.get(Uri.parse("https://equran.id/api/v2/tafsir/${widget.suratId}"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data']['tafsir'] as List;
      setState(() {
        tafsirList = data.map((e) => Tafsir.fromJson(e)).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📚 Tafsir Ayat"),
        backgroundColor: Colors.green[700],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tafsirList.length,
              itemBuilder: (context, index) {
                final t = tafsirList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ayat ${t.ayat}",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(t.teks, textAlign: TextAlign.justify),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
