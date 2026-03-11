import 'package:flutter/material.dart';
import '../../model/quran_models.dart';

class QuranDetailHeader extends StatelessWidget {
  final Surat? surat;
  const QuranDetailHeader({super.key, required this.surat});

  @override
  Widget build(BuildContext context) {
    if (surat == null) return const SizedBox.shrink();

    return Column(
      children: [
        Text(
          surat!.nama,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'ScheherazadeNew', fontSize: 32),
        ),
        Text(
          "${surat!.namaLatin} • ${surat!.arti}\n${surat!.tempatTurun} • ${surat!.jumlahAyat} Ayat",
          textAlign: TextAlign.center,
        ),
        const Divider(height: 24),
      ],
    );
  }
}
