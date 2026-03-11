import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ZakatResultCard extends StatelessWidget {
  final double zakatAmount;
  final bool isAboveNisab;
  final NumberFormat currencyFormat;

  final String? calculationBreakdown;

  const ZakatResultCard({
    super.key,
    required this.zakatAmount,
    required this.isAboveNisab,
    required this.currencyFormat,
    this.calculationBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 * 255
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isAboveNisab
                ? "✅ Anda WAJIB membayar zakat."
                : "ℹ️ Anda BELUM mencapai nisab.",
            style: TextStyle(
              fontFamily: 'PoppinsSemiBold',
              color: isAboveNisab ? Colors.green : Colors.redAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(zakatAmount),
            style: const TextStyle(
              fontFamily: 'PoppinsBold',
              fontSize: 28,
              color: Colors.green,
            ),
          ),
          if (calculationBreakdown != null &&
              calculationBreakdown!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            Text(
              "Penjabaran Hitungan:",
              style: TextStyle(
                fontFamily: 'PoppinsSemiBold',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              calculationBreakdown!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PoppinsMedium',
                fontSize: 13,
                color: Colors.grey[800],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
