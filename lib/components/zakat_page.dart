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

  String? _lastUpdate; // simpan waktu update terakhir
  bool _isOffline = false; // indikator mode offline

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

  Future<void> _fetchGoldPrice() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    const fallbackPricePerGram = 2000000.0; // fallback lebih realistis sekarang
    double? pricePerGram;
    double? usdToIdr;

    try {
      print("🌐 [LOG] Mengambil harga emas & kurs USD→IDR...");

      // 1️⃣ Ambil kurs USD → IDR
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

      // 2️⃣ Ambil harga emas per gram dari GoldAPI.io
      final goldRes = await http.get(
        Uri.parse('https://www.goldapi.io/api/XAU/USD'),
        headers: {
          'x-access-token': 'goldapi-1wwsrsmhk0ch86-io',
          'Content-Type': 'application/json',
        },
      );

      if (goldRes.statusCode == 200) {
        final goldData = json.decode(goldRes.body);

        // Ambil langsung field harga per gram 24K (USD)
        final double usdPerGram = (goldData['price_gram_24k'] ?? 0).toDouble();
        print("🪙 Harga emas (USD/gram 24K): $usdPerGram");

        // Konversi ke Rupiah
        pricePerGram = usdPerGram * (usdToIdr ?? 15000);
        print(
          "💰 Harga emas (IDR/gram): Rp ${pricePerGram?.toStringAsFixed(0)}",
        );

        // 3️⃣ Validasi kisaran harga (pasar 2025: 1.8–2.6 jt)
        if (pricePerGram! < 1800000 || pricePerGram > 2600000) {
          print(
            "⚠️ Harga emas tidak realistis ($pricePerGram). Pakai fallback Rp $fallbackPricePerGram",
          );
          pricePerGram = fallbackPricePerGram;
        }

        // 4️⃣ Simpan ke cache
        await prefs.setDouble('last_gold_price', pricePerGram);
        await prefs.setString('last_update', DateTime.now().toIso8601String());
        _isOffline = false;
        print("💾 Harga emas tersimpan ke cache: Rp $pricePerGram");
      } else {
        // Fallback ke cache
        print("⚠️ Gagal ambil API GoldAPI (${goldRes.statusCode})");
        pricePerGram = prefs.getDouble('last_gold_price');
        if (pricePerGram != null) {
          print("📦 Gunakan harga dari cache: Rp $pricePerGram");
          _isOffline = true;
        } else {
          print("⚠️ Cache kosong, fallback Rp $fallbackPricePerGram");
          pricePerGram = fallbackPricePerGram;
          _isOffline = true;
        }
      }
    } catch (e) {
      print("📴 Tidak bisa konek API: $e");
      pricePerGram = prefs.getDouble('last_gold_price') ?? fallbackPricePerGram;
      _isOffline = true;
    }

    // 5️⃣ Hitung nisab (85 gram)
    setState(() {
      _nisabValue = 85 * (pricePerGram ?? fallbackPricePerGram);
      _lastUpdate = prefs.getString('last_update');
      _isLoading = false;
    });

    print("✅ Nisab final (85 gram): Rp ${_nisabValue?.toStringAsFixed(0)}");
  }

  void _calculateZakat() {
    // --- Ambil teks input ---
    String incomeText = _incomeController.text.trim();
    String expenseText = _expenseController.text.trim();

    // --- Bersihkan input ke format numerik ---
    String cleanIncome = toNumericString(incomeText, allowPeriod: false);
    String cleanExpense = toNumericString(expenseText, allowPeriod: false);

    // --- Hapus ".00" sisa format ---
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

    print("📊 Net Income: $netIncome | Annual: $annualIncome | Zakat: $zakat");
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
                  // ======================================================
                  // 📈 INFORMASI HARGA EMAS DUNIA + STATUS KONEKSI API
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ICON TRENDING (KIRI)
                          const Icon(
                            Icons.trending_up,
                            color: Colors.amber,
                            size: 28,
                          ),
                          const SizedBox(width: 10),

                          // KONTEN TENGAH
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

                                // HARGA PER GRAM
                                Text(
                                  "${_currencyFormat.format(_nisabValue! / 85)} / gram",
                                  style: const TextStyle(
                                    fontFamily: 'PoppinsBold',
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // TANGGAL UPDATE
                                if (_lastUpdate != null)
                                  Text(
                                    "Update: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(_lastUpdate!))}",
                                    style: const TextStyle(
                                      fontFamily: 'PoppinsRegular',
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),

                                // SUMBER API
                                const Text(
                                  "Sumber: GoldAPI.io + open.er-api.com",
                                  style: TextStyle(
                                    fontFamily: 'PoppinsRegular',
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // STATUS ONLINE / OFFLINE (KANAN ATAS)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isOffline ? Icons.circle : Icons.circle,
                                    color: _isOffline
                                        ? Colors.redAccent
                                        : Colors.green,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isOffline ? "Offline (Cache)" : "Online",
                                    style: TextStyle(
                                      fontFamily: 'PoppinsRegular',
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
                        ],
                      ),
                    ),

                  // HEADER INFO NISAB
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
                          style: const TextStyle(
                            fontFamily: 'PoppinsRegular',
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        if (_lastUpdate != null)
                          Text(
                            "🕓 Terakhir diperbarui: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(_lastUpdate!))}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        if (_isOffline)
                          const Text(
                            "⚠️ Mode offline: data diambil dari cache lokal",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_nisabValue != null)
                    Text(
                      "Harga emas per gram: ${_currencyFormat.format(_nisabValue! / 85)}",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),

                  const SizedBox(height: 20),

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
                        leadingSymbol: '', // biar gak dobel Rp
                        useSymbolPadding: false,
                        mantissaLength: 0, // tanpa desimal
                        thousandSeparator: ThousandSeparator.Period,
                      ),
                    ],
                    decoration: InputDecoration(
                      hintText: "Masukkan gaji per bulan",
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(
                        fontFamily: 'PoppinsSemiBold',
                        color: Colors.black87,
                        fontSize: 15,
                      ),
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
                    inputFormatters: [
                      CurrencyInputFormatter(
                        leadingSymbol: '',
                        useSymbolPadding: false,
                        mantissaLength: 0, // 🔥 hilangkan .00
                        thousandSeparator: ThousandSeparator.Period,
                      ),
                    ],
                    decoration: InputDecoration(
                      hintText: "Masukkan pengeluaran pokok",
                      prefixIcon: const Icon(Icons.shopping_cart_outlined),
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(
                        fontFamily: 'PoppinsSemiBold',
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

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
                ],
              ),
            ),
    );
  }
}
