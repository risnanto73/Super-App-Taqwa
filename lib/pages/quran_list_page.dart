import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bitaqwa/model/quran_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bitaqwa/pages/quran_detail_page.dart';
import '../widgets/quran/surat_card.dart';

class QuranListPage extends StatefulWidget {
  const QuranListPage({super.key});

  @override
  State<QuranListPage> createState() => _QuranListPageState();
}

class _QuranListPageState extends State<QuranListPage> {
  List<Surat> suratList = [];
  List<Surat> filteredList = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final String _suratCacheKey = "surat_list_cache";

  @override
  void initState() {
    super.initState();
    _loadCachedAndFetch();
  }

  Future<void> _loadCachedAndFetch() async {
    await _loadCachedSurat();
    await fetchSuratList();
  }

  Future<void> _loadCachedSurat() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_suratCacheKey);
    if (cached != null) {
      final data = json.decode(cached) as List;
      setState(() {
        suratList = data.map((e) => Surat.fromJson(e)).toList();
        filteredList = suratList;
        isLoading = false;
      });
    }
  }

  Future<void> fetchSuratList() async {
    try {
      final res = await http.get(Uri.parse("https://equran.id/api/v2/surat"));
      if (res.statusCode == 200) {
        final rawData = json.decode(res.body)['data'] as List;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_suratCacheKey, json.encode(rawData));

        setState(() {
          suratList = rawData.map((e) => Surat.fromJson(e)).toList();
          filteredList = suratList;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetch surat: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredList = suratList;
      } else {
        filteredList = suratList
            .where(
              (s) =>
                  s.namaLatin.toLowerCase().contains(query.toLowerCase()) ||
                  s.arti.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _showBookmarkSheet() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookmarks = prefs.getStringList('quran_bookmarks') ?? [];

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "🔖 Daftar Bookmark",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  bookmarks.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text("Belum ada bookmark"),
                        )
                      : Flexible(
                          child: ListView.builder(
                            itemCount: bookmarks.length,
                            itemBuilder: (context, index) {
                              final item = json.decode(bookmarks[index]);
                              return ListTile(
                                leading: const Icon(
                                  Icons.bookmark,
                                  color: Colors.amber,
                                ),
                                title: Text(
                                  "${item['suratName']} : ${item['nomorAyat']}",
                                ),
                                subtitle: Text(
                                  item['teksArab'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'ScheherazadeNew',
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    setSheetState(() {
                                      bookmarks.removeAt(index);
                                    });
                                    await prefs.setStringList(
                                      'quran_bookmarks',
                                      bookmarks,
                                    );
                                  },
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QuranDetailPage(
                                        suratId: item['suratId'],
                                        startAyat: item['nomorAyat'],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("📖 Al-Qur'an Digital"),
        backgroundColor: Colors.green[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_added_rounded),
            onPressed: _showBookmarkSheet,
            tooltip: "Bookmarks",
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSearch,
              decoration: InputDecoration(
                hintText: "Cari surat (contoh: Al-Fatihah, An-Nas...)",
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 📜 Daftar Surat
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : filteredList.isEmpty
                ? const Center(child: Text("Tidak ada surat ditemukan"))
                : ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final surat = filteredList[index];
                      return SuratCard(surat: surat);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
