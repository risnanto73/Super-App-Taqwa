import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardHeader extends StatelessWidget {
  final String location;
  final String prayerName;
  final String prayerTime;
  final String backgroundImage;
  final Duration? timeRemaining;
  final VoidCallback onRefresh;
  final String Function(Duration) formatDuration;

  const DashboardHeader({
    super.key,
    required this.location,
    required this.prayerName,
    required this.prayerTime,
    required this.backgroundImage,
    required this.timeRemaining,
    required this.onRefresh,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final timeNow = DateFormat('HH:mm').format(DateTime.now());

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          height: 290,
          decoration: BoxDecoration(
            color: const Color(0xFFB3E5FC),
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(30),
              bottomLeft: Radius.circular(30),
            ),
            image: DecorationImage(
              image: AssetImage(backgroundImage),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  "Assalamu'alaikum",
                  style: TextStyle(
                    fontFamily: 'PoppinsRegular',
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Text(
                  location,
                  style: const TextStyle(
                    fontFamily: 'PoppinsSemiBold',
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                Text(
                  timeNow,
                  style: const TextStyle(
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
                  color: Colors.black.withAlpha(25), // 0.1 * 255
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
                  prayerName.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'PoppinsBold',
                    fontSize: 20,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  prayerTime,
                  style: const TextStyle(
                    fontFamily: 'PoppinsBold',
                    fontSize: 28,
                    color: Colors.black87,
                  ),
                ),
                if (timeRemaining != null)
                  Text(
                    "(${formatDuration(timeRemaining!)})",
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
}
