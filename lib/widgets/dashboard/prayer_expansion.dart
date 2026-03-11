import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrayerExpansion extends StatelessWidget {
  final List<dynamic>? jadwalSholat;
  final String prayerName;

  const PrayerExpansion({
    super.key,
    required this.jadwalSholat,
    required this.prayerName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 3,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: const Icon(Icons.access_time, color: Colors.amber),
            title: const Text(
              "Jadwal Sholat Hari Ini",
              style: TextStyle(fontFamily: 'PoppinsBold', fontSize: 18),
            ),
            children: [
              if (jadwalSholat != null)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _buildTodayPrayerList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayPrayerList() {
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todaySchedule = jadwalSholat
        ?.where((e) => e['tanggal'] == todayDate)
        .firstOrNull;
    if (todaySchedule == null) return const Text("Tidak ada jadwal hari ini");

    final items = {
      "Imsyak": todaySchedule['imsyak'],
      "Shubuh": todaySchedule['shubuh'],
      "Shurooq": todaySchedule['terbit'],
      "Dhuha": todaySchedule['dhuha'],
      "Dzuhur": todaySchedule['dzuhur'],
      "Ashar": todaySchedule['ashr'],
      "Maghrib": todaySchedule['magrib'],
      "Isya": todaySchedule['isya'],
    };

    return Column(
      children: items.entries.map((entry) {
        final isNext = entry.key == prayerName;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isNext
                ? Colors.amber.withAlpha(38)
                : Colors.grey[50], // 0.15 * 255
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isNext ? Colors.amber : Colors.grey[300]!,
              width: isNext ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.key,
                style: TextStyle(
                  fontFamily: 'PoppinsMedium',
                  fontSize: 15,
                  color: isNext ? Colors.amber[900] : Colors.black87,
                ),
              ),
              Text(
                entry.value.toString(),
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
