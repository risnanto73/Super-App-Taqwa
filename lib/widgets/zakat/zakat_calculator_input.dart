import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class ZakatCalculatorInput extends StatelessWidget {
  final TextEditingController incomeController;
  final TextEditingController expenseController;
  final VoidCallback onCalculate;

  const ZakatCalculatorInput({
    super.key,
    required this.incomeController,
    required this.expenseController,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gaji Per Bulan",
          style: TextStyle(fontFamily: 'PoppinsSemiBold'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          incomeController,
          "Masukkan gaji",
          Icons.monetization_on_outlined,
        ),
        const SizedBox(height: 16),
        const Text(
          "Pengeluaran Pokok",
          style: TextStyle(fontFamily: 'PoppinsSemiBold'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          expenseController,
          "Masukkan pengeluaran",
          Icons.shopping_cart_outlined,
        ),
        const SizedBox(height: 20),
        SizedBox(
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
        ),
      ],
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
}
