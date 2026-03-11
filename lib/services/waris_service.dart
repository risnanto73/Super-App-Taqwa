import 'package:intl/intl.dart';

class WarisStep {
  final String title;
  final String description;
  final Map<String, dynamic>? data;

  WarisStep({required this.title, required this.description, this.data});

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'data': data,
  };

  factory WarisStep.fromJson(Map<String, dynamic> json) => WarisStep(
    title: json['title'],
    description: json['description'],
    data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
  );
}

class HeirPortion {
  final String name;
  final int num;
  final int den;
  final bool isAshabah;
  final int count;
  int? value; // Initial value from AM
  double? nominal;
  final String? dalil;

  HeirPortion({
    required this.name,
    this.num = 0,
    this.den = 1,
    this.isAshabah = false,
    this.count = 1,
    this.value,
    this.nominal,
    this.dalil,
  });

  String get fractionText => isAshabah ? "Ashabah" : "$num/$den";

  Map<String, dynamic> toJson() => {
    'name': name,
    'num': num,
    'den': den,
    'isAshabah': isAshabah,
    'count': count,
    'value': value,
    'nominal': nominal,
    'dalil': dalil,
  };

  factory HeirPortion.fromJson(Map<String, dynamic> json) => HeirPortion(
    name: json['name'],
    num: json['num'],
    den: json['den'],
    isAshabah: json['isAshabah'],
    count: json['count'],
    value: json['value'],
    nominal: json['nominal']?.toDouble(),
    dalil: json['dalil'],
  );
}

class WarisResult {
  final List<HeirPortion> validHeirs;
  final List<String> blockedHeirs;
  final int initialAM;
  final int finalAM;
  final String? adjustmentType; // 'Aul, Radd, Tashih, None
  final bool isDeceasedMale;
  final double totalWealth;
  final List<WarisStep> steps;
  final DateTime? createdAt;

  WarisResult({
    required this.validHeirs,
    required this.blockedHeirs,
    required this.initialAM,
    required this.finalAM,
    this.adjustmentType,
    required this.isDeceasedMale,
    required this.totalWealth,
    required this.steps,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'validHeirs': validHeirs.map((h) => h.toJson()).toList(),
    'blockedHeirs': blockedHeirs,
    'initialAM': initialAM,
    'finalAM': finalAM,
    'adjustmentType': adjustmentType,
    'isDeceasedMale': isDeceasedMale,
    'totalWealth': totalWealth,
    'steps': steps.map((s) => s.toJson()).toList(),
    'createdAt': createdAt?.toIso8601String(),
  };

  factory WarisResult.fromJson(Map<String, dynamic> json) => WarisResult(
    validHeirs: (json['validHeirs'] as List)
        .map((h) => HeirPortion.fromJson(h))
        .toList(),
    blockedHeirs: List<String>.from(json['blockedHeirs']),
    initialAM: json['initialAM'],
    finalAM: json['finalAM'],
    adjustmentType: json['adjustmentType'],
    isDeceasedMale: json['isDeceasedMale'],
    totalWealth: json['totalWealth'].toDouble(),
    steps: (json['steps'] as List).map((s) => WarisStep.fromJson(s)).toList(),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null,
  );

  String toShareText() {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    final buffer = StringBuffer();
    buffer.writeln(" *HASIL PERHITUNGAN WARIS (FARAIDH)* ");
    buffer.writeln("------------------------------------");
    buffer.writeln(
      "Pewaris: ${isDeceasedMale ? 'Laki-laki (Suami)' : 'Perempuan (Istri)'}",
    );
    buffer.writeln("Total Harta: ${format.format(totalWealth)}");
    buffer.writeln("");
    buffer.writeln(" *RINCIAN AHLI WARIS:* ");
    for (var h in validHeirs) {
      buffer.writeln("• ${h.name}: ${h.fractionText}");
      buffer.writeln("  Bagian: ${format.format(h.nominal ?? 0)}");
    }
    if (blockedHeirs.isNotEmpty) {
      buffer.writeln("");
      buffer.writeln(" *AHLI WARIS TERHALANG (MAHJUB):* ");
      for (var b in blockedHeirs) {
        buffer.writeln("• $b");
      }
    }
    buffer.writeln("");
    buffer.writeln("Ashlul Mas-alah: $initialAM");
    buffer.writeln("Penyesuaian: ${adjustmentType ?? 'Normal'}");
    buffer.writeln("------------------------------------");
    buffer.writeln("Dihitung menggunakan Aplikasi Taqwa");
    return buffer.toString();
  }
}

class WarisService {
  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
  static int _lcm(int a, int b) =>
      (a == 0 || b == 0) ? 0 : (a * b) ~/ _gcd(a, b);

  static WarisResult calculate({
    required bool isDeceasedMale,
    required int H,
    required int W,
    required int S,
    required int D,
    required int GS,
    required int GD,
    required int F,
    required int M,
    required int GF,
    required int GMf,
    required int GMm,
    required int Bf,
    required int Sf,
    required int Bp,
    required int Sp,
    required int Bm,
    required int Sm,
    required double totalWealth,
  }) {
    List<WarisStep> calculationSteps = [];
    List<String> blocked = [];
    Map<String, HeirPortion> portions = {};

    // --- LANGKAH 1 & 2: Identifikasi & Hijab ---
    bool hasSon = S > 0;
    bool hasMaleDesc = S > 0 || GS > 0;
    bool hasDesc = (S + D + GS + GD) > 0;
    bool hasFather = F > 0;
    bool hasMother = M > 0;
    bool hasMultipleSiblings = (Bf + Sf + Bp + Sp + Bm + Sm) >= 2;

    // HIJAB RULES (Blocking)
    // 1. Father blocks Grandfather and Paternal Grandmother
    if (hasFather) {
      if (GF > 0) blocked.add("Kakek (Terhalang Ayah)");
      if (GMf > 0) blocked.add("Nenek Ayah (Terhalang Ayah)");
    }
    // 2. Mother blocks all Grandmothers
    if (hasMother) {
      if (GMf > 0 && !blocked.any((s) => s.contains("Nenek Ayah"))) {
        blocked.add("Nenek Ayah (Terhalang Ibu)");
      }
      if (GMm > 0) blocked.add("Nenek Ibu (Terhalang Ibu)");
    }
    // 3. Male Descendant blocks Siblings (except Seibu which is blocked by any desc)
    if (hasMaleDesc) {
      if (Bf > 0) blocked.add("Saudara Kandung (Terhalang Anak/Cucu Laki)");
      if (Sf > 0) blocked.add("Saudari Kandung (Terhalang Anak/Cucu Laki)");
      if (Bp > 0) blocked.add("Saudara Seayah (Terhalang Anak/Cucu Laki)");
      if (Sp > 0) blocked.add("Saudari Seayah (Terhalang Anak/Cucu Laki)");
    }
    // 4. Father blocks all Siblings
    if (hasFather) {
      if (Bf > 0 && !blocked.any((s) => s.contains("Saudara Kandung")))
        blocked.add("Saudara Kandung (Terhalang Ayah)");
      if (Sf > 0 && !blocked.any((s) => s.contains("Saudari Kandung")))
        blocked.add("Saudari Kandung (Terhalang Ayah)");
      if (Bp > 0 && !blocked.any((s) => s.contains("Saudara Seayah")))
        blocked.add("Saudara Seayah (Terhalang Ayah)");
      if (Sp > 0 && !blocked.any((s) => s.contains("Saudari Seayah")))
        blocked.add("Saudari Seayah (Terhalang Ayah)");
      if (Bm > 0) blocked.add("Saudara Seibu (Terhalang Ayah)");
      if (Sm > 0) blocked.add("Saudari Seibu (Terhalang Ayah)");
    }
    // 5. Descendants block Siblings Seibu
    if (hasDesc) {
      if (Bm > 0 && !blocked.any((s) => s.contains("Saudara Seibu")))
        blocked.add("Saudara Seibu (Terhalang Keturunan)");
      if (Sm > 0 && !blocked.any((s) => s.contains("Saudari Seibu")))
        blocked.add("Saudari Seibu (Terhalang Keturunan)");
    }
    // 6. Full Brother/Sister (multiple or ashabah) blocks Seayah
    if (Bf > 0) {
      if (Bp > 0) blocked.add("Saudara Seayah (Terhalang Sdr Kandung Laki)");
      if (Sp > 0) blocked.add("Saudari Seayah (Terhalang Sdr Kandung Laki)");
    }

    // --- Tentukan Furudh ---
    const qSpouse12 = "QS. An-Nisa: 12 (Bagian pasangan Suami/Istri)";
    const qChildren11 = "QS. An-Nisa: 11 (Bagian Anak & Orang Tua)";
    const qSiblings12 = "QS. An-Nisa: 12 (Bagian Saudara Seibu)";
    const qSiblings176 = "QS. An-Nisa: 176 (Bagian Saudara Kandung/Seayah)";

    // Spouse
    if (H > 0) {
      portions['Suami'] = HeirPortion(
        name: 'Suami',
        num: hasDesc ? 1 : 1,
        den: hasDesc ? 4 : 2,
        dalil: qSpouse12,
      );
    }
    if (W > 0) {
      portions['Istri'] = HeirPortion(
        name: 'Istri',
        num: hasDesc ? 1 : 1,
        den: hasDesc ? 8 : 4,
        count: W,
        dalil: qSpouse12,
      );
    }

    // Parents
    if (M > 0) {
      portions['Ibu'] = HeirPortion(
        name: 'Ibu',
        num: (hasDesc || hasMultipleSiblings) ? 1 : 1,
        den: (hasDesc || hasMultipleSiblings) ? 6 : 3,
        dalil: qChildren11,
      );
    }
    if (F > 0) {
      if (hasMaleDesc) {
        portions['Ayah'] = HeirPortion(
          name: 'Ayah',
          num: 1,
          den: 6,
          dalil: qChildren11,
        );
      } else if (D > 0 || GD > 0) {
        // 1/6 + Sisa (but for calculation simplicity, we treat it as 1/6 here and will get residue later if ashabah)
        portions['Ayah'] = HeirPortion(
          name: 'Ayah',
          num: 1,
          den: 6,
          isAshabah: true, // Marker to indicate it can take residue
          dalil: qChildren11,
        );
      } else {
        portions['Ayah'] = HeirPortion(
          name: 'Ayah',
          isAshabah: true,
          dalil: qChildren11,
        );
      }
    }

    // Grandparents (if not blocked)
    if (GF > 0 && !blocked.any((s) => s.contains("Kakek"))) {
      if (hasMaleDesc) {
        portions['Kakek'] = HeirPortion(name: 'Kakek', num: 1, den: 6);
      } else {
        portions['Kakek'] = HeirPortion(name: 'Kakek', isAshabah: true);
      }
    }
    int gmCount = 0;
    if (GMf > 0 && !blocked.any((s) => s.contains("Nenek Ayah"))) gmCount++;
    if (GMm > 0 && !blocked.any((s) => s.contains("Nenek Ibu"))) gmCount++;
    if (gmCount > 0) {
      portions['Nenek'] = HeirPortion(
        name: 'Nenek',
        num: 1,
        den: 6,
        count: gmCount,
      );
    }

    // Descendants
    if (S > 0) {
      // 1. If there's a son, he and daughters (if any) are Ashabah. Grandchildren are blocked.
      portions['Anak Laki-laki'] = HeirPortion(
        name: 'Anak Laki-laki',
        isAshabah: true,
        count: S,
        dalil: qChildren11,
      );
      if (D > 0) {
        portions['Anak Perempuan'] = HeirPortion(
          name: 'Anak Perempuan',
          isAshabah: true,
          count: D,
          dalil: qChildren11,
        );
      }
      if (GS > 0) blocked.add("Cucu Laki-laki (Terhalang Anak Laki)");
      if (GD > 0) blocked.add("Cucu Perempuan (Terhalang Anak Laki)");
    } else {
      // 2. No Son. Handle Daughters and Grandchildren.
      if (D > 0) {
        if (D == 1) {
          portions['Anak Perempuan'] = HeirPortion(
            name: 'Anak Perempuan',
            num: 1,
            den: 2,
            count: 1,
            dalil: qChildren11,
          );
          // With 1 Daughter, Granddaughter (GD) can get 1/6 (Takmilah ath-thuluthain) if no Grandson (GS)
          if (GS > 0) {
            portions['Cucu Laki-laki'] = HeirPortion(
              name: 'Cucu Laki-laki',
              isAshabah: true,
              count: GS,
            );
            if (GD > 0)
              portions['Cucu Perempuan'] = HeirPortion(
                name: 'Cucu Perempuan',
                isAshabah: true,
                count: GD,
              );
          } else if (GD > 0) {
            portions['Cucu Perempuan'] = HeirPortion(
              name: 'Cucu Perempuan',
              num: 1,
              den: 6,
              count: GD,
            );
          }
        } else {
          // Multiple Daughters (D >= 2) take 2/3
          portions['Anak Perempuan'] = HeirPortion(
            name: 'Anak Perempuan',
            num: 2,
            den: 3,
            count: D,
            dalil: qChildren11,
          );
          // Granddaughters are blocked unless there's a Grandson (GS) to make them Ashabah
          if (GS > 0) {
            portions['Cucu Laki-laki'] = HeirPortion(
              name: 'Cucu Laki-laki',
              isAshabah: true,
              count: GS,
            );
            if (GD > 0)
              portions['Cucu Perempuan'] = HeirPortion(
                name: 'Cucu Perempuan',
                isAshabah: true,
                count: GD,
              );
          } else if (GD > 0) {
            blocked.add("Cucu Perempuan (Terhalang >1 Anak Peremp)");
          }
        }
      } else if (GS > 0 || GD > 0) {
        // 3. No Children. Grandchildren inherit like children.
        if (GS > 0) {
          portions['Cucu Laki-laki'] = HeirPortion(
            name: 'Cucu Laki-laki',
            isAshabah: true,
            count: GS,
          );
          if (GD > 0)
            portions['Cucu Perempuan'] = HeirPortion(
              name: 'Cucu Perempuan',
              isAshabah: true,
              count: GD,
            );
        } else {
          portions['Cucu Perempuan'] = HeirPortion(
            name: 'Cucu Perempuan',
            num: GD == 1 ? 1 : 2,
            den: GD == 1 ? 2 : 3,
            count: GD,
          );
        }
      }
    }

    // Siblings
    // 1. Siblings Seibu (Bm/Sm) - Hijab already handled
    if ((Bm + Sm) > 0 && !blocked.any((s) => s.contains("Seibu"))) {
      portions['Saudara Seibu'] = HeirPortion(
        name: 'Saudara Seibu',
        num: (Bm + Sm) == 1 ? 1 : 1,
        den: (Bm + Sm) == 1 ? 6 : 3,
        count: Bm + Sm,
        dalil: qSiblings12,
      );
    }
    // 2. Siblings Kandung (Bf/Sf) - Hijab already handled
    if ((Bf + Sf) > 0 && !blocked.any((s) => s.contains("Kandung"))) {
      if (Bf > 0) {
        portions['Saudara Kandung'] = HeirPortion(
          name: 'Saudara Kandung',
          isAshabah: true,
          count: Bf,
          dalil: qSiblings176,
        );
        if (Sf > 0)
          portions['Saudari Kandung'] = HeirPortion(
            name: 'Saudari Kandung',
            isAshabah: true,
            count: Sf,
            dalil: qSiblings176,
          );
      } else {
        // Only sisters, if there are female descendants (D/GD), they become Ashabah Ma'al Ghair
        if (D > 0 || GD > 0) {
          portions['Saudari Kandung'] = HeirPortion(
            name: 'Saudari Kandung',
            isAshabah: true,
            count: Sf,
            dalil: qSiblings176,
          );
        } else {
          portions['Saudari Kandung'] = HeirPortion(
            name: 'Saudari Kandung',
            num: Sf == 1 ? 1 : 2,
            den: Sf == 1 ? 2 : 3,
            count: Sf,
            dalil: qSiblings176,
          );
        }
      }
    }
    // 3. Siblings Seayah (Bp/Sp) - Hijab already handled
    if ((Bp + Sp) > 0 && !blocked.any((s) => s.contains("Seayah"))) {
      if (Bp > 0) {
        portions['Saudara Seayah'] = HeirPortion(
          name: 'Saudara Seayah',
          isAshabah: true,
          count: Bp,
          dalil: qSiblings176,
        );
        if (Sp > 0)
          portions['Saudari Seayah'] = HeirPortion(
            name: 'Saudari Seayah',
            isAshabah: true,
            count: Sp,
            dalil: qSiblings176,
          );
      } else {
        // Only sisters seayah
        if (D > 0 ||
            GD > 0 ||
            (Sf > 0 &&
                portions.containsKey('Saudari Kandung') &&
                portions['Saudari Kandung']!.isAshabah)) {
          portions['Saudari Seayah'] = HeirPortion(
            name: 'Saudari Seayah',
            isAshabah: true,
            count: Sp,
            dalil: qSiblings176,
          );
        } else {
          // If there is 1 full sister, sister seayah gets 1/6 (complementing 2/3)
          if (Sf == 1) {
            portions['Saudari Seayah'] = HeirPortion(
              name: 'Saudari Seayah',
              num: 1,
              den: 6,
              count: Sp,
              dalil: qSiblings176,
            );
          } else {
            portions['Saudari Seayah'] = HeirPortion(
              name: 'Saudari Seayah',
              num: Sp == 1 ? 1 : 2,
              den: Sp == 1 ? 2 : 3,
              count: Sp,
              dalil: qSiblings176,
            );
          }
        }
      }
    }

    // --- LANGKAH 3: Ashlul Mas-alah (AM) ---
    int am = 1;
    portions.values
        .where((p) => !p.isAshabah || (p.num > 0)) // Fixed portions
        .forEach((p) => am = _lcm(am, p.den));

    calculationSteps.add(
      WarisStep(
        title: "Langkah 1 & 2: Identifikasi & Furudh",
        description:
            "Menentukan ahli waris yang sah dan bagian tetap (Furudh) mereka.",
      ),
    );

    // --- LANGKAH 4: Nilai Bagian ---
    int sumFurudhValues = 0;
    portions.forEach((k, p) {
      if (p.num > 0) {
        p.value = (am * p.num) ~/ p.den;
        sumFurudhValues += p.value!;
      }
    });

    // --- LANGKAH 5: Kondisi Khusus ---
    String? adjType;
    int residue = am - sumFurudhValues;

    if (sumFurudhValues > am) {
      adjType = "Aul";
      am = sumFurudhValues; // AM naik
      residue = 0;
      // All ashabah get 0
      portions.values
          .where((p) => p.isAshabah && p.num == 0)
          .forEach((p) => p.value = 0);
    } else if (residue > 0) {
      // Cek Ashabah (Prioritas: Anak > Ayah > Kakek > Saudara)
      var ashabahHeirs = portions.values.where((p) => p.isAshabah).toList();
      if (ashabahHeirs.isNotEmpty) {
        adjType = "Ashabah";

        // Handle specific ratios
        if (portions.containsKey('Anak Laki-laki') &&
            portions.containsKey('Anak Perempuan')) {
          int totalHeads = (S * 2) + D;
          if (residue % totalHeads != 0) {
            int factor = totalHeads ~/ _gcd(residue, totalHeads);
            am *= factor;
            portions.forEach((k, p) {
              if (p.value != null) p.value = p.value! * factor;
            });
            residue *= factor;
            adjType = "Tashih";
          }
          portions['Anak Laki-laki']!.value = (residue * (S * 2)) ~/ totalHeads;
          portions['Anak Perempuan']!.value = (residue * D) ~/ totalHeads;
        } else if (portions.containsKey('Saudara Kandung') &&
            portions.containsKey('Saudari Kandung')) {
          int totalHeads = (Bf * 2) + Sf;
          portions['Saudara Kandung']!.value =
              (residue * (Bf * 2)) ~/ totalHeads;
          portions['Saudari Kandung']!.value = (residue * Sf) ~/ totalHeads;
        } else if (portions.containsKey('Saudara Seayah') &&
            portions.containsKey('Saudari Seayah')) {
          int totalHeads = (Bp * 2) + Sp;
          portions['Saudara Seayah']!.value =
              (residue * (Bp * 2)) ~/ totalHeads;
          portions['Saudari Seayah']!.value = (residue * Sp) ~/ totalHeads;
        } else if (portions.containsKey('Cucu Laki-laki') &&
            portions.containsKey('Cucu Perempuan')) {
          int totalHeads = (GS * 2) + GD;
          if (residue % totalHeads != 0) {
            int factor = totalHeads ~/ _gcd(residue, totalHeads);
            am *= factor;
            portions.forEach((k, p) {
              if (p.value != null) p.value = p.value! * factor;
            });
            residue *= factor;
            adjType = "Tashih";
          }
          portions['Cucu Laki-laki']!.value =
              (residue * (GS * 2)) ~/ totalHeads;
          portions['Cucu Perempuan']!.value = (residue * GD) ~/ totalHeads;
        } else {
          // Normal residue assignment to the highest priority ashabah
          ashabahHeirs.first.value = residue;
        }
      } else {
        // Radd (Simplified)
        adjType = "Radd";
        am = sumFurudhValues;
      }
    }

    calculationSteps.add(
      WarisStep(
        title: "Langkah 3 & 4: Ashlul Mas-alah",
        description: "KPK dari penyebut adalah $am.",
      ),
    );

    // Final Nominal
    List<HeirPortion> finalHeirs = portions.values.toList();
    for (var p in finalHeirs) {
      double totalGroupNominal = (p.value ?? 0) / am * totalWealth;
      p.nominal = totalGroupNominal;
    }

    return WarisResult(
      validHeirs: finalHeirs,
      blockedHeirs: blocked,
      initialAM: am,
      finalAM: am,
      adjustmentType: adjType,
      isDeceasedMale: isDeceasedMale,
      totalWealth: totalWealth,
      steps: calculationSteps,
    );
  }
}
