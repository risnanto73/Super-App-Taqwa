import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZakatPage extends StatefulWidget {
  const ZakatPage({Key? key}) : super(key: key);

  @override
  State<ZakatPage> createState() => _ZakatPageState();
}

class _ZakatPageState extends State<ZakatPage> {
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _expenseController = TextEditingController();

  double? _zakatAmount;
  double? _nisabValue;
  bool _isAboveNisab = false;
  bool _isLoading = false;
  List<double> _zakatHistory = [];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchGoldPrice();
  }

  /// Ambil harga emas dari API, simpan ke cache, dan gunakan fallback saat offline
  Future<void> _fetchGoldPrice() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    const fallbackPricePerGram = 1000000.0; // Rp 1 juta per gram
    double? pricePerGram;
    double? usdToIdr;

    try {
      print("🌐 Mengambil harga emas dan kurs USD → IDR...");

      // 1️⃣ Ambil kurs USD ke IDR (agar bisa konversi harga emas jika perlu)
      final exchangeRes = await http.get(
        Uri.parse('https://api.exchangerate.host/latest?base=USD&symbols=IDR'),
      );

      if (exchangeRes.statusCode == 200) {
        final exData = json.decode(exchangeRes.body);
        usdToIdr = (exData['rates']?['IDR'] ?? 15000).toDouble();
        print("💵 Kurs USD → IDR: $usdToIdr");
      } else {
        usdToIdr = 15000; // fallback kurs
        print("⚠️ Gagal ambil kurs, pakai fallback: $usdToIdr");
      }

      // 2️⃣ Ambil harga emas (XAU/USD)
      final goldRes = await http.get(
        Uri.parse('https://api.goldapi.io/api/XAU/USD'),
        headers: {
          'x-access-token':
              'goldapi-9a6m03cpsa6bd-io', // ganti token kamu sendiri
        },
      );

      if (goldRes.statusCode == 200) {
        final goldData = json.decode(goldRes.body);

        // Ada beberapa field berbeda tergantung API
        double rawPriceUsd = 0;
        if (goldData.containsKey('price_gram_24k')) {
          rawPriceUsd = (goldData['price_gram_24k'] ?? 0).toDouble();
        } else if (goldData.containsKey('price')) {
          rawPriceUsd = (goldData['price'] ?? 0).toDouble();
        }

        print("🪙 Harga emas (USD per gram): $rawPriceUsd");

        // 3️⃣ Konversi USD → IDR
        pricePerGram = rawPriceUsd * (usdToIdr ?? 15000);
        print("💰 Harga emas (IDR per gram): $pricePerGram");

        // 4️⃣ Validasi harga agar realistis
        if (pricePerGram! < 500000 || pricePerGram > 2000000) {
          print(
            "⚠️ Harga emas tidak realistis ($pricePerGram). Pakai fallback Rp $fallbackPricePerGram",
          );
          pricePerGram = fallbackPricePerGram;
        }

        // 5️⃣ Simpan ke cache
        await prefs.setDouble('last_gold_price', pricePerGram);
        await prefs.setString('last_update', DateTime.now().toIso8601String());
        print("💾 Harga emas tersimpan ke cache: $pricePerGram");
      } else {
        print("⚠️ Gagal ambil API goldapi.io (status: ${goldRes.statusCode})");
        pricePerGram = prefs.getDouble('last_gold_price');
        if (pricePerGram != null) {
          print("📦 Gunakan harga dari cache: $pricePerGram");
        }
      }
    } catch (e) {
      print("📴 Gagal terhubung ke API, aktifkan mode offline: $e");
      pricePerGram = prefs.getDouble('last_gold_price');
      if (pricePerGram != null) {
        print("📦 Harga emas diambil dari cache: $pricePerGram");
      } else {
        print("⚠️ Cache kosong, pakai fallback Rp $fallbackPricePerGram");
        pricePerGram = fallbackPricePerGram;
      }
    }

    // 6️⃣ Hitung nilai nisab
    setState(() {
      _nisabValue = 85 * (pricePerGram ?? fallbackPricePerGram);
      _isLoading = false;
    });

    print("✅ Nisab final (85 gram): ${_nisabValue}");
  }

  void _calculateZakat() {
    // --- Ambil teks input ---
    String incomeText = _incomeController.text.trim();
    String expenseText = _expenseController.text.trim();

    // --- Bersihkan input ke format numerik ---
    String cleanIncome = toNumericString(incomeText, allowPeriod: false);
    String cleanExpense = toNumericString(expenseText, allowPeriod: false);

    // --- Hapus sisa ".00" kalau ada ---
    cleanIncome = cleanIncome.replaceAll(RegExp(r'\.00$'), '');
    cleanExpense = cleanExpense.replaceAll(RegExp(r'\.00$'), '');

    // --- Cek validitas input ---
    if (cleanIncome.isEmpty || cleanExpense.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi semua kolom dengan angka yang valid.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // --- Parsing ke double ---
    final double? income = double.tryParse(cleanIncome);
    final double? expenses = double.tryParse(cleanExpense);

    if (income == null || expenses == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Angka tidak valid. Pastikan format tanpa huruf.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // --- Debug log (bisa hapus kalau sudah stabil) ---
    print(
      "🧾 Input Mentah: income='${_incomeController.text}', expense='${_expenseController.text}'",
    );
    print("💰 Parsed Income: $income");
    print("💸 Parsed Expense: $expenses");
    print("💎 Nisab: $_nisabValue");

    // --- Hitung zakat ---
    final double netIncome = (income - expenses).clamp(0, double.infinity);
    final double annualIncome = income * 12;
    final double zakat = netIncome * 0.025;

    setState(() {
      _zakatAmount = zakat;
      _isAboveNisab = _nisabValue != null && annualIncome >= _nisabValue!;
      _zakatHistory.add(zakat);
      if (_zakatHistory.length > 6) _zakatHistory.removeAt(0);
    });

    // --- Debug hasil ---
    print("📊 Net Income: $netIncome");
    print("📅 Annual Income: $annualIncome");
    print("📈 Zakat (2.5%): $_zakatAmount");
    print("⚖️ Wajib Zakat: $_isAboveNisab");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.amber,
        elevation: 0,
        title: const Text(
          "Zakat Penghasilan",
          style: TextStyle(fontFamily: 'PoppinsSemiBold', color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER INFO NISAB
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _nisabValue != null
                          ? "💰 Nisab saat ini (85 gram emas): ${_currencyFormat.format(_nisabValue)} per tahun."
                          : "Mengambil data harga emas...",
                      style: const TextStyle(
                        fontFamily: 'PoppinsRegular',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    "Harga emas per gram: ${_currencyFormat.format(_nisabValue! / 85)}",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),

                  // INPUT GAJI
                  const Text(
                    "Gaji Per Bulan",
                    style: TextStyle(
                      fontFamily: 'PoppinsSemiBold',
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      CurrencyInputFormatter(
                        leadingSymbol: '', // biar tidak muncul Rp dua kali
                        useSymbolPadding: false,
                        mantissaLength: 0, // ❗ tidak pakai desimal .00
                        thousandSeparator: ThousandSeparator.Period,
                      ),
                    ],
                    decoration: InputDecoration(
                      hintText: "Masukkan gaji per bulan",
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // INPUT PENGELUARAN
                  const Text(
                    "Pengeluaran Pokok Per Bulan",
                    style: TextStyle(
                      fontFamily: 'PoppinsSemiBold',
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _expenseController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      hintText: "Masukkan pengeluaran pokok",
                      prefixIcon: const Icon(Icons.shopping_cart_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TOMBOL HITUNG
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
                      onPressed: _calculateZakat,
                      icon: const Icon(Icons.calculate, color: Colors.white),
                      label: const Text(
                        "Hitung Zakat",
                        style: TextStyle(
                          fontFamily: 'PoppinsBold',
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // HASIL
                  if (_zakatAmount != null)
                    Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              _isAboveNisab
                                  ? "✅ Anda WAJIB membayar zakat penghasilan."
                                  : "ℹ️ Anda BELUM mencapai nisab zakat.",
                              style: TextStyle(
                                fontFamily: 'PoppinsSemiBold',
                                color: _isAboveNisab
                                    ? Colors.green
                                    : Colors.redAccent,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currencyFormat.format(_zakatAmount),
                              style: const TextStyle(
                                fontFamily: 'PoppinsBold',
                                fontSize: 28,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // GRAFIK
                  if (_zakatHistory.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "📊 Riwayat Zakat Bulanan",
                            style: TextStyle(
                              fontFamily: 'PoppinsSemiBold',
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 200),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          "Bln ${(value + 1).toInt()}",
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontFamily: 'PoppinsRegular',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                barGroups: _zakatHistory
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => BarChartGroupData(
                                        x: entry.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: entry.value / 1000000,
                                            color: Colors.amber,
                                            width: 16,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
