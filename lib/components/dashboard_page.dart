// -----------------------------------------------
// IMPORT PACKAGE YANG DIGUNAKAN
// -----------------------------------------------
import 'dart:async'; // untuk Timer countdown
import 'package:carousel_slider/carousel_slider.dart'; // slider banner
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // untuk ambil data dari API GitHub
import 'dart:convert'; // untuk decode JSON
import 'package:geolocator/geolocator.dart'; // ambil posisi GPS
import 'package:geocoding/geocoding.dart'; // konversi GPS ke nama kota
import 'package:intl/intl.dart'; // format tanggal & waktu
import 'package:permission_handler/permission_handler.dart'; // minta izin lokasi
import 'package:shared_preferences/shared_preferences.dart'; // simpan cache lokal
import 'package:string_similarity/string_similarity.dart'; // fuzzy match nama kota

// -----------------------------------------------
// DASHBOARD PAGE UTAMA
// -----------------------------------------------
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // controller untuk carousel banner
  final CarouselController _controller = CarouselController();

  // index banner aktif
  int _currentIndex = 0;

  // status loading
  bool _isLoading = true;

  // countdown menuju waktu sholat berikutnya
  Duration? _timeRemaining;
  Timer? _countdownTimer;

  // format durasi countdown jadi "x jam y menit lagi"
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return "$hours jam $minutes menit lagi";
  }

  // daftar poster carousel
  final List<String> posterList = const [
    'assets/images/ramadhan-kareem.png',
    'assets/images/idl-fitr.png',
    'assets/images/idl-adh.png',
  ];

  // variabel state utama
  String _location = "Mengambil lokasi...";
  String _prayerName = "Loading...";
  String _prayerTime = "Loading...";
  String _backgroundImage = 'assets/images/slider-3.png';
  List<dynamic>? _jadwalSholat;

  @override
  void initState() {
    super.initState();
    _updatePrayerTimes(); // mulai proses ambil lokasi & jadwal
  }

  // ---------------------------------------------------------
  // AMBIL LOKASI, DETEKSI KOTA, DAN MUAT JADWAL SHOLAT
  // ---------------------------------------------------------
  Future<void> _updatePrayerTimes() async {
    setState(() {
      _isLoading = true;
    });

    if (await _requestLocationPermission()) {
      try {
        // ambil posisi GPS dengan batas waktu 10 detik
        Position position =
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception("Gagal mendapatkan lokasi (timeout)");
              },
            );

        // cari kota terdekat berdasarkan koordinat GPS
        String city;
        try {
          city = await getClosestCity(position.latitude, position.longitude);
        } catch (e) {
          print("Gagal mencari kota terdekat: $e");
          city = "semarang"; // fallback default
        }

        // ambil nama lokasi secara deskriptif (misal: "Karanganyar, Jawa Tengah")
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        Placemark place = placemarks.isNotEmpty
            ? placemarks.first
            : Placemark();

        // ambil bulan & tahun saat ini
        String month = DateFormat('MM').format(DateTime.now());
        String year = DateFormat('yyyy').format(DateTime.now());

        // ambil jadwal sholat (pakai cache jika ada)
        _jadwalSholat = await fetchJadwalSholat(city, month, year);

        // hitung waktu sholat berikutnya
        _calculateNextPrayer();

        // update tampilan
        setState(() {
          _location =
              "${place.subAdministrativeArea ?? ''}, ${place.locality ?? ''}";
          _backgroundImage = _getBackgroundImage(DateTime.now());
          _isLoading = false;
        });
      } catch (e) {
        // tampilkan error dialog jika gagal
        print("ERROR di _updatePrayerTimes: $e");
        setState(() => _isLoading = false);
        _showErrorDialog("Gagal mengambil data: ${e.toString()}");
      }
    } else {
      // jika izin lokasi ditolak
      setState(() => _isLoading = false);
      _showErrorDialog(
        "Akses lokasi ditolak. Aktifkan izin lokasi untuk melanjutkan.",
      );
    }
  }

  // ---------------------------------------------------------
  // AMBIL JADWAL SHOLAT DARI API (DAN SIMPAN KE CACHE)
  // ---------------------------------------------------------
  Future<List<dynamic>> fetchJadwalSholat(
    String city,
    String month,
    String year,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = "$city-$year-$month";
    final cachedData = prefs.getString(cacheKey);

    // pakai data dari cache kalau sudah ada
    if (cachedData != null) {
      print("📦 Memuat jadwal dari cache: $cacheKey");
      return json.decode(cachedData) as List<dynamic>;
    }

    // ambil data dari GitHub
    final url =
        'https://raw.githubusercontent.com/lakuapik/jadwalsholatorg/master/adzan/$city/$year/$month.json';
    print("🌐 Fetching jadwal dari: $url");
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // simpan hasil ke cache
      await prefs.setString(cacheKey, response.body);
      print("✅ Jadwal disimpan ke cache: $cacheKey");
      return json.decode(response.body) as List<dynamic>;
    } else {
      // fallback ke data tahun 2019 jika tahun berjalan belum ada
      final fallbackUrl =
          'https://raw.githubusercontent.com/lakuapik/jadwalsholatorg/master/adzan/$city/2019/$month.json';
      final fallbackResponse = await http.get(Uri.parse(fallbackUrl));

      if (fallbackResponse.statusCode == 200) {
        await prefs.setString(cacheKey, fallbackResponse.body);
        print("⚠️ Gunakan data fallback (2019) dan simpan ke cache: $cacheKey");
        return json.decode(fallbackResponse.body) as List<dynamic>;
      } else {
        throw Exception(
          'Gagal memuat jadwal sholat untuk $city ($month-$year)',
        );
      }
    }
  }

  // ---------------------------------------------------------
  // COBA CARI KOTA TERDEKAT BERDASARKAN NAMA (FUZZY MATCH)
  // ---------------------------------------------------------
  Future<String> getClosestCity(double userLat, double userLon) async {
    // ambil daftar nama kota dari GitHub
    final url =
        'https://raw.githubusercontent.com/lakuapik/jadwalsholatorg/master/kota.json';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat daftar kota');
    }

    final List<dynamic> cityList = json.decode(response.body);

    // dapatkan nama kota dari koordinat
    List<Placemark> placemarks = await placemarkFromCoordinates(
      userLat,
      userLon,
    );
    Placemark place = placemarks.first;
    String? userCity =
        (place.subAdministrativeArea ??
                place.locality ??
                place.administrativeArea ??
                "")
            .toLowerCase()
            .replaceAll(" ", "");

    print("📍 Kota pengguna dari GPS: $userCity");

    // cari kecocokan nama kota (pakai library string_similarity)
    double bestScore = 0.0;
    String bestMatch = cityList.first;
    for (var city in cityList) {
      double score = city.toString().similarityTo(userCity ?? "");
      if (score > bestScore) {
        bestScore = score;
        bestMatch = city.toString();
      }
    }

    print(
      "🏙️ Kota terdekat cocok: $bestMatch (score: ${bestScore.toStringAsFixed(2)})",
    );
    return bestMatch;
  }

  // ---------------------------------------------------------
  // HITUNG WAKTU SHOLAT BERIKUTNYA & MULAI COUNTDOWN
  // ---------------------------------------------------------
  void _calculateNextPrayer() {
    if (_jadwalSholat == null || _jadwalSholat!.isEmpty) return;

    final now = DateTime.now();
    final format = DateFormat('HH:mm');
    final todayDate = DateFormat('yyyy-MM-dd').format(now);

    // ambil jadwal untuk hari ini
    var todaySchedule = _jadwalSholat?.firstWhere(
      (element) => element['tanggal'] == todayDate,
      orElse: () => null,
    );

    if (todaySchedule != null) {
      // ubah string jam jadi DateTime agar bisa dibanding
      DateTime parseTime(String hhmm) {
        final time = format.parse(hhmm);
        return DateTime(now.year, now.month, now.day, time.hour, time.minute);
      }

      // buat map daftar waktu sholat hari ini
      final prayers = {
        "Shubuh": parseTime(todaySchedule['shubuh']),
        "Dzuhur": parseTime(todaySchedule['dzuhur']),
        "Ashar": parseTime(todaySchedule['ashr']),
        "Maghrib": parseTime(todaySchedule['magrib']),
        "Isya": parseTime(todaySchedule['isya']),
      };

      // cari waktu sholat berikutnya (yang paling dekat setelah waktu sekarang)
      String nextPrayer = "Shubuh";
      Duration? closestDuration;

      prayers.forEach((name, time) {
        final diff = time.difference(now);
        if (diff > Duration.zero &&
            (closestDuration == null || diff < closestDuration!)) {
          closestDuration = diff;
          nextPrayer = name;
        }
      });

      // jika semua waktu sudah lewat → ambil shubuh besok
      if (closestDuration == null) {
        nextPrayer = "Shubuh";
        final tomorrow = now.add(Duration(days: 1));
        final tomorrowSchedule = _jadwalSholat?.firstWhere(
          (element) =>
              element['tanggal'] == DateFormat('yyyy-MM-dd').format(tomorrow),
          orElse: () => null,
        );

        _prayerTime = tomorrowSchedule != null
            ? tomorrowSchedule['shubuh']
            : "N/A";
      } else {
        _prayerTime = DateFormat('HH:mm').format(prayers[nextPrayer]!);
      }

      // simpan ke state dan mulai countdown
      setState(() {
        _prayerName = nextPrayer;
        _prayerTime = DateFormat('HH:mm').format(prayers[nextPrayer]!);
        _timeRemaining = prayers[nextPrayer]!.difference(now);
      });

      // timer hitung mundur setiap detik
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        final remaining = prayers[nextPrayer]!.difference(DateTime.now());
        if (remaining.isNegative) {
          timer.cancel();
          _calculateNextPrayer(); // otomatis hitung ulang setelah masuk waktu baru
        } else {
          setState(() {
            _timeRemaining = remaining;
          });
        }
      });
    } else {
      // kalau tidak ada jadwal
      setState(() {
        _prayerName = "N/A";
        _prayerTime = "N/A";
      });
    }
  }

  // ---------------------------------------------------------
  // PERMINTAAN IZIN AKSES LOKASI
  // ---------------------------------------------------------
  Future<bool> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isGranted) return true;

    if (status.isDenied) {
      status = await Permission.location.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings(); // arahkan user ke pengaturan app
      return false;
    }

    return false;
  }

  // ---------------------------------------------------------
  // PILIH BACKGROUND SESUAI JAM (pagi, siang, malam)
  // ---------------------------------------------------------
  String _getBackgroundImage(DateTime now) {
    int hour = now.hour;
    if (hour < 12) return 'assets/images/bg_morning.png';
    if (hour < 18) return 'assets/images/bg_afternoon.png';
    return 'assets/images/bg_night.png';
  }

  // ---------------------------------------------------------
  // DIALOG ERROR GENERIK
  // ---------------------------------------------------------
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Terjadi Kesalahan",
            style: TextStyle(fontFamily: 'PoppinsBold'),
          ),
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'PoppinsRegular'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------
  // BUILD UI DASHBOARD
  // ---------------------------------------------------------
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
                    // ===== HEADER DENGAN BACKGROUND LANGIT =====
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // bagian background
                        Container(
                          width: double.infinity,
                          height: 260,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB3E5FC),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/bg_morning.png'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
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
                                const SizedBox(height: 10),
                                Text(
                                  DateFormat('HH:mm').format(DateTime.now()),
                                  style: const TextStyle(
                                    fontFamily: 'PoppinsBold',
                                    fontSize: 52,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 25),
                              ],
                            ),
                          ),
                        ),

                        // CARD INFO WAKTU SHOLAT BERIKUTNYA
                        Positioned(
                          bottom: -65,
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 16,
                            ),
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
                    ),

                    const SizedBox(height: 80),

                    // ===== MENU GRID (Doa, Zakat, Sholat, Kajian) =====
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildMenuItem(
                            'assets/images/ic_menu_doa.png',
                            'Doa',
                            '/video-kajian',
                          ),
                          _buildMenuItem(
                            'assets/images/ic_menu_zakat.png',
                            'Zakat',
                            '/zakat-page',
                          ),
                          _buildMenuItem(
                            'assets/images/ic_menu_jadwal_sholat.png',
                            'Sholat',
                            '/video-kajian',
                          ),
                          _buildMenuItem(
                            'assets/images/ic_menu_video_kajian.png',
                            'Kajian',
                            '/video-kajian',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== EXPANSION TILE JADWAL SHOLAT =====
                    if (_jadwalSholat != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 3,
                          child: Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: false,
                              leading: const Icon(
                                Icons.access_time,
                                color: Colors.amber,
                              ),
                              title: const Text(
                                "Jadwal Sholat Hari Ini",
                                style: TextStyle(
                                  fontFamily: 'PoppinsBold',
                                  fontSize: 18,
                                ),
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
                      ),

                    const SizedBox(height: 20),

                    // ===== CAROUSEL SLIDER =====
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
                        viewportFraction: 0.85,
                        enlargeCenterPage: true,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                      ),
                    ),

                    // indikator carousel
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: posterList.asMap().entries.map((entry) {
                        return GestureDetector(
                          onTap: () => _controller.animateToPage(entry.key),
                          child: Container(
                            width: 10.0,
                            height: 10.0,
                            margin: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 4.0,
                            ),
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
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------
  // WIDGET BUILDER MENU GRID
  // ---------------------------------------------------------
  Widget _buildMenuItem(String iconPath, String title, String routeName) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.amber.withOpacity(0.2),
        onTap: () {
          Navigator.pushNamed(context, routeName);
        },
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

  // ---------------------------------------------------------
  // TAMPILKAN LIST JADWAL SHOLAT HARI INI (DALAM CARD)
  // ---------------------------------------------------------
  Widget _buildTodayPrayerListCard() {
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var todaySchedule = _jadwalSholat?.firstWhere(
      (element) => element['tanggal'] == todayDate,
      orElse: () => null,
    );

    if (todaySchedule == null) {
      return const Text("Tidak ada jadwal untuk hari ini");
    }

    // data waktu sholat
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

    return Column(
      children: items.entries.map((entry) {
        final isNext =
            entry.key == _prayerName; // tandai waktu sholat berikutnya

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
}

extension on CarouselController {
  void animateToPage(int key) {}
}
