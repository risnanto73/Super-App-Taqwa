import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class ZakatPerdaganganForm extends StatelessWidget {
  final TextEditingController modalController;
  final TextEditingController labaController;
  final TextEditingController piutangController;
  final TextEditingController hutangController;
  final TextEditingController kerugianController;
  final VoidCallback onCalculate;

  const ZakatPerdaganganForm({
    super.key,
    required this.modalController,
    required this.labaController,
    required this.piutangController,
    required this.hutangController,
    required this.kerugianController,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Modal yang Diputar"),
          _buildTextField(
            modalController,
            "Masukkan modal",
            Icons.business_center_outlined,
          ),
          const SizedBox(height: 12),
          _buildLabel("Keuntungan (Laba)"),
          _buildTextField(labaController, "Masukkan laba", Icons.trending_up),
          const SizedBox(height: 12),
          _buildLabel("Piutang Lancar"),
          _buildTextField(
            piutangController,
            "Masukkan piutang",
            Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 12),
          _buildLabel("Hutang Jatuh Tempo"),
          _buildTextField(
            hutangController,
            "Masukkan hutang",
            Icons.money_off_outlined,
          ),
          const SizedBox(height: 12),
          _buildLabel("Kerugian (Jika ada)"),
          _buildTextField(
            kerugianController,
            "Masukkan kerugian",
            Icons.report_problem_outlined,
          ),
          const SizedBox(height: 20),
          _buildCalculateButton(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontFamily: 'PoppinsSemiBold')),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        CurrencyInputFormatter(
          leadingSymbol: '',
          thousandSeparator: ThousandSeparator.Period,
          mantissaLength: 0,
        ),
      ],
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        prefixText: 'Rp ',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onCalculate,
        icon: const Icon(Icons.calculate, color: Colors.white),
        label: const Text(
          "Hitung Zakat",
          style: TextStyle(
            fontFamily: 'PoppinsBold',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
