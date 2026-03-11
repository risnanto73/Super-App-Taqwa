import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import '../services/zakat_service.dart';
import '../widgets/zakat/zakat_info_card.dart';
import '../widgets/zakat/zakat_calculator_input.dart';
import '../widgets/zakat/zakat_result_card.dart';
import '../widgets/zakat/forms/zakat_perdagangan_form.dart';
import '../widgets/zakat/forms/zakat_emas_perak_form.dart';
import '../widgets/zakat/forms/zakat_pertanian_form.dart';
import '../widgets/zakat/forms/zakat_tabungan_form.dart';

class ZakatPage extends StatefulWidget {
  const ZakatPage({super.key});

  @override
  State<ZakatPage> createState() => _ZakatPageState();
}

class _ZakatPageState extends State<ZakatPage> {
  // Penghasilan
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _expenseController = TextEditingController();

  // Perdagangan
  final TextEditingController _modalController = TextEditingController();
  final TextEditingController _labaController = TextEditingController();
  final TextEditingController _piutangController = TextEditingController();
  final TextEditingController _hutangController = TextEditingController();
  final TextEditingController _kerugianController = TextEditingController();

  // Emas & Perak
  final TextEditingController _ownedController = TextEditingController();
  final TextEditingController _usedController = TextEditingController();

  // Pertanian
  final TextEditingController _harvestController = TextEditingController();

  // Tabungan
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();

  double? _zakatAmount;
  String? _zakatSymbol = "Rp ";
  double? _nisabValue;
  double? _goldPrice;
  double? _silverPrice;
  bool _isAboveNisab = false;
  bool _isLoading = false;
  String? _lastUpdate;
  bool _isOffline = false;
  String? _calculationBreakdown;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    final data = await ZakatService.fetchGoldAndNisab();
    setState(() {
      _nisabValue = data['nisabValue'];
      _goldPrice = data['goldPrice'];
      _silverPrice = data['silverPrice'];
      _lastUpdate = data['lastUpdate'];
      _isOffline = data['isOffline'];
      _isLoading = false;
    });
  }

  void _calculateZakat() {
    final income = double.tryParse(toNumericString(_incomeController.text));
    final expense = double.tryParse(toNumericString(_expenseController.text));

    if (income == null || expense == null) {
      _showWarning('Masukkan angka yang valid');
      return;
    }

    if (_nisabValue == null) return;

    final result = ZakatService.calculateZakat(income, expense, _nisabValue!);
    setState(() {
      _zakatAmount = result['zakatAmount'];
      _zakatSymbol = "Rp ";
      _isAboveNisab = result['isAboveNisab'];
      _calculationBreakdown =
          "(${_currencyFormat.format(income)} - ${_currencyFormat.format(expense)}) x 2,5%";
    });
  }

  void _calculatePerdagangan() {
    final modal = double.tryParse(toNumericString(_modalController.text)) ?? 0;
    final laba = double.tryParse(toNumericString(_labaController.text)) ?? 0;
    final piutang =
        double.tryParse(toNumericString(_piutangController.text)) ?? 0;
    final hutang =
        double.tryParse(toNumericString(_hutangController.text)) ?? 0;
    final kerugian =
        double.tryParse(toNumericString(_kerugianController.text)) ?? 0;

    if (_nisabValue == null) return;

    final result = ZakatService.calculatePerdagangan(
      modal: modal,
      laba: laba,
      piutang: piutang,
      hutang: hutang,
      kerugian: kerugian,
      nisabValue: _nisabValue!,
    );
    setState(() {
      _zakatAmount = result['zakatAmount'];
      _zakatSymbol = "Rp ";
      _isAboveNisab = result['isAboveNisab'];
      _calculationBreakdown =
          "(${_currencyFormat.format(modal)} + ${_currencyFormat.format(laba)} + ${_currencyFormat.format(piutang)} - ${_currencyFormat.format(hutang)} - ${_currencyFormat.format(kerugian)}) x 2,5%";
    });
  }

  void _calculateEmasPerak(bool isGold) {
    final owned = double.tryParse(_ownedController.text) ?? 0;
    final used = double.tryParse(_usedController.text) ?? 0;
    final double nisabGram = isGold ? 85.0 : 595.0;

    final result = ZakatService.calculateEmasPerak(
      totalOwned: owned,
      totalUsed: used,
      nisabGram: nisabGram,
    );

    setState(() {
      final pricePerGram = isGold ? (_goldPrice ?? 0) : (_silverPrice ?? 0);
      _zakatAmount = result['zakatWeight'] * pricePerGram;
      _zakatSymbol = "Rp ";
      _isAboveNisab = result['isAboveNisab'];
      _calculationBreakdown =
          "($owned gr - $used gr) x ${_currencyFormat.format(pricePerGram)} x 2,5%";
    });
  }

  void _calculatePertanian(bool isIrrigated) {
    final harvest = double.tryParse(_harvestController.text) ?? 0;
    final result = ZakatService.calculatePertanian(
      harvestKg: harvest,
      isIrrigated: isIrrigated,
    );
    setState(() {
      _zakatAmount = result['zakatAmountKg'];
      _zakatSymbol = " kg";
      _isAboveNisab = result['isAboveNisab'];
      final rate = isIrrigated ? "5%" : "10%";
      _calculationBreakdown = "$harvest kg x $rate";
    });
  }

  void _calculateTabungan() {
    final balance =
        double.tryParse(toNumericString(_balanceController.text)) ?? 0;
    final interest =
        double.tryParse(toNumericString(_interestController.text)) ?? 0;

    if (_nisabValue == null) return;

    final result = ZakatService.calculateTabungan(
      balance: balance,
      interest: interest,
      nisabValue: _nisabValue!,
    );
    setState(() {
      _zakatAmount = result['zakatAmount'];
      _zakatSymbol = "Rp ";
      _isAboveNisab = result['isAboveNisab'];
      _calculationBreakdown =
          "(${_currencyFormat.format(balance)} - ${_currencyFormat.format(interest)}) x 2,5%";
    });
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.amber,
          title: const Text(
            "Kalkulator Zakat",
            style: TextStyle(
              fontFamily: 'PoppinsSemiBold',
              color: Colors.white,
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Penghasilan"),
              Tab(text: "Perdagangan"),
              Tab(text: "Emas & Perak"),
              Tab(text: "Pertanian"),
              Tab(text: "Tabungan"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
            : Column(
                children: [
                  if (_nisabValue != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: ZakatInfoCard(
                        nisabValue: _nisabValue!,
                        lastUpdate: _lastUpdate,
                        isOffline: _isOffline,
                        currencyFormat: _currencyFormat,
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTabWrapper(
                          ZakatCalculatorInput(
                            incomeController: _incomeController,
                            expenseController: _expenseController,
                            onCalculate: _calculateZakat,
                          ),
                        ),
                        _buildTabWrapper(
                          ZakatPerdaganganForm(
                            modalController: _modalController,
                            labaController: _labaController,
                            piutangController: _piutangController,
                            hutangController: _hutangController,
                            kerugianController: _kerugianController,
                            onCalculate: _calculatePerdagangan,
                          ),
                        ),
                        _buildTabWrapper(
                          ZakatEmasPerakForm(
                            ownedController: _ownedController,
                            usedController: _usedController,
                            onCalculate: (isGold) =>
                                _calculateEmasPerak(isGold),
                          ),
                        ),
                        _buildTabWrapper(
                          ZakatPertanianForm(
                            harvestController: _harvestController,
                            onCalculate: _calculatePertanian,
                          ),
                        ),
                        _buildTabWrapper(
                          ZakatTabunganForm(
                            balanceController: _balanceController,
                            interestController: _interestController,
                            onCalculate: _calculateTabungan,
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

  Widget _buildTabWrapper(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          child,
          if (_zakatAmount != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ZakatResultCard(
                zakatAmount: _zakatAmount!,
                isAboveNisab: _isAboveNisab,
                calculationBreakdown: _calculationBreakdown,
                currencyFormat: NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: _zakatSymbol,
                  decimalDigits: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
