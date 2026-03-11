import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PrayerService {
  static const String _apiKey = '03dd8d9467b2169e39bda684785ff623';

  static Future<List<dynamic>> fetchJadwalSholat(
    String city,
    String month,
    String year,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = "prayer_muslimsalat_$city-$year-$month";

    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      return json.decode(cachedData) as List<dynamic>;
    }

    // MuslimSalat monthly endpoint with API Key and Method 5 (Muslim World League)
    final formattedMonth = month.padLeft(2, '0');
    final url =
        'https://muslimsalat.com/$city/monthly/01-$formattedMonth-$year.json?key=$_apiKey&method=5';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status_code'] == 1) {
          final items = data['items'] as List<dynamic>;

          // Map MuslimSalat keys to app keys and normalize time to 24h
          final normalizedItems = items.map((e) {
            final fahrRaw = e['fajr'];
            final shurooqRaw = e['shurooq'];

            final shubuh = _convertTo24h(fahrRaw);
            final terbit = _convertTo24h(shurooqRaw);

            // Calculate Imsyak (approx 10 min before Subuh) and Dhuha (approx 20 min after Terbit)
            final imsyak = _adjustTime(shubuh, -10);
            final dhuha = _adjustTime(terbit, 20);

            return {
              'tanggal': _normalizeDate(e['date_for']),
              'imsyak': imsyak,
              'shubuh': shubuh,
              'terbit': terbit,
              'dhuha': dhuha,
              'dzuhur': _convertTo24h(e['dhuhr']),
              'ashr': _convertTo24h(e['asr']),
              'magrib': _convertTo24h(e['maghrib']),
              'isya': _convertTo24h(e['isha']),
            };
          }).toList();

          await prefs.setString(cacheKey, json.encode(normalizedItems));
          return normalizedItems;
        }
      }
    } catch (e) {
      print("Error fetch MuslimSalat: $e");
    }

    throw Exception('Gagal memuat jadwal sholat untuk $city');
  }

  static String _normalizeDate(String dateStr) {
    // Input: "2026-2-24" -> Output: "2026-02-24"
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final month = parts[1].padLeft(2, '0');
        final day = parts[2].padLeft(2, '0');
        return "$year-$month-$day";
      }
    } catch (_) {}
    return dateStr;
  }

  static String _convertTo24h(String timeStr) {
    // Input: "4:49 am" -> Output: "04:49"
    // Input: "2:57 pm" -> Output: "14:57"
    try {
      final format = DateFormat("h:mm a");
      final time = format.parse(timeStr.toUpperCase());
      return DateFormat("HH:mm").format(time);
    } catch (e) {
      return timeStr;
    }
  }

  static String _adjustTime(String hhmm, int minutes) {
    try {
      final format = DateFormat("HH:mm");
      final time = format.parse(hhmm);
      final adjusted = time.add(Duration(minutes: minutes));
      return format.format(adjusted);
    } catch (_) {
      return hhmm;
    }
  }

  static Future<List<String>> fetchCitySuggestions() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/lakuapik/jadwalsholatorg/master/kota.json',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<String> getClosestCity(String userCityName) async {
    // MuslimSalat allows direct city names, no need for the old GitHub list lookup
    return userCityName;
  }

  static Map<String, dynamic>? calculateNextPrayer(List<dynamic>? jadwal) {
    if (jadwal == null || jadwal.isEmpty) return null;

    final now = DateTime.now();
    final hhmmFormat = DateFormat('HH:mm');
    final todayDate = DateFormat('yyyy-MM-dd').format(now);

    final todaySchedule = jadwal
        .where((e) => e['tanggal'] == todayDate)
        .firstOrNull;
    if (todaySchedule == null) {
      // If today is not in current month list, fallback to first item
      return null;
    }

    DateTime parseTime(String hhmm) {
      final t = hhmmFormat.parse(hhmm);
      return DateTime(now.year, now.month, now.day, t.hour, t.minute);
    }

    final prayers = {
      "Subuh": parseTime(todaySchedule['shubuh']),
      "Dzuhur": parseTime(todaySchedule['dzuhur']),
      "Ashar": parseTime(todaySchedule['ashr']),
      "Maghrib": parseTime(todaySchedule['magrib']),
      "Isya": parseTime(todaySchedule['isya']),
    };

    String nextName = "Subuh";
    Duration? closest;

    prayers.forEach((name, time) {
      final diff = time.difference(now);
      if (diff > Duration.zero && (closest == null || diff < closest!)) {
        closest = diff;
        nextName = name;
      }
    });

    // If all prayers today are passed, next is Subuh tomorrow (simplification)
    final nextTimeText = closest != null
        ? hhmmFormat.format(prayers[nextName]!)
        : "N/A";

    return {
      "nextName": nextName,
      "nextTime": nextTimeText,
      "remaining": closest,
      "todaySchedule": todaySchedule,
    };
  }
}
