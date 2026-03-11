import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PrayerWidgetUpdater {
  static const String _androidWidgetProvider = 'PrayerWidgetProvider';

  static Future<void> refreshAndSave() async {
    // 1) Pastikan izin lokasi (di APP, bukan widget)
    final pos = await _getCurrentPosition();

    // Reverse geocoding untuk dapetin nama kota
    String locationText;
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city =
            place.subAdministrativeArea ??
            place.locality ??
            place.administrativeArea ??
            '-';
        locationText = city;
      } else {
        locationText =
            '${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)}';
      }
    } catch (_) {
      locationText =
          '${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)}';
    }

    // 2) Hit API jadwal sholat hari ini (contoh Aladhan)
    final uri = Uri.parse(
      'https://api.aladhan.com/v1/timings'
      '?latitude=${pos.latitude}'
      '&longitude=${pos.longitude}'
      '&method=11',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Gagal ambil jadwal sholat. HTTP ${res.statusCode}');
    }

    final jsonMap = json.decode(res.body) as Map<String, dynamic>;
    final data = jsonMap['data'] as Map<String, dynamic>;
    final timings = data['timings'] as Map<String, dynamic>;

    final times = <String, String>{
      'Shubuh': timings['Fajr']?.toString() ?? '-',
      'Dzuhur': timings['Dhuhr']?.toString() ?? '-',
      'Ashar': timings['Asr']?.toString() ?? '-',
      'Maghrib': timings['Maghrib']?.toString() ?? '-',
      'Isya': timings['Isha']?.toString() ?? '-',
    };

    final next = _computeNextPrayer(times);
    final activeName = next
        .split(' • ')
        .first; // Extract "Shubuh", "Dzuhur", etc.

    // 3) Simpan ke HomeWidget storage
    await HomeWidget.saveWidgetData<String>('prayer_location', locationText);
    await HomeWidget.saveWidgetData<String>('prayer_next', 'Berikutnya: $next');

    // Simpan masing-masing waktu sholat untuk Row UI
    await HomeWidget.saveWidgetData<String>(
      'time_subuh',
      _hhmm(times['Shubuh']),
    );
    await HomeWidget.saveWidgetData<String>(
      'time_dzuhur',
      _hhmm(times['Dzuhur']),
    );
    await HomeWidget.saveWidgetData<String>(
      'time_ashar',
      _hhmm(times['Ashar']),
    );
    await HomeWidget.saveWidgetData<String>(
      'time_maghrib',
      _hhmm(times['Maghrib']),
    );
    await HomeWidget.saveWidgetData<String>('time_isya', _hhmm(times['Isya']));
    await HomeWidget.saveWidgetData<String>('active_prayer', activeName);

    // 4) Trigger update widget
    await HomeWidget.updateWidget(androidName: _androidWidgetProvider);
  }

  static String _hhmm(String? raw) {
    if (raw == null) return '-';
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
    if (m == null) return raw;
    final h = m.group(1)!.padLeft(2, '0');
    final mm = m.group(2)!;
    return '$h:$mm';
  }

  static String _computeNextPrayer(Map<String, String> times) {
    final now = DateTime.now();

    DateTime? parseToday(String? raw) {
      if (raw == null) return null;
      final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
      if (m == null) return null;
      final h = int.parse(m.group(1)!);
      final mm = int.parse(m.group(2)!);
      return DateTime(now.year, now.month, now.day, h, mm);
    }

    final schedule = <MapEntry<String, DateTime>>[];
    for (final e in times.entries) {
      final dt = parseToday(e.value);
      if (dt != null) schedule.add(MapEntry(e.key, dt));
    }
    schedule.sort((a, b) => a.value.compareTo(b.value));

    for (final e in schedule) {
      if (e.value.isAfter(now)) {
        return '${e.key} • ${DateFormat('HH:mm').format(e.value)}';
      }
    }

    // lewat Isya -> Shubuh besok
    final fajr = parseToday(times['Shubuh']);
    if (fajr != null) {
      final tomorrow = fajr.add(const Duration(days: 1));
      return 'Shubuh • ${DateFormat('HH:mm').format(tomorrow)}';
    }
    return '-';
  }

  static Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location service belum aktif.');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Izin lokasi ditolak.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Buka setting.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
