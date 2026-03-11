import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/waris_service.dart';
import '../../services/pdf_service.dart';

class WarisResultView extends StatelessWidget {
  final WarisResult result;

  const WarisResultView({super.key, required this.result});

  static const List<Color> _chartColors = [
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.blueAccent,
    Colors.cyanAccent,
    Colors.tealAccent,
    Colors.greenAccent,
  ];

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle("HASIL PERHITUNGAN FARAIDH"),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.amber),
                  tooltip: "Download PDF",
                  onPressed: () {
                    PdfService.generateWarisReport(result);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.amber),
                  tooltip: "Bagikan Teks",
                  onPressed: () {
                    Share.share(result.toShareText());
                  },
                ),
              ],
            ),
          ],
        ),
        Text(
          "Pewaris: ${result.isDeceasedMale ? 'Laki-laki (Suami)' : 'Perempuan (Istri)'}",
          style: const TextStyle(
            fontFamily: 'PoppinsSemiBold',
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 20),

        // PIE CHART
        Center(
          child: SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(result.validHeirs.length, (i) {
                  final h = result.validHeirs[i];
                  final percentage =
                      (h.nominal ?? 0) / result.totalWealth * 100;
                  return PieChartSectionData(
                    color: _chartColors[i % _chartColors.length],
                    value: h.nominal ?? 0,
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'PoppinsBold',
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // LENGEND (Optional but helpful)
        const Text(
          "Keterangan Warna:",
          style: TextStyle(fontFamily: 'PoppinsSemiBold', fontSize: 12),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: List.generate(result.validHeirs.length, (i) {
            final h = result.validHeirs[i];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _chartColors[i % _chartColors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(h.name, style: const TextStyle(fontSize: 11)),
              ],
            );
          }),
        ),
        const SizedBox(height: 24),

        // LANGKAH 1 & 2
        _buildStepCard(
          "1 & 2. Identifikasi & Hijab",
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Ahli Waris Sah:",
                style: TextStyle(fontFamily: 'PoppinsSemiBold'),
              ),
              ...result.validHeirs.map(
                (h) => Text("• ${h.name} (${h.fractionText})"),
              ),
              if (result.blockedHeirs.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  "Ahli Waris Terhalang (Mahjub):",
                  style: TextStyle(
                    fontFamily: 'PoppinsSemiBold',
                    color: Colors.red,
                  ),
                ),
                ...result.blockedHeirs.map(
                  (h) =>
                      Text("• $h", style: const TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
        ),

        // LANGKAH 3 & 4
        _buildStepCard(
          "3 & 4. Ashlul Mas-alah",
          Text(
            "Ashlul Mas-alah (KPK Penyebut): ${result.initialAM}\n"
            "Status: ${result.adjustmentType ?? 'Normal'}",
          ),
        ),

        // LANGKAH 6
        _buildSectionTitle("RINCIAN PEMBAGIAN HARTA"),
        ...result.validHeirs.map((h) => _buildHeirCard(h, format)),

        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                "Total Harta",
                style: TextStyle(fontFamily: 'PoppinsRegular'),
              ),
              Text(
                format.format(result.totalWealth),
                style: const TextStyle(fontFamily: 'PoppinsBold', fontSize: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'PoppinsBold',
          fontSize: 16,
          color: Colors.amber,
        ),
      ),
    );
  }

  Widget _buildStepCard(String title, Widget content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'PoppinsBold',
                color: Colors.blueGrey,
              ),
            ),
            const Divider(),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildHeirCard(HeirPortion h, NumberFormat format) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          h.name,
          style: const TextStyle(fontFamily: 'PoppinsSemiBold'),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${h.fractionText} | Bagian: ${h.value}"),
            if (h.dalil != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  h.dalil!,
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: Colors.amber[900],
                  ),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              format.format(h.nominal!),
              style: const TextStyle(
                fontFamily: 'PoppinsBold',
                color: Colors.green,
              ),
            ),
            if (h.count > 1)
              Text(
                "@ ${format.format(h.nominal! / h.count)}",
                style: const TextStyle(fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}
