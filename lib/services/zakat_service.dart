import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ZakatService {
  static const double fallbackPricePerGram = 2000000.0;
  static const double nisabGoldGrams = 85.0;

  static Future<Map<String, dynamic>> fetchGoldAndNisab() async {
    final prefs = await SharedPreferences.getInstance();
    double? goldPrice;
    double? silverPrice;
    double usdToIdr = 15500.0;
    bool isOffline = false;

    try {
      final exchangeRes = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/USD'),
      );
      if (exchangeRes.statusCode == 200) {
        final exData = json.decode(exchangeRes.body);
        usdToIdr = (exData['rates']?['IDR'] ?? 15500.0).toDouble();
      } else {
        usdToIdr = 15500.0;
      }

      goldPrice = await _fetchMetalPrice(
        'XAU',
        usdToIdr,
        prefs,
        'last_gold_price',
      );
      silverPrice = await _fetchMetalPrice(
        'XAG',
        usdToIdr,
        prefs,
        'last_silver_price',
      );

      if (goldPrice == null || silverPrice == null) {
        isOffline = true;
      } else {
        await prefs.setString('last_update', DateTime.now().toIso8601String());
      }
    } catch (e) {
      isOffline = true;
    }

    // Use cached values if fetch failed
    goldPrice ??= prefs.getDouble('last_gold_price') ?? fallbackPricePerGram;
    silverPrice ??=
        prefs.getDouble('last_silver_price') ?? 15000.0; // Fallback perak

    return {
      'nisabValue':
          nisabGoldGrams * goldPrice, // Default nisab gold for other tabs
      'goldPrice': goldPrice,
      'silverPrice': silverPrice,
      'lastUpdate': prefs.getString('last_update'),
      'isOffline': isOffline,
    };
  }

  static Future<double?> _fetchMetalPrice(
    String symbol,
    double usdToIdr,
    SharedPreferences prefs,
    String cacheKey,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('https://www.goldapi.io/api/$symbol/USD'),
        headers: {
          'x-access-token': 'goldapi-1wwsrsmhk0ch86-io',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final double usdPerGram = (data['price_gram_24k'] ?? 0).toDouble();
        double pricePerGram = usdPerGram * usdToIdr;

        // Basic sanity check
        if (pricePerGram > 1000) {
          await prefs.setDouble(cacheKey, pricePerGram);
          return pricePerGram;
        }
      }
    } catch (_) {}
    return null;
  }

  static Map<String, dynamic> calculateZakat(
    double income,
    double expense,
    double nisabValue,
  ) {
    final double netIncome = (income - expense).clamp(0, double.infinity);
    final double annualIncome = income * 12;
    final double zakatAmount = netIncome * 0.025;
    final bool isAboveNisab = annualIncome >= nisabValue;

    return {'zakatAmount': zakatAmount, 'isAboveNisab': isAboveNisab};
  }

  static Map<String, dynamic> calculatePerdagangan({
    required double modal,
    required double laba,
    required double piutang,
    required double hutang,
    required double kerugian,
    required double nisabValue,
  }) {
    final double netAssets = (modal + laba + piutang) - (hutang + kerugian);
    final double zakatAmount = netAssets.clamp(0, double.infinity) * 0.025;
    final bool isAboveNisab = netAssets >= nisabValue;

    return {'zakatAmount': zakatAmount, 'isAboveNisab': isAboveNisab};
  }

  static Map<String, dynamic> calculateEmasPerak({
    required double totalOwned,
    required double totalUsed,
    required double nisabGram,
  }) {
    final double netWeight = (totalOwned - totalUsed).clamp(0, double.infinity);
    final bool isAboveNisab = totalOwned >= nisabGram;
    // Note: Zakat is usually calculated in value, but image says (Emas/Perak owned - used) * 2.5%
    // This usually means 2.5% of the weight or value. We'll return the weight to be multiplied by price later.
    final double zakatWeight = isAboveNisab ? netWeight * 0.025 : 0;

    return {'zakatWeight': zakatWeight, 'isAboveNisab': isAboveNisab};
  }

  static Map<String, dynamic> calculatePertanian({
    required double harvestKg,
    required bool isIrrigated,
  }) {
    const double nisabKg = 520.0;
    final double rate = isIrrigated ? 0.05 : 0.10;
    final bool isAboveNisab = harvestKg >= nisabKg;
    final double zakatAmountKg = isAboveNisab ? harvestKg * rate : 0;

    return {'zakatAmountKg': zakatAmountKg, 'isAboveNisab': isAboveNisab};
  }

  static Map<String, dynamic> calculateTabungan({
    required double balance,
    required double interest,
    required double nisabValue,
  }) {
    final double netBalance = (balance - interest).clamp(0, double.infinity);
    final double zakatAmount = netBalance * 0.025;
    final bool isAboveNisab = netBalance >= nisabValue;

    return {'zakatAmount': zakatAmount, 'isAboveNisab': isAboveNisab};
  }
}
