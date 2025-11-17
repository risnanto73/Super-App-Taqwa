import 'dart:async'; // timer countdown
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart'; // carousel slider
import 'package:http/http.dart' as http; // ambil data API JSON
import 'dart:convert'; // decode JSON
import 'package:geolocator/geolocator.dart'; // GPS
import 'package:geocoding/geocoding.dart'; // Konversi GPS
import 'package:intl/intl.dart'; // Formatter Number
import 'package:permission_handler/permission_handler.dart'; // Izin handler
import 'package:shared_preferences/shared_preferences.dart'; // cache lokal
import 'package:string_similarity/string_similarity.dart'; // fuzzy match string

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CarouselController _controller = CarouselController();
  int _currentIndex = 0;
  bool _isLoading = true;
  Duration? _timeRemaining;
  Timer? _countdownTimer;
  String _location = "Mengambil lokasi....";
  String _prayerTime = "Loading...";
  String _prayerName = "Loading...";
  String _backgroundImage = 'assets/images/bg_morning.png';
  List<dynamic>? _jadwalSholat;

  final posterList = const <String>[
    'assets/images/ramadhan-kareem.png',
    'assets/images/idl-fitr.png',
    'assets/images/idl-adh.png',
  ];

  //fungsi teks remaining waktu sholat
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minute = d.inMinutes.remainder(60);
    return "$hours jam $minute menit lagi";
  }

  // state untuk dijalankan diawal
  @override
  void initState() {
    super.initState();
    _updatePrayerTimes();
  }

  // ================================================================
  // LOGIKA INTI: UPDATE DATA WAKTU SHOLAT & LOKASI
  // ================================================================
  /// 🔹 Mengambil lokasi, mendeteksi kota terdekat, dan memuat jadwal sholat
  ///
  /// Diagram alur:
  ///
  ///  [GPS Position]
  ///  [Kota terdekat (fuzzy match)]
  ///  [Ambil data GitHub jadwal sholat]
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
  // API CALL: AMBIL DATA JADWAL SHOLAT DARI GITHUB
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
  // LOGIKA FUZZY MATCH: DETEKSI KOTA TERDEKAT
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
  // PERHITUNGAN: WAKTU SHOLAT BERIKUTNYA & COUNTDOWN
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
  // PERMINTAAN IZIN AKSES LOKASI
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
  // DIALOG ERROR
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

  String _getBackgroundImage(DateTime now) {
    if (now.hour < 12) {
      return 'assets/images/bg_morning.png';
    } else if (now.hour < 18) {
      return 'assets/images/bg_afternoon.png';
    }

    return 'assets/images/bg_night.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // =============================
              // [MENU WAKTU SHOLAT BY LOKASI]
              // =============================
              _buildHeroSection(),
              const SizedBox(height: 65),
              // =============================
              // [MENU SECTION]
              // =============================
              _buildMenuGridSection(),

              // =============================
              // [CAROUSEL SECTION]
              // =============================
              _buildCarouselSection(),
            ],
          ),
        ),
      ),
    );
  }

  // =============================
  // [MENU HERO WIDGET]
  // =============================
  Widget _buildHeroSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          height: 290,
          decoration: BoxDecoration(
            color: Color(0xFFB3E5FC),
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(30),
              bottomLeft: Radius.circular(30),
            ),
            image: DecorationImage(
              image: AssetImage(_backgroundImage),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Assalamu\'alaikum',
                  style: TextStyle(
                    fontFamily: 'PoppinsRegular',
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _location,
                  style: TextStyle(
                    fontFamily: 'PoppinsSemiBold',
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(DateTime.now()),
                  style: TextStyle(
                    fontFamily: 'PoppinsBold',
                    fontSize: 50,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ========= WAKTU SHOLAT SELANJUTNYA =========
        Positioned(
          bottom: -55,
          left: 20,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  blurRadius: 2,
                  offset: Offset(0, 4),
                  color: Colors.amber.withOpacity(0.4),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            child: Column(
              children: [
                Text(
                  'Waktu Sholat Berikutnya..',
                  style: TextStyle(
                    fontFamily: 'PoppinsRegular',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'ASHAR',
                  style: TextStyle(
                    fontFamily: 'PoppinsBold',
                    fontSize: 20,
                    color: Colors.amber,
                  ),
                ),
                Text(
                  '14:22',
                  style: TextStyle(
                    fontFamily: 'PoppinsBold',
                    fontSize: 28,
                    color: Colors.black38,
                  ),
                ),
                Text(
                  '5 Jam 10 Menit',
                  style: TextStyle(
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

  // =============================
  // [MENU ITEM WIDGET]
  // =============================
  Widget _buildMenuItem(String iconPath, String title, String routeName) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, routeName);
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.amber.withOpacity(0.2),
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
                style: TextStyle(fontFamily: 'PoppinsRegular', fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================
  // [MENU GRID SECTION WIDGET]
  // =============================
  Widget _buildMenuGridSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.count(
        crossAxisCount: 4, // max 4 baris
        shrinkWrap: true,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildMenuItem(
            'assets/images/ic_menu_doa.png', // iconPath
            'Doa', // title
            '/doa',
          ), //routeName
          _buildMenuItem(
            'assets/images/ic_menu_jadwal_sholat.png',
            'Sholat',
            '/doa',
          ),
          _buildMenuItem(
            'assets/images/ic_menu_video_kajian.png',
            'Kajian',
            '/doa',
          ),
          _buildMenuItem('assets/images/ic_menu_zakat.png', 'Zakat', '/doa'),
          _buildMenuItem(
            'assets/images/ic_menu_jadwal_sholat.png', // iconPath
            'Khutbah', // title
            '/doa',
          ),
        ],
      ),
    );
  }

  // =============================
  // [CAROUSEL SECTION WIDGET]
  // =============================
  Widget _buildCarouselSection() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // CAROUSEL CARD
        CarouselSlider.builder(
          itemCount: posterList.length,
          itemBuilder: (context, index, realIndex) {
            final poster = posterList[index];
            return Container(
              margin: EdgeInsets.all(15),
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(20),
                child: Image.asset(
                  poster,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
          options: CarouselOptions(
            autoPlay: true,
            height: 270,
            enlargeCenterPage: true,
            viewportFraction: 0.7,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
        ),

        // DOT INDIKATOR CAROUSEL
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: posterList.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _currentIndex.animateToPage(entry.key),
              child: Container(
                width: 10,
                height: 10,
                margin: EdgeInsets.all(2),
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
}

extension on int {
  void animateToPage(int key) {}
}
