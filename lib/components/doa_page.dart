// ================================================================
// 🕌 DOA PAGE — Kumpulan Doa Sehari-hari dengan GLOBAL SEARCH
// ================================================================
// 🔹 Data doa diambil dari: lib/data/data_doa.dart
// 🔹 Fitur:
//    ✅ Dropdown kategori (filter manual)
//    ✅ Pencarian lintas kategori (global search)
// ================================================================

import 'package:flutter/material.dart';
import '../data/data_doa.dart'; // ✅ sumber doa

class DoaPage extends StatefulWidget {
  const DoaPage({super.key});

  @override
  State<DoaPage> createState() => _DoaPageState();
}

class _DoaPageState extends State<DoaPage> {
  /// 🔹 Kategori aktif
  String _selectedCategory = "Makanan & Minuman";

  /// 🔹 Semua doa (gabungan seluruh kategori)
  late List<Map<String, String>> _allDoaList;

  /// 🔹 Doa yang ditampilkan (hasil filter atau kategori)
  late List<Map<String, String>> _displayedList;

  /// 🔹 Controller pencarian
  final TextEditingController _searchController = TextEditingController();

  /// 🔹 Daftar kategori yang tersedia
  final List<String> _categories = [
    "Makanan & Minuman",
    "Pagi & Malam",
    "Rumah",
    "Perjalanan",
    "Sholat",
    "Etika Baik"
  ];

  @override
  void initState() {
    super.initState();

    /// 🔹 Ambil semua doa dari tiap kategori, digabung
    _allDoaList = [];
    for (var cat in _categories) {
      final list = getDoaList(cat)
          .map((d) => {...d, "category": cat}) // tambahkan label kategori
          .toList();
      _allDoaList.addAll(list);
    }

    /// 🔹 Default tampilan = kategori pertama
    _displayedList = getDoaList(_selectedCategory);
  }

  // ================================================================
  // [1] 🔷 Ganti kategori
  // ================================================================
  void _onCategoryChanged(String? newCategory) {
    if (newCategory == null) return;
    setState(() {
      _selectedCategory = newCategory;
      _searchController.clear();
      _displayedList = getDoaList(_selectedCategory);
    });
  }

  // ================================================================
  // [2] 🔷 Fungsi pencarian global lintas kategori
  // ================================================================
  void _filterGlobal(String query) {
    setState(() {
      if (query.isEmpty) {
        _displayedList = getDoaList(_selectedCategory);
      } else {
        _displayedList = _allDoaList.where((doa) {
          final title = doa['title']?.toLowerCase() ?? '';
          final translation = doa['translation']?.toLowerCase() ?? '';
          return title.contains(query.toLowerCase()) ||
              translation.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // ================================================================
  // [3] 🔷 Bangun UI
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text(
          "Kumpulan Doa Sehari-hari",
          style: TextStyle(fontFamily: 'PoppinsSemiBold'),
        ),
        backgroundColor: Colors.amber,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------------
            // [3.1] Dropdown kategori doa
            // ------------------------------------------------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  items: _categories
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(
                                fontFamily: 'PoppinsMedium',
                                fontSize: 14,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: _onCategoryChanged,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ------------------------------------------------------------
            // [3.2] Search bar
            // ------------------------------------------------------------
            TextField(
              controller: _searchController,
              onChanged: _filterGlobal,
              decoration: InputDecoration(
                hintText: 'Cari doa (misal: tidur, makan, wudhu...)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterGlobal('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ------------------------------------------------------------
            // [3.3] List Doa
            // ------------------------------------------------------------
            Expanded(
              child: _displayedList.isEmpty
                  ? const Center(
                      child: Text(
                        "❌ Doa tidak ditemukan.",
                        style: TextStyle(
                          fontFamily: 'PoppinsRegular',
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _displayedList.length,
                      itemBuilder: (context, index) {
                        final doa = _displayedList[index];
                        return _buildDoaCard(doa);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // [4] 🔷 Widget Card Doa
  // ================================================================
  Widget _buildDoaCard(Map<String, String> doa) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul dan kategori
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (doa['image'] != null)
                  Image.asset(
                    doa['image']!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doa['title'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'PoppinsSemiBold',
                          fontSize: 16,
                          color: Colors.amber,
                        ),
                      ),
                      if (doa['category'] != null)
                        Text(
                          "📂 ${doa['category']!}",
                          style: const TextStyle(
                            fontFamily: 'PoppinsRegular',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Teks Arab
            if (doa['arabicText'] != null)
              Text(
                doa['arabicText']!,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'ScheherazadeNew',
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
            const SizedBox(height: 10),

            // Terjemahan
            if (doa['translation'] != null)
              Text(
                doa['translation']!,
                style: const TextStyle(
                  fontFamily: 'PoppinsRegular',
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 8),

            // Referensi
            if (doa['reference'] != null)
              Text(
                "📚 ${doa['reference']!}",
                style: const TextStyle(
                  fontFamily: 'PoppinsItalic',
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
