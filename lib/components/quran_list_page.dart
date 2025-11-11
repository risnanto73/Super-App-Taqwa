import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:bitaqwa/components/quran_detail_page.dart';
import 'package:bitaqwa/model/quran_models.dart';

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

  @override
  void initState() {
    super.initState();
    fetchSuratList();
  }

  Future<void> fetchSuratList() async {
    try {
      final res = await http.get(Uri.parse("https://equran.id/api/v2/surat"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'] as List;
        setState(() {
          suratList = data.map((e) => Surat.fromJson(e)).toList();
          filteredList = suratList;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Error fetch surat: $e");
      setState(() => isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("📖 Al-Qur'an Digital"),
        backgroundColor: Colors.green[700],
        elevation: 0,
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
                      return _buildSuratCard(context, surat);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // 💠 Card Surat (desain modern)
  // ======================================================
  Widget _buildSuratCard(BuildContext context, Surat surat) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuranDetailPage(suratId: surat.nomor),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Hero(
        tag: 'surat_${surat.nomor}',
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.green.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade100,
              ),
              alignment: Alignment.center,
              child: Text(
                surat.nomor.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),

            // 🔹 Gunakan Row agar kiri-kanan seimbang & teks Arab tidak overflow
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surat.namaLatin,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "${surat.arti} • ${surat.jumlahAyat} ayat",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: surat.tempatTurun.toLowerCase() == "mekah"
                                  ? Colors.orange.shade100
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              surat.tempatTurun,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    surat.tempatTurun.toLowerCase() == "mekah"
                                    ? Colors.orange.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 🔹 Kolom kanan untuk teks Arab — batasi lebarnya agar tidak mepet
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      surat.nama,
                      style: const TextStyle(
                        fontFamily: 'ScheherazadeNew',
                        fontSize: 22,
                        color: Colors.green,
                      ),
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
