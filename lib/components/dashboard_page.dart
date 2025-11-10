// ================================================================
// 📘 MODUL AJAR: DASHBOARD WAKTU SHOLAT & LOKASI OTOMATIS
// ================================================================
// Struktur file ini mengikuti alur kerja Flutter modern:
// 1️⃣ Import library
// 2️⃣ Class utama (StatefulWidget)
// 3️⃣ Deklarasi variabel & state
// 4️⃣ Fungsi logika (API, lokasi, kalkulasi)
// 5️⃣ Fungsi UI (build widget)
// ================================================================

import 'dart:async'; // Timer countdown waktu sholat
import 'package:carousel_slider/carousel_slider.dart'; // Carousel banner
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Ambil data dari API GitHub
import 'dart:convert'; // Decode JSON
import 'package:geolocator/geolocator.dart'; // Ambil posisi GPS
import 'package:geocoding/geocoding.dart'; // Konversi GPS ke nama kota
import 'package:intl/intl.dart'; // Format tanggal & waktu
import 'package:permission_handler/permission_handler.dart'; // Izin lokasi
import 'package:shared_preferences/shared_preferences.dart'; // Cache lokal
import 'package:string_similarity/string_similarity.dart'; // Fuzzy match nama kota

// ================================================================
// [1] CLASS UTAMA: DashboardPage
// ================================================================
/// 🔹 Widget utama yang menampilkan:
/// - Lokasi pengguna
/// - Jadwal sholat otomatis
/// - Menu fitur (Doa, Zakat, Sholat, Kajian)
/// - Carousel banner islami
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

// ================================================================
// [2] STATE UTAMA: _DashboardPageState
// ================================================================
/// 🔹 Menampung semua state & logika utama aplikasi.
///
/// Alur logika:
///
///  ┌──────────────────────────────┐
///  │ 1. Ambil izin lokasi         │
///  │ 2. Dapatkan koordinat GPS    │
///  │ 3. Temukan kota terdekat     │
///  │ 4. Ambil jadwal sholat kota  │
///  │ 5. Hitung waktu sholat next  │
///  │ 6. Tampilkan countdown & UI  │
///  └──────────────────────────────┘
class _DashboardPageState extends State<DashboardPage> {
  // ------------------------------------------------------------
  // [3] VARIABEL STATE & KONTROL
  // ------------------------------------------------------------
  final CarouselController _controller = CarouselController();
  int _currentIndex = 0;
  bool _isLoading = true;
  Duration? _timeRemaining;
  Timer? _countdownTimer;

  // Fungsi bantu: ubah Duration jadi teks ramah
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return "$hours jam $minutes menit lagi";
  }

  // Gambar banner carousel
  final List<String> posterList = const [
    'assets/images/ramadhan-kareem.png',
    'assets/images/idl-fitr.png',
    'assets/images/idl-adh.png',
  ];

  // Variabel utama UI
  String _location = "Mengambil lokasi...";
  String _prayerName = "Loading...";
  String _prayerTime = "Loading...";
  String _backgroundImage = 'assets/images/bg_morning.png';
  List<dynamic>? _jadwalSholat;

  @override
  void initState() {
    super.initState();
    _updatePrayerTimes(); // jalankan saat awal
  }

  // ================================================================
  // [4] LOGIKA INTI: UPDATE DATA WAKTU SHOLAT & LOKASI
  // ================================================================
  /// 🔹 Mengambil lokasi, mendeteksi kota terdekat, dan memuat jadwal sholat
  ///
  /// Diagram alur:
  ///
  ///  [GPS Position]
  ///       ↓
  ///  [Kota terdekat (fuzzy match)]
  ///       ↓
  ///  [Ambil data GitHub jadwal sholat]
  ///       ↓
  ///  [Hitung waktu sholat terdekat + countdown]
  Future<void> _updatePrayerTimes() async {
    setState(() => _isLoading = true);

    if (await _requestLocationPermission()) {
      try {
        // Ambil posisi GPS user (timeout 10 detik)
        Position position =
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () =>
                  throw Exception("Gagal mendapatkan lokasi (timeout)"),
            );

        // Cari kota terdekat dari koordinat
        String city;
        try {
          city = await getClosestCity(position.latitude, position.longitude);
        } catch (_) {
          city = "semarang"; // fallback default
        }

        // Konversi koordinat ke nama lokasi manusiawi
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        Placemark place = placemarks.isNotEmpty
            ? placemarks.first
            : Placemark();

        // Ambil bulan & tahun sekarang
        String month = DateFormat('MM').format(DateTime.now());
        String year = DateFormat('yyyy').format(DateTime.now());

        // Ambil jadwal sholat & hitung waktu terdekat
        _jadwalSholat = await fetchJadwalSholat(city, month, year);
        _calculateNextPrayer();

        // Update tampilan UI
        setState(() {
          _location =
              "${place.subAdministrativeArea ?? ''}, ${place.locality ?? ''}";
          _backgroundImage = _getBackgroundImage(DateTime.now());
          _isLoading = false;
        });
      } catch (e) {
        _showErrorDialog("Gagal mengambil data: ${e.toString()}");
        setState(() => _isLoading = false);
      }
    } else {
      _showErrorDialog(
        "Izin lokasi ditolak. Aktifkan lokasi untuk melanjutkan.",
      );
      setState(() => _isLoading = false);
    }
  }

  // ================================================================
  // [5] API CALL: AMBIL DATA JADWAL SHOLAT DARI GITHUB
  // ================================================================
  /// 🔹 Mengambil data JSON jadwal sholat berdasarkan kota, bulan, dan tahun.
  /// 🔹 Data disimpan ke cache agar bisa diakses offline.
  Future<List<dynamic>> fetchJadwalSholat(
    String city,
    String month,
    String year,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = "$city-$year-$month";

    // Gunakan cache jika tersedia
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      return json.decode(cachedData) as List<dynamic>;
    }

    // Fetch dari GitHub repo jadwalsholatorg
    final url =
        'https://raw.githubusercontent.com/lakuapik/jadwalsholatorg/master/adzan/$city/$year/$month.json';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      await prefs.setString(cacheKey, response.body);
      return json.decode(response.body) as List<dynamic>;
    }

    // Fallback ke data tahun 2019 jika gagal
    final fallbackUrl =
        'https://raw.githubusercontent.com/lakuapik/jadwalsholatorg/master/adzan/$city/2019/$month.json';
    final fallbackResponse = await http.get(Uri.parse(fallbackUrl));

    if (fallbackResponse.statusCode == 200) {
      await prefs.setString(cacheKey, fallbackResponse.body);
      return json.decode(fallbackResponse.body) as List<dynamic>;
    }

    throw Exception('Gagal memuat jadwal sholat untuk $city ($month-$year)');
  }

  // ================================================================
  // [6] LOGIKA FUZZY MATCH: DETEKSI KOTA TERDEKAT
  // ================================================================
  /// 🔹 Mencocokkan nama kota pengguna dengan daftar kota dari GitHub.
  ///
  /// 🔸 Contoh:
  /// "Jakarta Selatan" → dicocokkan → "jakarta"
  Future<String> getClosestCity(double userLat, double userLon) async {
    final response = await http.get(
      Uri.parse(
        'https://raw.githubusercontent.com/lakuapik/jadwalsholatorg/master/kota.json',
      ),
    );
    if (response.statusCode != 200) throw Exception('Gagal memuat daftar kota');

    final List<dynamic> cityList = json.decode(response.body);
    List<Placemark> placemarks = await placemarkFromCoordinates(
      userLat,
      userLon,
    );
    Placemark place = placemarks.first;

    String userCity =
        (place.subAdministrativeArea ??
                place.locality ??
                place.administrativeArea ??
                "")
            .toLowerCase()
            .replaceAll(" ", "");

    double bestScore = 0.0;
    String bestMatch = cityList.first;
    for (var city in cityList) {
      double score = city.toString().similarityTo(userCity);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = city.toString();
      }
    }
    return bestMatch;
  }

  // ================================================================
  // [7] PERHITUNGAN: WAKTU SHOLAT BERIKUTNYA & COUNTDOWN
  // ================================================================
  /// 🔹 Menghitung waktu sholat berikutnya berdasarkan jadwal hari ini.
  /// 🔹 Menampilkan countdown waktu tersisa.
  void _calculateNextPrayer() {
    if (_jadwalSholat == null || _jadwalSholat!.isEmpty) return;

    final now = DateTime.now();
    final format = DateFormat('HH:mm');
    final todayDate = DateFormat('yyyy-MM-dd').format(now);

    var todaySchedule = _jadwalSholat?.firstWhere(
      (e) => e['tanggal'] == todayDate,
      orElse: () => null,
    );
    if (todaySchedule == null) return;

    // Helper untuk parsing waktu
    DateTime parseTime(String hhmm) {
      final t = format.parse(hhmm);
      return DateTime(now.year, now.month, now.day, t.hour, t.minute);
    }

    // Peta jadwal sholat
    final prayers = {
      "Shubuh": parseTime(todaySchedule['shubuh']),
      "Dzuhur": parseTime(todaySchedule['dzuhur']),
      "Ashar": parseTime(todaySchedule['ashr']),
      "Maghrib": parseTime(todaySchedule['magrib']),
      "Isya": parseTime(todaySchedule['isya']),
    };

    // Cari waktu sholat berikutnya
    String nextPrayer = "Shubuh";
    Duration? closest;
    prayers.forEach((name, time) {
      final diff = time.difference(now);
      if (diff > Duration.zero && (closest == null || diff < closest!)) {
        closest = diff;
        nextPrayer = name;
      }
    });

    setState(() {
      _prayerName = nextPrayer;
      _timeRemaining = closest;
      _prayerTime = closest != null
          ? DateFormat('HH:mm').format(prayers[nextPrayer]!)
          : "N/A";
    });

    // Timer countdown
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = prayers[nextPrayer]!.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        _calculateNextPrayer();
      } else {
        setState(() => _timeRemaining = remaining);
      }
    });
  }

  // ================================================================
  // [8] PERMINTAAN IZIN AKSES LOKASI
  // ================================================================
  /// 🔹 Meminta izin lokasi dari pengguna.
  Future<bool> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isGranted) return true;
    if (status.isDenied) {
      status = await Permission.location.request();
      return status.isGranted;
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  // ================================================================
  // [9] PEMILIH BACKGROUND SESUAI WAKTU
  // ================================================================
  /// 🔹 Menentukan gambar background pagi / siang / malam.
  String _getBackgroundImage(DateTime now) {
    if (now.hour < 12) return 'assets/images/bg_morning.png';
    if (now.hour < 18) return 'assets/images/bg_afternoon.png';
    return 'assets/images/bg_night.png';
  }

  // ================================================================
  // [10] DIALOG ERROR
  // ================================================================
  /// 🔹 Menampilkan dialog jika terjadi kesalahan (mis. gagal lokasi).
  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Terjadi Kesalahan"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // [11] BUILD UI: STRUKTUR UTAMA
  // ================================================================
  /// 🔹 Struktur tampilan utama dari atas ke bawah:
  ///
  ///  ┌─--------──────────────┐
  ///  │ Header (Lokasi, Jam)  │
  ///  │ Card Countdown Sholat │
  ///  │ Menu Grid 4 item      │
  ///  │ Jadwal Sholat (Expand)│
  ///  │ Carousel Banner       │
  ///  └───────────────--------┘
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 80),
                    _buildMenuGrid(),
                    if (_jadwalSholat != null) _buildPrayerExpansion(),
                    _buildCarouselSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // ================================================================
  // [12] BAGIAN HEADER & KARTU INFO WAKTU SHOLAT
  // ================================================================
  /// 🔹 Bagian ini menampilkan:
  ///   - Sapaan “Assalamu’alaikum”
  ///   - Nama lokasi & jam saat ini
  ///   - Kartu berisi waktu sholat berikutnya + countdown
  ///
  ///  ┌─────────────────────────────────────┐
  ///  │ 🌤  Background Langit               │
  ///  │ ┌───────────────────────────────┐  │
  ///  │ │ Assalamu’alaikum              │  │
  ///  │ │ Karanganyar, Jawa Tengah      │  │
  ///  │ │ 05:32                         │  │
  ///  │ └───────────────────────────────┘  │
  ///  │     ↓                             │
  ///  │  📅 Card “Waktu Sholat Berikutnya” │
  ///  └─────────────────────────────────────┘
  Widget _buildHeaderSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // [12.1] 🌅 Background Langit
        Container(
          width: double.infinity,
          height: 290,
          decoration: BoxDecoration(
            color: const Color(0xFFB3E5FC),
            image: DecorationImage(
              image: AssetImage(_backgroundImage),
              fit: BoxFit.cover,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Assalamu’alaikum",
                  style: TextStyle(
                    fontFamily: 'PoppinsRegular',
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _location,
                  style: const TextStyle(
                    fontFamily: 'PoppinsSemiBold',
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(DateTime.now()),
                  style: const TextStyle(
                    fontFamily: 'PoppinsBold',
                    fontSize: 50,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        // [12.2] 🕋 Card “Waktu Sholat Berikutnya”
        Positioned(
          bottom: -75,
          left: 20,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            child: Column(
              children: [
                const Text(
                  "Waktu Sholat Berikutnya",
                  style: TextStyle(
                    fontFamily: 'PoppinsRegular',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _prayerName,
                  style: const TextStyle(
                    fontFamily: 'PoppinsBold',
                    fontSize: 20,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  _prayerTime,
                  style: const TextStyle(
                    fontFamily: 'PoppinsBold',
                    fontSize: 28,
                    color: Colors.black87,
                  ),
                ),
                if (_timeRemaining != null)
                  Text(
                    "(${_formatDuration(_timeRemaining!)})",
                    style: const TextStyle(
                      fontFamily: 'PoppinsRegular',
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // [13] MENU GRID (Doa, Zakat, Sholat, Kajian)
  // ================================================================
  /// 🔹 Grid 4 kolom menampilkan fitur utama aplikasi.
  ///
  ///  ┌──────┬──────┬──────┬──────┐
  ///  │ 🙏 Doa │ 💰 Zakat │ 🕌 Sholat │ 🎥 Kajian │
  ///  └──────┴──────┴──────┴──────┘
  Widget _buildMenuGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildMenuItem('assets/images/ic_menu_doa.png', 'Doa', '/doa'),
          _buildMenuItem(
            'assets/images/ic_menu_zakat.png',
            'Zakat',
            '/zakat-page',
          ),
          _buildMenuItem(
            'assets/images/ic_menu_jadwal_sholat.png',
            'Sholat',
            '/jadwal-sholat',
          ),
          _buildMenuItem(
            'assets/images/ic_menu_video_kajian.png',
            'Kajian',
            '/video-kajian',
          ),
        ],
      ),
    );
  }

  // ================================================================
  // [14] EXPANSION TILE: JADWAL SHOLAT HARI INI
  // ================================================================
  /// 🔹 Menampilkan daftar jadwal sholat hari ini dalam bentuk expandable card.
  ///
  ///  ┌───────────── Jadwal Sholat Hari Ini ▼ ──────────────┐
  ///  │ Imsyak   04:22                                      │
  ///  │ Shubuh   04:33                                      │
  ///  │ ...                                                 │
  ///  └─────────────────────────────────────────────────────┘
  Widget _buildPrayerExpansion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 3,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            leading: const Icon(Icons.access_time, color: Colors.amber),
            title: const Text(
              "Jadwal Sholat Hari Ini",
              style: TextStyle(fontFamily: 'PoppinsBold', fontSize: 18),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildTodayPrayerListCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // [15] CAROUSEL SLIDER: POSTER / BANNER
  // ================================================================
  /// 🔹 Carousel menampilkan poster Islami bergulir otomatis.
  ///
  ///  ┌───────────────────────┐
  ///  │ [🌙 Ramadhan Kareem]  │
  ///  │ [🕋 Idul Adha]        │
  ///  └───────────────────────┘
  ///     ●    ○    ○   (indikator)
  Widget _buildCarouselSection() {
    return Column(
      children: [
        const SizedBox(height: 20),
        CarouselSlider.builder(
          itemCount: posterList.length,
          itemBuilder: (context, index, realIndex) {
            final poster = posterList[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  poster,
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 180,
            autoPlay: true,
            viewportFraction: 0.7,
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
        ),

        // [15.1] 🔘 Indikator carousel (titik bawah)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: posterList.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _controller.animateToPage(entry.key),
              child: Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == entry.key
                      ? Colors.amber
                      : Colors.grey[400],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ================================================================
  // [16] TABEL / LIST JADWAL SHOLAT HARI INI
  // ================================================================
  /// 🔹 Membuat daftar waktu sholat dengan highlight untuk waktu berikutnya.
  ///
  ///  ┌─────────────────────────────────────────────┐
  ///  │ 🕌 Shubuh 04:30 ← waktu berikutnya (kuning) │
  ///  │ Dzuhur 11:42                                │
  ///  │ Ashar 15:05                                 │
  ///  └─────────────────────────────────────────────┘
  Widget _buildTodayPrayerListCard() {
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var todaySchedule = _jadwalSholat?.firstWhere(
      (e) => e['tanggal'] == todayDate,
      orElse: () => null,
    );

    if (todaySchedule == null) {
      return const Text("Tidak ada jadwal untuk hari ini");
    }

    // [16.1] Koleksi waktu sholat
    final items = {
      "Imsyak": todaySchedule['imsyak'],
      "Shubuh": todaySchedule['shubuh'],
      "Terbit": todaySchedule['terbit'],
      "Dhuha": todaySchedule['dhuha'],
      "Dzuhur": todaySchedule['dzuhur'],
      "Ashar": todaySchedule['ashr'],
      "Maghrib": todaySchedule['magrib'],
      "Isya": todaySchedule['isya'],
    };

    // [16.2] Render ke daftar card
    return Column(
      children: items.entries.map((entry) {
        final isNext = entry.key == _prayerName;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isNext ? Colors.amber.withOpacity(0.15) : Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isNext ? Colors.amber : Colors.grey[300]!,
              width: isNext ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time_filled,
                    size: 18,
                    color: isNext ? Colors.amber[800] : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontFamily: 'PoppinsMedium',
                      fontSize: 15,
                      color: isNext ? Colors.amber[900] : Colors.black87,
                      fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              Text(
                entry.value,
                style: TextStyle(
                  fontFamily: 'PoppinsRegular',
                  fontSize: 15,
                  color: isNext ? Colors.amber[900] : Colors.black54,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ================================================================
  // [17] WIDGET BUILDER MENU GRID (Reusable Component)
  // ================================================================
  /// 🔹 Komponen kecil pembentuk item grid menu.
  ///
  ///  ┌──────────────┐
  ///  │   🕌 Icon    |
  ///  │  Zakat       │
  ///  └─────────────┘
  /// Klik → navigasi ke routeName.
  Widget _buildMenuItem(String iconPath, String title, String routeName) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.amber.withOpacity(0.2),
        onTap: () => Navigator.pushNamed(context, routeName),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(iconPath, width: 35),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'PoppinsRegular',
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on CarouselController {
  void animateToPage(int key) {}
}
