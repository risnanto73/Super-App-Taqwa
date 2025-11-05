// ================================================================
// 🕌 ZAKAT PAGE — versi teaching-friendly
// Dibuat untuk menampilkan perhitungan zakat penghasilan
// berdasarkan harga emas dunia (GoldAPI) & kurs USD/IDR (OpenERAPI)
// ================================================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔷 Kelas utama halaman zakat
/// Mewarisi `StatefulWidget` agar bisa memperbarui UI secara dinamis
class ZakatPage extends StatefulWidget {
  const ZakatPage({Key? key}) : super(key: key);

  @override
  State<ZakatPage> createState() => _ZakatPageState();
}

/// 🔷 State untuk menyimpan data dan logika utama
class _ZakatPageState extends State<ZakatPage> {
  // ---------------------------------------------------------------
  // 🔷 Controller untuk input user
  // ---------------------------------------------------------------
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _expenseController = TextEditingController();

  // ---------------------------------------------------------------
  // 🔷 Variabel utama logika zakat
  // ---------------------------------------------------------------
  double? _zakatAmount;
  double? _nisabValue;
  bool _isAboveNisab = false;
  bool _isLoading = false;
  List<double> _zakatHistory = [];

  // ---------------------------------------------------------------
  // 🔷 Variabel untuk status dan cache
  // ---------------------------------------------------------------
  String? _lastUpdate; // waktu update terakhir dari API
  bool _isOffline = false; // apakah sedang pakai cache

  // 🔷 Formatter untuk mata uang Rupiah (tanpa desimal)
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // ---------------------------------------------------------------
  // 🔷 Lifecycle method: dijalankan sekali saat halaman dimuat
  // ---------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _fetchGoldPrice(); // ambil data harga emas dan kurs
  }

  // ================================================================
  // [1] 🔷 Ambil data harga emas dari GoldAPI + kurs USD/IDR
  // ================================================================
  Future<void> _fetchGoldPrice() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    const fallbackPricePerGram = 2000000.0; // fallback realistis (Rp 2 jt/gram)
    double? pricePerGram;
    double? usdToIdr;

    try {
      print("🌐 [LOG] Mengambil harga emas & kurs USD→IDR...");

      // -------------------------------------------------------------
      // [1.1] Ambil kurs USD → IDR dari open.er-api.com
      // -------------------------------------------------------------
      final exchangeRes = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/USD'),
      );

      if (exchangeRes.statusCode == 200) {
        final exData = json.decode(exchangeRes.body);
        usdToIdr = (exData['rates']?['IDR'] ?? 15000).toDouble();
        print("💵 Kurs USD → IDR: Rp ${usdToIdr?.toStringAsFixed(2)}");
      } else {
        usdToIdr = 15000;
        print("⚠️ Gagal ambil kurs, fallback Rp $usdToIdr");
      }

      // -------------------------------------------------------------
      // [1.2] Ambil harga emas per gram 24K dari GoldAPI.io
      // -------------------------------------------------------------
      final goldRes = await http.get(
        Uri.parse('https://www.goldapi.io/api/XAU/USD'),
        headers: {
          'x-access-token': 'goldapi-1wwsrsmhk0ch86-io',
          'Content-Type': 'application/json',
        },
      );

      if (goldRes.statusCode == 200) {
        final goldData = json.decode(goldRes.body);
        final double usdPerGram = (goldData['price_gram_24k'] ?? 0).toDouble();
        print("🪙 Harga emas (USD/gram 24K): $usdPerGram");

        // 🔹 Konversi ke Rupiah
        pricePerGram = usdPerGram * (usdToIdr ?? 15000);
        print("💰 Harga emas (IDR/gram): Rp ${pricePerGram?.toStringAsFixed(0)}");

        // 🔹 Validasi harga agar realistis
        if (pricePerGram! < 1800000 || pricePerGram > 2600000) {
          print("⚠️ Harga emas tidak realistis ($pricePerGram). Gunakan fallback.");
          pricePerGram = fallbackPricePerGram;
        }

        // 🔹 Simpan hasil ke cache
        await prefs.setDouble('last_gold_price', pricePerGram);
        await prefs.setString('last_update', DateTime.now().toIso8601String());
        _isOffline = false;
      } else {
        // 🔹 Fallback ke cache
        pricePerGram = prefs.getDouble('last_gold_price') ?? fallbackPricePerGram;
        _isOffline = true;
      }
    } catch (e) {
      // 🔹 Jika tidak konek API
      print("📴 Tidak bisa konek API: $e");
      pricePerGram = prefs.getDouble('last_gold_price') ?? fallbackPricePerGram;
      _isOffline = true;
    }

    // -------------------------------------------------------------
    // [1.3] Hitung nilai nisab (85 gram emas)
    // -------------------------------------------------------------
    setState(() {
      _nisabValue = 85 * (pricePerGram ?? fallbackPricePerGram);
      _lastUpdate = prefs.getString('last_update');
      _isLoading = false;
    });

    print("✅ Nisab final (85 gram): Rp ${_nisabValue?.toStringAsFixed(0)}");
  }

  // ================================================================
  // [2] 🔷 Logika perhitungan zakat penghasilan
  // ================================================================
  void _calculateZakat() {
    /// Langkah-langkah logika:
    /// 1️⃣ Ambil input gaji & pengeluaran
    /// 2️⃣ Bersihkan format (hilangkan titik, koma, .00)
    /// 3️⃣ Validasi input
    /// 4️⃣ Hitung zakat (2.5% dari penghasilan bersih)
    /// 5️⃣ Bandingkan dengan nisab untuk menentukan wajib/tidak

    String incomeText = _incomeController.text.trim();
    String expenseText = _expenseController.text.trim();

    String cleanIncome = toNumericString(incomeText, allowPeriod: false);
    String cleanExpense = toNumericString(expenseText, allowPeriod: false);

    cleanIncome = cleanIncome.replaceAll(RegExp(r'\.00$'), '');
    cleanExpense = cleanExpense.replaceAll(RegExp(r'\.00$'), '');

    if (cleanIncome.isEmpty || cleanExpense.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi semua kolom dengan angka yang valid.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

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

    final double netIncome = (income - expenses).clamp(0, double.infinity);
    final double annualIncome = income * 12;
    final double zakat = netIncome * 0.025;

    setState(() {
      _zakatAmount = zakat;
      _isAboveNisab = _nisabValue != null && annualIncome >= _nisabValue!;
      _zakatHistory.add(zakat);
      if (_zakatHistory.length > 6) _zakatHistory.removeAt(0);
    });

    print("📊 Net Income: $netIncome | Annual: $annualIncome | Zakat: $zakat");
  }

  // ================================================================
  // [3] 🔷 UI utama halaman zakat
  // ================================================================
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

      /// 🔷 BODY — berisi seluruh konten zakat
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ======================================================
                  // [3.1] 📈 INFORMASI HARGA EMAS DUNIA + STATUS KONEKSI
                  // ======================================================
                  if (!_isLoading && _nisabValue != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),

                      /// Layout:
                      /// [📈 Icon] [Info Emas + Update] [🟢 Online / 🔴 Offline]
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.trending_up,
                              color: Colors.amber, size: 28),
                          const SizedBox(width: 10),

                          // 🔹 Info harga & waktu update
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "📈 Harga emas dunia:",
                                  style: TextStyle(
                                    fontFamily: 'PoppinsSemiBold',
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${_currencyFormat.format(_nisabValue! / 85)} / gram",
                                  style: const TextStyle(
                                    fontFamily: 'PoppinsBold',
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                if (_lastUpdate != null)
                                  Text(
                                    "Update: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(_lastUpdate!))}",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                const Text(
                                  "Sumber: GoldAPI.io + open.er-api.com",
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),

                          // 🔹 Status koneksi API (Online / Offline)
                          Row(
                            children: [
                              Icon(Icons.circle,
                                  color: _isOffline
                                      ? Colors.redAccent
                                      : Colors.green,
                                  size: 10),
                              const SizedBox(width: 4),
                              Text(
                                _isOffline ? "Offline (Cache)" : "Online",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _isOffline
                                      ? Colors.redAccent
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // ======================================================
                  // [3.2] 💰 INFORMASI NISAB SAAT INI
                  // ======================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nisabValue != null
                              ? "💰 Nisab saat ini (85 gram emas): ${_currencyFormat.format(_nisabValue)} per tahun."
                              : "Mengambil data harga emas...",
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (_lastUpdate != null)
                          Text(
                            "🕓 Terakhir diperbarui: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(_lastUpdate!))}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        if (_isOffline)
                          const Text(
                            "⚠️ Mode offline: data diambil dari cache lokal",
                            style: TextStyle(
                                fontSize: 12, color: Colors.redAccent),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ======================================================
                  // [3.3] 💼 INPUT: GAJI & PENGELUARAN
                  // ======================================================
                  const Text("Gaji Per Bulan",
                      style: TextStyle(fontFamily: 'PoppinsSemiBold')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      CurrencyInputFormatter(
                        leadingSymbol: '',
                        useSymbolPadding: false,
                        mantissaLength: 0,
                        thousandSeparator: ThousandSeparator.Period,
                      ),
                    ],
                    decoration: InputDecoration(
                      hintText: "Masukkan gaji per bulan",
                      prefixIcon:
                          const Icon(Icons.monetization_on_outlined),
                      prefixText: 'Rp ',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text("Pengeluaran Pokok Per Bulan",
                      style: TextStyle(fontFamily: 'PoppinsSemiBold')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _expenseController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      CurrencyInputFormatter(
                        leadingSymbol: '',
                        useSymbolPadding: false,
                        mantissaLength: 0,
                        thousandSeparator: ThousandSeparator.Period,
                      ),
                    ],
                    decoration: InputDecoration(
                      hintText: "Masukkan pengeluaran pokok",
                      prefixIcon:
                          const Icon(Icons.shopping_cart_outlined),
                      prefixText: 'Rp ',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ======================================================
                  // [3.4] 🧮 TOMBOL HITUNG ZAKAT
                  // ======================================================
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
                      label: const Text("Hitung Zakat",
                          style: TextStyle(
                              fontFamily: 'PoppinsBold', fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ======================================================
                  // [3.5] 📊 HASIL PERHITUNGAN ZAKAT
                  // ======================================================
                  if (_zakatAmount != null)
                    Container(
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
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currencyFormat.format(_zakatAmount),
                            style: const TextStyle(
                                fontFamily: 'PoppinsBold',
                                fontSize: 28,
                                color: Colors.green),
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
