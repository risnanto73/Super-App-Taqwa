import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'waris_service.dart';

class PdfService {
  static Future<void> generateWarisReport(WarisResult result) async {
    final pdf = pw.Document();
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Load logo or custom fonts if needed (using default for now)

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                children: [
                  pw.Text(
                    "LAPORAN PERHITUNGAN WARIS (FARAIDH)",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                      color: PdfColors.amber,
                    ),
                  ),
                  pw.Divider(thickness: 2, color: PdfColors.amber),
                  pw.SizedBox(height: 10),
                ],
              ),
            ),

            pw.SizedBox(height: 10),
            pw.Text(
              "INFORMASI PEWARIS",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Jenis Kelamin:"),
                pw.Text(
                  result.isDeceasedMale
                      ? 'Laki-laki (Suami)'
                      : 'Perempuan (Istri)',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total Harta Warisan:"),
                pw.Text(
                  format.format(result.totalWealth),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 25),
            pw.Text(
              "RINCIAN PEMBAGIAN AHLI WARIS",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.SizedBox(height: 10),

            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.amber),
              headers: [
                "Nama Ahli Waris",
                "Bagian",
                "Nominal (IDR)",
                "Dalil Al-Quran",
              ],
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.center,
              data: result.validHeirs
                  .map(
                    (h) => [
                      h.name,
                      h.fractionText,
                      format.format(h.nominal ?? 0),
                      h.dalil ?? "-",
                    ],
                  )
                  .toList(),
            ),

            pw.SizedBox(height: 30),
            pw.Text(
              "MASALAH PERHITUNGAN",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.Bullet(text: "Ashlul Mas-alah (AM): ${result.initialAM}"),
            pw.Bullet(
              text: "Penyesuaian: ${result.adjustmentType ?? 'Normal'}",
            ),

            pw.Spacer(),
            pw.Divider(thickness: 1, color: PdfColors.grey),
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Column(
                children: [
                  pw.Text(
                    "Laporan ini diterbitkan secara otomatis oleh Aplikasi Taqwa.",
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 8,
                      color: PdfColors.grey,
                    ),
                  ),
                  pw.Text(
                    "Semoga bermanfaat untuk kemaslahatan umat.",
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 8,
                      color: PdfColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // Open PDF preview/print UI
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Laporan_Waris_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }
}
