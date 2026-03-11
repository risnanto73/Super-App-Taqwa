import 'package:flutter/material.dart';

class SholatCityList extends StatelessWidget {
  final List<Map<String, String>> cityList;
  final Function(String code, String name) onCitySelected;

  const SholatCityList({
    super.key,
    required this.cityList,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (cityList.isEmpty) {
      return const Center(child: Text("Kota tidak ditemukan."));
    }

    return ListView.builder(
      itemCount: cityList.length,
      itemBuilder: (context, index) {
        final city = cityList[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(
              Icons.location_on_outlined,
              color: Colors.amber,
            ),
            title: Text(
              city["name"]!,
              style: const TextStyle(fontFamily: 'PoppinsMedium'),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => onCitySelected(city["code"]!, city["name"]!),
          ),
        );
      },
    );
  }
}
