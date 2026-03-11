// ================================================================
// 🕌 SHOLAT PAGE — Jadwal Sholat Indonesia
// ================================================================
// Fitur:
// ✅ Ambil daftar kota dari API Lakuapik (GitHub)
// ✅ Pencarian kota (search filter)
// ✅ Tampilkan jadwal sholat sebulan penuh per kota
// ✅ Warna & ikon khusus untuk tiap waktu salat
// ================================================================

import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/prayer_service.dart';
import '../widgets/sholat/prayer_schedule_view.dart';

// ================================================================
// 🔷 Struktur Umum Widget
// ================================================================
// ┌────────────────────────────┐
// │ SholatPage (StatefulWidget)│
// ├────────────────────────────┤
// │  state variables           │
// │  ├ city list (API kota)    │
// │  ├ selected city           │
// │  ├ prayerTimes (jadwal)    │
// │  └ loading + controller    │
// ├────────────────────────────┤
// │  methods:                  │
// │  1️⃣ _fetchCityList()       │
// │  2️⃣ _fetchPrayerSchedule() │
// │  3️⃣ _filterCities()        │
// │  4️⃣ _buildUI()             │
// │  5️⃣ _buildCityList()       │
// │  6️⃣ _buildPrayerSchedule() │
// │  7️⃣ _buildPrayerCard()     │
// │  8️⃣ _buildPrayerRow()      │
// └────────────────────────────┘
// ================================================================

class SholatPage extends StatefulWidget {
  const SholatPage({super.key});

  @override
  State<SholatPage> createState() => _SholatPageState();
}

class _SholatPageState extends State<SholatPage> {
  // ================================================================
  // [🔹] STATE VARIABLE — Menyimpan data penting aplikasi
  // ================================================================
  String? _selectedCityName; // nama kota yang ditampilkan
  List<dynamic> _prayerTimes = []; // hasil jadwal dari API
  List<String> _citySuggestions = []; // daftar kota untuk suggest
  bool _isLoading = false;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _selectFilterDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(_selectedYear, _selectedMonth, 1),
      lastDate: DateTime(_selectedYear, _selectedMonth + 1, 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.amber,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _filterDate) {
      setState(() {
        _filterDate = picked;
      });
    }
  }

  Future<void> _loadSuggestions() async {
    final suggestions = await PrayerService.fetchCitySuggestions();
    if (mounted) {
      setState(() => _citySuggestions = suggestions);
    }
  }

  Future<void> _fetchWithLocation() async {
    try {
      setState(() => _isLoading = true);
      final hasPerm = await LocationService.requestPermission();
      if (!hasPerm) {
        _showError("Izin lokasi ditolak.");
        return;
      }

      final pos = await LocationService.getCurrentPosition();
      final place = await LocationService.getPlacemark(
        pos.latitude,
        pos.longitude,
      );

      // Bersihkan nama lokasi agar lebih akurat buat API (Hapus 'Kecamatan', 'Kabupaten', dsb)
      String cityName =
          place?.locality ?? place?.subAdministrativeArea ?? "Semarang";
      cityName = cityName
          .replaceAll(
            RegExp(r'Kecamatan|Kabupaten|Kota', caseSensitive: false),
            '',
          )
          .trim();

      await _fetchPrayerSchedule(cityName);
    } catch (e) {
      _showError("Gagal mendapatkan lokasi: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPrayerSchedule(String cityName) async {
    try {
      setState(() {
        _isLoading = true;
        _selectedCityName = cityName;
        _prayerTimes = [];
      });

      final result = await PrayerService.fetchJadwalSholat(
        cityName,
        _selectedMonth.toString(),
        _selectedYear.toString(),
      );

      setState(() => _prayerTimes = result);
    } catch (e) {
      _showError(
        "Gagal memuat jadwal untuk $cityName. Coba periksa koneksi atau nama kota.",
      );
      setState(() => _selectedCityName = null);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          _selectedCityName == null
              ? "Jadwal Sholat Dunia"
              : "🕌 ${_selectedCityName!}",
          style: const TextStyle(fontFamily: 'PoppinsSemiBold'),
        ),
        backgroundColor: Colors.amber,
        actions: [
          if (_selectedCityName != null)
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _selectFilterDate,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_selectedCityName == null) ...[
                    _buildSearchHeader(),
                    const SizedBox(height: 20),
                    _buildQuickLocationButton(),
                  ] else ...[
                    _buildDateRangeSelector(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: PrayerScheduleView(
                        prayerTimes: _prayerTimes,
                        filterDate: _filterDate,
                        onClearFilter: () => setState(() => _filterDate = null),
                        onBack: () {
                          setState(() {
                            _selectedCityName = null;
                            _prayerTimes.clear();
                            _filterDate = null;
                          });
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDateRangeSelector() {
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agu",
      "Sep",
      "Okt",
      "Nov",
      "Des",
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pilih Periode: ${_selectedYear}",
                style: const TextStyle(fontFamily: 'PoppinsBold'),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      setState(() => _selectedYear--);
                      _fetchPrayerSchedule(_selectedCityName!);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      setState(() => _selectedYear++);
                      _fetchPrayerSchedule(_selectedCityName!);
                    },
                  ),
                ],
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(12, (index) {
                final isSelected = _selectedMonth == (index + 1);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(months[index]),
                    selected: isSelected,
                    selectedColor: Colors.amber,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedMonth = index + 1);
                        _fetchPrayerSchedule(_selectedCityName!);
                      }
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Cari Kota",
            style: TextStyle(fontFamily: 'PoppinsBold', fontSize: 18),
          ),
          const Text(
            "Masukkan nama kota di seluruh dunia untuk melihat jadwal sholat.",
            style: TextStyle(
              fontFamily: 'PoppinsMedium',
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return _citySuggestions.where((String option) {
                return option.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                );
              });
            },
            onSelected: (String selection) {
              _fetchPrayerSchedule(selection);
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty)
                        _fetchPrayerSchedule(val.trim());
                    },
                    decoration: InputDecoration(
                      hintText: 'Misal: Semarang, London, Tokyo...',
                      prefixIcon: const Icon(
                        Icons.location_city,
                        color: Colors.amber,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.amber),
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            _fetchPrayerSchedule(controller.text.trim());
                          }
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  );
                },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLocationButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.amber,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        side: const BorderSide(color: Colors.amber, width: 1.5),
      ),
      onPressed: _fetchWithLocation,
      icon: const Icon(Icons.my_location),
      label: const Text(
        "Gunakan Lokasi Saat Ini",
        style: TextStyle(fontFamily: 'PoppinsSemiBold'),
      ),
    );
  }
}
