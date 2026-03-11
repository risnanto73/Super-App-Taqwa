import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import '../services/waris_service.dart';
import '../services/waris_history_service.dart';
import '../widgets/waris/heir_input_card.dart';
import '../widgets/waris/waris_result_view.dart';
import 'waris_history_page.dart';

class WarisPage extends StatefulWidget {
  const WarisPage({super.key});

  @override
  State<WarisPage> createState() => _WarisPageState();
}

class _WarisPageState extends State<WarisPage> {
  final TextEditingController _wealthController = TextEditingController();

  bool _isDeceasedMale = true;
  int H = 0, W = 0, S = 0, D = 0, GS = 0, GD = 0, F = 0, M = 0, GF = 0;
  int GMf = 0, GMm = 0, Bf = 0, Sf = 0, Bp = 0, Sp = 0, Bm = 0, Sm = 0;
  WarisResult? _result;

  void _calculate() {
    final wealth =
        double.tryParse(toNumericString(_wealthController.text)) ?? 0;
    if (wealth <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan jumlah harta yang valid")),
      );
      return;
    }

    setState(() {
      _result = WarisService.calculate(
        isDeceasedMale: _isDeceasedMale,
        H: _isDeceasedMale ? 0 : H,
        W: _isDeceasedMale ? W : 0,
        S: S,
        D: D,
        GS: GS,
        GD: GD,
        F: F,
        M: M,
        GF: GF,
        GMf: GMf,
        GMm: GMm,
        Bf: Bf,
        Sf: Sf,
        Bp: Bp,
        Sp: Sp,
        Bm: Bm,
        Sm: Sm,
        totalWealth: wealth,
      );
    });

    if (_result != null) {
      WarisHistoryService.saveCalculation(_result!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Kalkulator Waris",
          style: TextStyle(fontFamily: 'PoppinsBold'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Riwayat",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WarisHistoryPage(),
                ),
              );
            },
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Pewaris (Yang Meninggal Dunia)"),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("Laki-laki (Suami)")),
                    selected: _isDeceasedMale,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _isDeceasedMale = true;
                        H = 0;
                      }
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("Perempuan (Istri)")),
                    selected: !_isDeceasedMale,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _isDeceasedMale = false;
                        W = 0;
                      }
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Harta Bersih (U)",
              style: TextStyle(fontFamily: 'PoppinsSemiBold'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _wealthController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                CurrencyInputFormatter(
                  leadingSymbol: '',
                  thousandSeparator: ThousandSeparator.Period,
                  mantissaLength: 0,
                ),
              ],
              decoration: InputDecoration(
                hintText: "Contoh: 100.000.000",
                prefixText: "Rp ",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("Pasangan (Yang Hidup)"),
            if (!_isDeceasedMale)
              HeirInputCard(
                title: "Suami",
                subtitle: "Suami dari pewaris",
                value: H,
                max: 1,
                onChanged: (v) => setState(() => H = v),
              ),
            if (_isDeceasedMale)
              HeirInputCard(
                title: "Istri",
                subtitle: "Istri dari pewaris (maks 4)",
                value: W,
                max: 4,
                onChanged: (v) => setState(() => W = v),
              ),

            const SizedBox(height: 16),
            _buildSectionHeader("Keturunan"),
            HeirInputCard(
              title: "Anak Laki-laki",
              subtitle: "Anak kandung",
              value: S,
              onChanged: (v) => setState(() => S = v),
            ),
            HeirInputCard(
              title: "Anak Perempuan",
              subtitle: "Anak kandung",
              value: D,
              onChanged: (v) => setState(() => D = v),
            ),
            HeirInputCard(
              title: "Cucu Laki-laki",
              subtitle: "Dari anak laki-laki",
              value: GS,
              onChanged: (v) => setState(() => GS = v),
            ),
            HeirInputCard(
              title: "Cucu Perempuan",
              subtitle: "Dari anak laki-laki",
              value: GD,
              onChanged: (v) => setState(() => GD = v),
            ),

            const SizedBox(height: 16),
            _buildSectionHeader("Orang Tua"),
            HeirInputCard(
              title: "Ayah",
              subtitle: "Ayah kandung",
              value: F,
              max: 1,
              onChanged: (v) => setState(() => F = v),
            ),
            HeirInputCard(
              title: "Ibu",
              subtitle: "Ibu kandung",
              value: M,
              max: 1,
              onChanged: (v) => setState(() => M = v),
            ),
            HeirInputCard(
              title: "Kakek",
              subtitle: "Ayah dari ayah",
              value: GF,
              max: 1,
              onChanged: (v) => setState(() => GF = v),
            ),
            HeirInputCard(
              title: "Nenek (Ayah)",
              subtitle: "Nenek jalur ayah",
              value: GMf,
              max: 1,
              onChanged: (v) => setState(() => GMf = v),
            ),
            HeirInputCard(
              title: "Nenek (Ibu)",
              subtitle: "Nenek jalur ibu",
              value: GMm,
              max: 1,
              onChanged: (v) => setState(() => GMm = v),
            ),

            const SizedBox(height: 16),
            _buildSectionHeader("Saudara"),
            HeirInputCard(
              title: "Saudara Kandung (L)",
              subtitle: "Sekandung laki",
              value: Bf,
              onChanged: (v) => setState(() => Bf = v),
            ),
            HeirInputCard(
              title: "Saudari Kandung (P)",
              subtitle: "Sekandung perempuan",
              value: Sf,
              onChanged: (v) => setState(() => Sf = v),
            ),
            HeirInputCard(
              title: "Saudara Seayah (L)",
              subtitle: "Seayah laki",
              value: Bp,
              onChanged: (v) => setState(() => Bp = v),
            ),
            HeirInputCard(
              title: "Saudari Seayah (P)",
              subtitle: "Seayah perempuan",
              value: Sp,
              onChanged: (v) => setState(() => Sp = v),
            ),
            HeirInputCard(
              title: "Saudara Seibu (L)",
              subtitle: "Seibu laki",
              value: Bm,
              onChanged: (v) => setState(() => Bm = v),
            ),
            HeirInputCard(
              title: "Saudari Seibu (P)",
              subtitle: "Seibu perempuan",
              value: Sm,
              onChanged: (v) => setState(() => Sm = v),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _calculate,
                child: const Text(
                  "Hitung Waris",
                  style: TextStyle(
                    fontFamily: 'PoppinsBold',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_result != null) WarisResultView(result: _result!),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'PoppinsBold',
          fontSize: 16,
          color: Colors.amber[800],
        ),
      ),
    );
  }
}
