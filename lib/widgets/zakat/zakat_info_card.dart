import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ZakatInfoCard extends StatelessWidget {
  final double nisabValue;
  final String? lastUpdate;
  final bool isOffline;
  final NumberFormat currencyFormat;

  const ZakatInfoCard({
    super.key,
    required this.nisabValue,
    required this.lastUpdate,
    required this.isOffline,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13), // 0.05 * 255
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.trending_up, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "📈 Harga emas dunia:",
                      style: TextStyle(
                        fontFamily: 'PoppinsSemiBold',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${currencyFormat.format(nisabValue / 85)} / gram",
                      style: const TextStyle(
                        fontFamily: 'PoppinsBold',
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    if (lastUpdate != null)
                      Text(
                        "Update: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(lastUpdate!))}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: isOffline ? Colors.redAccent : Colors.green,
                    size: 10,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOffline ? "Offline" : "Online",
                    style: TextStyle(
                      fontSize: 11,
                      color: isOffline ? Colors.redAccent : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            "💰 Nisab saat ini (85 gram emas): ${currencyFormat.format(nisabValue)} per tahun.",
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
