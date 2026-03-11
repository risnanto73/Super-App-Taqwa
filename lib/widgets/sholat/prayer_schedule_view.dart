import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'prayer_day_card.dart';

class PrayerScheduleView extends StatelessWidget {
  final List<dynamic> prayerTimes;
  final DateTime? filterDate;
  final VoidCallback onClearFilter;
  final VoidCallback onBack;

  const PrayerScheduleView({
    super.key,
    required this.prayerTimes,
    required this.onBack,
    this.filterDate,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    List<dynamic> sortedList = List.from(prayerTimes);
    if (filterDate == null) {
      // Pin hari ini ke atas, sisanya urut tanggal
      sortedList.sort((a, b) {
        if (a['tanggal'] == todayStr) return -1;
        if (b['tanggal'] == todayStr) return 1;
        return a['tanggal'].compareTo(b['tanggal']);
      });
    }

    final filteredList = filterDate == null
        ? sortedList
        : prayerTimes.where((e) {
            return e['tanggal'] == DateFormat('yyyy-MM-dd').format(filterDate!);
          }).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              filterDate == null ? "📅 Jadwal Sholat" : "📅 Hasil Filter",
              style: const TextStyle(fontFamily: 'PoppinsSemiBold'),
            ),
            Row(
              children: [
                if (filterDate != null)
                  TextButton(
                    onPressed: onClearFilter,
                    child: const Text(
                      "Lihat Semua",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                  label: const Text("Ganti Kota"),
                  onPressed: onBack,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: prayerTimes.isEmpty
              ? const Center(child: Text("Memuat jadwal..."))
              : filteredList.isEmpty
              ? const Center(child: Text("Tidak ada jadwal untuk tanggal ini"))
              : ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    return PrayerDayCard(item: item);
                  },
                ),
        ),
      ],
    );
  }
}
