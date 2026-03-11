import 'package:flutter/material.dart';

class ZakatPertanianForm extends StatefulWidget {
  final TextEditingController harvestController;
  final Function(bool isIrrigated) onCalculate;

  const ZakatPertanianForm({
    super.key,
    required this.harvestController,
    required this.onCalculate,
  });

  @override
  State<ZakatPertanianForm> createState() => _ZakatPertanianFormState();
}

class _ZakatPertanianFormState extends State<ZakatPertanianForm> {
  bool _isIrrigated = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Hasil Panen (kg)"),
          _buildTextField(
            widget.harvestController,
            "Masukkan berat panen",
            Icons.agriculture,
          ),
          const SizedBox(height: 16),
          const Text(
            "Metode Pengairan",
            style: TextStyle(fontFamily: 'PoppinsSemiBold'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text(
              "Menggunakan Irigasi Berbayar",
              style: TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              _isIrrigated
                  ? "Kadar Zakat 5%"
                  : "Kadar Zakat 10% (Air Hujan/Mata Air)",
              style: const TextStyle(fontSize: 12),
            ),
            value: _isIrrigated,
            onChanged: (val) => setState(() => _isIrrigated = val),
            activeColor: Colors.amber,
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
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixText: 'kg',
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
        onPressed: () => widget.onCalculate(_isIrrigated),
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
