import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrayerDayCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const PrayerDayCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(item['tanggal']);
    final tanggal = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);

    final prayers = {
      "Imsyak": item['imsyak'],
      "Shubuh": item['shubuh'],
      "Shurooq": item['terbit'],
      "Dhuha": item['dhuha'],
      "Dzuhur": item['dzuhur'],
      "Ashar": item['ashr'],
      "Maghrib": item['magrib'],
      "Isya": item['isya'],
    };

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = item['tanggal'] == todayStr;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: isToday ? 5 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isToday
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      color: isToday ? Colors.amber.withAlpha(13) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tanggal,
                  style: const TextStyle(
                    fontFamily: 'PoppinsSemiBold',
                    fontSize: 14,
                    color: Colors.amber,
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "HARI INI",
                      style: TextStyle(
                        fontFamily: 'PoppinsBold',
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(),
            ...prayers.entries.map(
              (e) => _buildPrayerRow(e.key, e.value.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerRow(String name, String time) {
    final iconData = {
      "Imsyak": Icons.timer_outlined,
      "Shubuh": Icons.bedtime_rounded,
      "Shurooq": Icons.wb_sunny_outlined,
      "Dhuha": Icons.wb_twilight_rounded,
      "Dzuhur": Icons.wb_sunny_rounded,
      "Ashar": Icons.cloud_rounded,
      "Maghrib": Icons.night_shelter_rounded,
      "Isya": Icons.nightlight_round,
    }[name]!;

    final color = {
      "Imsyak": Colors.blueGrey,
      "Shubuh": Colors.indigo.shade400,
      "Shurooq": Colors.amber.shade700,
      "Dhuha": Colors.orange.shade400,
      "Dzuhur": Colors.orange.shade600,
      "Ashar": Colors.lightBlue.shade600,
      "Maghrib": Colors.deepOrange.shade600,
      "Isya": Colors.deepPurple.shade600,
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
