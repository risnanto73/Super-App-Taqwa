import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:home_widget/home_widget.dart';

import '../services/location_service.dart';
import '../services/prayer_service.dart';
import '../widgets/dashboard/dashboard_header.dart';
import '../widgets/dashboard/dashboard_menu.dart';
import '../widgets/dashboard/prayer_expansion.dart';
import '../widgets/dashboard/dashboard_carousel.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  String _location = "Mengambil lokasi...";
  String _prayerName = "Loading...";
  String _prayerTime = "Loading...";
  String _backgroundImage = 'assets/images/bg_morning.png';
  List<dynamic>? _jadwalSholat;
  Duration? _timeRemaining;
  Timer? _countdownTimer;

  final List<String> _posterList = const [
    'assets/images/ramadhan-kareem.png',
    'assets/images/idl-fitr.png',
    'assets/images/idl-adh.png',
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);

    if (!await LocationService.requestPermission()) {
      _showErrorDialog(
        "Izin lokasi ditolak. Aktifkan lokasi untuk melanjutkan.",
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final position = await LocationService.getCurrentPosition();
      final place = await LocationService.getPlacemark(
        position.latitude,
        position.longitude,
      );
      final locationText = LocationService.formatLocation(place);

      final cityName = place?.subAdministrativeArea ?? "semarang";
      final bestMatchCity = await PrayerService.getClosestCity(cityName);

      final now = DateTime.now();
      final month = DateFormat('MM').format(now);
      final year = DateFormat('yyyy').format(now);

      _jadwalSholat = await PrayerService.fetchJadwalSholat(
        bestMatchCity,
        month,
        year,
      );
      _updatePrayerLogic();

      setState(() {
        _location = locationText;
        _backgroundImage = _getBackgroundImage(now);
        _isLoading = false;
      });

      _updateHomeScreenWidget();
    } catch (e) {
      _showErrorDialog("Gagal mengambil data: ${e.toString()}");
      setState(() => _isLoading = false);
    }
  }

  void _updatePrayerLogic() {
    final nextPrayer = PrayerService.calculateNextPrayer(_jadwalSholat);
    if (nextPrayer != null) {
      setState(() {
        _prayerName = nextPrayer['nextName'];
        _prayerTime = nextPrayer['nextTime'];
        _timeRemaining = nextPrayer['remaining'];
      });

      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final updated = PrayerService.calculateNextPrayer(_jadwalSholat);
        if (updated != null) {
          if (updated['remaining'].isNegative) {
            _updatePrayerLogic();
          } else {
            if (mounted) setState(() => _timeRemaining = updated['remaining']);
          }
        }
      });
    }
  }

  Future<void> _updateHomeScreenWidget() async {
    if (_jadwalSholat == null) return;

    final now = DateTime.now();
    final todayDate = DateFormat('yyyy-MM-dd').format(now);
    final todaySchedule = _jadwalSholat!
        .where((e) => e['tanggal'] == todayDate)
        .firstOrNull;

    if (todaySchedule == null) return;

    await HomeWidget.saveWidgetData<String>('prayer_location', _location);
    await HomeWidget.saveWidgetData<String>(
      'prayer_next',
      'Berikutnya: $_prayerName • $_prayerTime',
    );
    await HomeWidget.saveWidgetData<String>(
      'time_subuh',
      todaySchedule["shubuh"] ?? "-",
    );
    await HomeWidget.saveWidgetData<String>(
      'time_dzuhur',
      todaySchedule["dzuhur"] ?? "-",
    );
    await HomeWidget.saveWidgetData<String>(
      'time_ashar',
      todaySchedule["ashr"] ?? "-",
    );
    await HomeWidget.saveWidgetData<String>(
      'time_maghrib',
      todaySchedule["magrib"] ?? "-",
    );
    await HomeWidget.saveWidgetData<String>(
      'time_isya',
      todaySchedule["isya"] ?? "-",
    );
    await HomeWidget.saveWidgetData<String>('active_prayer', _prayerName);

    await HomeWidget.updateWidget(androidName: 'PrayerWidgetProvider');
  }

  String _getBackgroundImage(DateTime now) {
    if (now.hour < 12) return 'assets/images/bg_morning.png';
    if (now.hour < 18) return 'assets/images/bg_afternoon.png';
    return 'assets/images/bg_night.png';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return "$hours jam $minutes menit lagi";
  }

  void _showErrorDialog(String msg) {
    if (!mounted) return;
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
                    DashboardHeader(
                      location: _location,
                      prayerName: _prayerName,
                      prayerTime: _prayerTime,
                      backgroundImage: _backgroundImage,
                      timeRemaining: _timeRemaining,
                      onRefresh: _initData,
                      formatDuration: _formatDuration,
                    ),
                    const SizedBox(height: 90),
                    const DashboardMenu(),
                    PrayerExpansion(
                      jadwalSholat: _jadwalSholat,
                      prayerName: _prayerName,
                    ),
                    DashboardCarousel(posterList: _posterList),
                  ],
                ),
              ),
            ),
    );
  }
}
