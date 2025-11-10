// ================================================================
// 🕌 SHOLAT PAGE — Jadwal Sholat Indonesia
// Menggunakan API dari Lakuapik (GitHub)
// Fitur: Search Kota + Jadwal Harian Sebulan + Warna & Ikon Tiap Salat
// ================================================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';


class SholatPage extends StatefulWidget {
  const SholatPage({super.key});

  @override
  State<SholatPage> createState() => _SholatPageState();
}

class _SholatPageState extends State<SholatPage> {
  // ================================================================
  // [🔹] STATE VARIABLE
  // ================================================================
  List<Map<String, String>> _cityList = []; // daftar {kode, nama}
  String? _selectedCityCode;
  String? _selectedCityName;
  List<dynamic> _prayerTimes = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCityList();
  }

  // ================================================================
  // [1] 🔷 Fungsi untuk mengambil daftar kota dari GitHub
  // ================================================================
  Future<void> _fetchCityList() async {
    try {
      setState(() => _isLoading = true);

      final response = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/lakuapik/jadwalsholatorg/master/kota.json',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ✅ karena data berupa List, bukan Map
        if (data is List) {
          setState(() {
            _cityList = data
                .map((e) => {"code": e.toString(), "name": e.toString()})
                .toList();
          });
        } else {
          print("⚠️ Struktur data tidak terduga: ${data.runtimeType}");
        }
      } else {
        throw Exception('Gagal memuat daftar kota');
      }
    } catch (e) {
      print("⚠️ Error fetch kota: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================================================================
  // [2] 🔷 Ambil jadwal sholat per kota dari API Lakuapik
  // ================================================================
  Future<void> _fetchPrayerSchedule(String cityCode, String cityName) async {
    try {
      setState(() {
        _isLoading = true;
        _selectedCityCode = cityCode;
        _selectedCityName = cityName;
        _prayerTimes = [];
      });

      final now = DateTime.now();
      final url =
          'https://raw.githubusercontent.com/lakuapik/jadwalsholatorg/master/adzan/$cityCode/${now.year}/${now.month.toString().padLeft(2, '0')}.json';

      print("🌐 Fetch: $url");
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        setState(() => _prayerTimes = json.decode(res.body));
      } else {
        throw Exception("Gagal memuat jadwal");
      }
    } catch (e) {
      print("❌ Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================================================================
  // [3] 🔷 Filter kota berdasarkan pencarian user
  // ================================================================
  List<Map<String, String>> _filterCities() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _cityList;
    return _cityList
        .where(
          (city) =>
              city["name"]!.toLowerCase().contains(query) ||
              city["code"]!.toLowerCase().contains(query),
        )
        .toList();
  }

  // ================================================================
  // [4] 🔷 Build UI utama (switch antara daftar kota / jadwal)
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          _selectedCityName == null
              ? "Jadwal Sholat Indonesia"
              : "🕌 ${_selectedCityName!}",
          style: const TextStyle(fontFamily: 'PoppinsSemiBold'),
        ),
        backgroundColor: Colors.amber,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// ------------------------------------------------------------
                  /// [4.1] Search Bar
                  /// ------------------------------------------------------------
                  if (_selectedCityCode == null)
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari kota (misal: Semarang, Surabaya...)',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),

                  /// ------------------------------------------------------------
                  /// [4.2] Jika belum pilih kota → tampilkan daftar kota
                  /// ------------------------------------------------------------
                  Expanded(
                    child: _selectedCityCode == null
                        ? _buildCityList()
                        : _buildPrayerScheduleView(),
                  ),
                ],
              ),
            ),
    );
  }

  // ================================================================
  // [5] 🔷 Widget daftar kota (dengan search filter)
  // ================================================================
  Widget _buildCityList() {
    final filteredCities = _filterCities();
    if (filteredCities.isEmpty) {
      return const Center(child: Text("Kota tidak ditemukan."));
    }

    return ListView.builder(
      itemCount: filteredCities.length,
      itemBuilder: (context, index) {
        final city = filteredCities[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(
              Icons.location_on_outlined,
              color: Colors.amber,
            ),
            title: Text(
              city["name"]!,
              style: const TextStyle(fontFamily: 'PoppinsMedium'),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => _fetchPrayerSchedule(city["code"]!, city["name"]!),
          ),
        );
      },
    );
  }

  // ================================================================
  // [6] 🔷 Widget jadwal sholat per kota (selama 1 bulan)
  // ================================================================
  Widget _buildPrayerScheduleView() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "📅 Jadwal Bulan Ini",
              style: const TextStyle(fontFamily: 'PoppinsSemiBold'),
            ),
            TextButton.icon(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: const Text("Ganti Kota"),
              onPressed: () {
                setState(() {
                  _selectedCityCode = null;
                  _prayerTimes.clear();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        Expanded(
          child: _prayerTimes.isEmpty
              ? const Center(child: Text("Memuat jadwal..."))
              : ListView.builder(
                  itemCount: _prayerTimes.length,
                  itemBuilder: (context, index) {
                    final item = _prayerTimes[index];
                    return _buildPrayerCard(item);
                  },
                ),
        ),
      ],
    );
  }

  // ================================================================
  // [7] 🔷 Card untuk setiap tanggal
  // ================================================================
  Widget _buildPrayerCard(Map<String, dynamic> item) {
    final date = DateTime.parse(item['tanggal']);
    final tanggal = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);

    final prayers = {
      "Shubuh": item['shubuh'],
      "Dzuhur": item['dzuhur'],
      "Ashar": item['ashr'],
      "Maghrib": item['magrib'],
      "Isya": item['isya'],
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tanggal,
              style: const TextStyle(
                fontFamily: 'PoppinsSemiBold',
                fontSize: 14,
                color: Colors.amber,
              ),
            ),
            const Divider(),
            ...prayers.entries.map((e) => _buildPrayerRow(e.key, e.value)),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // [8] 🔷 Helper: baris tiap waktu sholat dengan ikon & warna
  // ================================================================
  Widget _buildPrayerRow(String name, String time) {
    final iconData = {
      "Shubuh": Icons.bedtime_rounded,
      "Dzuhur": Icons.wb_sunny_rounded,
      "Ashar": Icons.cloud_rounded,
      "Maghrib": Icons.night_shelter_rounded,
      "Isya": Icons.nightlight_round,
    }[name]!;
    final color = {
      "Shubuh": Colors.indigo.shade200,
      "Dzuhur": Colors.orange.shade300,
      "Ashar": Colors.lightBlue.shade200,
      "Maghrib": Colors.deepOrange.shade300,
      "Isya": Colors.deepPurple.shade300,
    }[name]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(iconData, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontFamily: 'PoppinsMedium',
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            time,
            style: const TextStyle(fontFamily: 'PoppinsSemiBold', fontSize: 14),
          ),
        ],
      ),
    );
  }
}
