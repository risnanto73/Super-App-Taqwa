import 'package:flutter/material.dart';

class ZakatEmasPerakForm extends StatefulWidget {
  final TextEditingController ownedController;
  final TextEditingController usedController;
  final Function(bool isGold) onCalculate;

  const ZakatEmasPerakForm({
    super.key,
    required this.ownedController,
    required this.usedController,
    required this.onCalculate,
  });

  @override
  State<ZakatEmasPerakForm> createState() => _ZakatEmasPerakFormState();
}

class _ZakatEmasPerakFormState extends State<ZakatEmasPerakForm> {
  String _selectedMetal = "Emas";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Jenis Logam",
            style: TextStyle(fontFamily: 'PoppinsSemiBold'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMetalOption("Emas"),
              const SizedBox(width: 12),
              _buildMetalOption("Perak"),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabel("Total Berat yang Dimiliki (gram)"),
          _buildTextField(
            widget.ownedController,
            "Masukkan berat total",
            Icons.monitor_weight_outlined,
          ),
          const SizedBox(height: 12),
          _buildLabel("Berat yang Dipakai (gram)"),
          _buildTextField(
            widget.usedController,
            "Masukkan berat dipakai",
            Icons.accessibility_new_outlined,
          ),
          const SizedBox(height: 20),
          _buildCalculateButton(),
        ],
      ),
    );
  }

  Widget _buildMetalOption(String metal) {
    bool isSelected = _selectedMetal == metal;
    return ChoiceChip(
      label: Text(metal),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedMetal = metal);
      },
      selectedColor: Colors.amber,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontFamily: 'PoppinsSemiBold',
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
        suffixText: 'gram',
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
        onPressed: () => widget.onCalculate(_selectedMetal == "Emas"),
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
