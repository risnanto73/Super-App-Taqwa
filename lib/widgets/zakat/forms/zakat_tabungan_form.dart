import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class ZakatTabunganForm extends StatelessWidget {
  final TextEditingController balanceController;
  final TextEditingController interestController;
  final VoidCallback onCalculate;

  const ZakatTabunganForm({
    super.key,
    required this.balanceController,
    required this.interestController,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Saldo Akhir"),
          _buildTextField(
            balanceController,
            "Masukkan saldo total",
            Icons.account_balance,
          ),
          const SizedBox(height: 12),
          _buildLabel("Bunga* (Jika ada)"),
          _buildTextField(
            interestController,
            "Masukkan bunga bank",
            Icons.money_off,
          ),
          const SizedBox(height: 8),
          const Text(
            "*Bunga bank konvensional harus dikurangi dari saldo total.",
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
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
