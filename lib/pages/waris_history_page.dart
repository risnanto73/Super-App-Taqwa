import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/waris_service.dart';
import '../services/waris_history_service.dart';
import '../widgets/waris/waris_result_view.dart';

class WarisHistoryPage extends StatefulWidget {
  const WarisHistoryPage({super.key});

  @override
  State<WarisHistoryPage> createState() => _WarisHistoryPageState();
}

class _WarisHistoryPageState extends State<WarisHistoryPage> {
  List<WarisResult> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await WarisHistoryService.getHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Riwayat Perhitungan",
          style: TextStyle(fontFamily: 'PoppinsBold'),
        ),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _confirmClearHistory(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final result = _history[index];
                final dateStr = result.createdAt != null
                    ? DateFormat('dd MMM yyyy, HH:mm').format(result.createdAt!)
                    : "-";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        result.isDeceasedMale ? Icons.man : Icons.woman,
                        color: Colors.amber[900],
                      ),
                    ),
                    title: Text(
                      format.format(result.totalWealth),
                      style: const TextStyle(fontFamily: 'PoppinsBold'),
                    ),
                    subtitle: Text(
                      "Pewaris: ${result.isDeceasedMale ? 'Suami' : 'Istri'}\n$dateStr",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showResult(result),
                    onLongPress: () => _confirmDelete(index),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Belum ada riwayat",
            style: TextStyle(fontFamily: 'PoppinsSemiBold', color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showResult(WarisResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: WarisResultView(result: result),
        ),
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Riwayat?"),
        content: const Text("Tindakan ini tidak bisa dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              WarisHistoryService.deleteHistoryItem(index);
              Navigator.pop(context);
              _loadHistory();
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kosongkan Riwayat?"),
        content: const Text("Hapus semua catatan perhitungan waris?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              WarisHistoryService.clearHistory();
              Navigator.pop(context);
              _loadHistory();
            },
            child: const Text(
              "Hapus Semua",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
