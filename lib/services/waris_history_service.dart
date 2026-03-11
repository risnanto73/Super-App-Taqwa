import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'waris_service.dart';

class WarisHistoryService {
  static const String _key = 'waris_history';

  static Future<void> saveCalculation(WarisResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];

    // Add new result at the beginning
    final newResult = WarisResult(
      validHeirs: result.validHeirs,
      blockedHeirs: result.blockedHeirs,
      initialAM: result.initialAM,
      finalAM: result.finalAM,
      adjustmentType: result.adjustmentType,
      isDeceasedMale: result.isDeceasedMale,
      totalWealth: result.totalWealth,
      steps: result.steps,
      createdAt: DateTime.now(),
    );

    history.insert(0, jsonEncode(newResult.toJson()));

    // Limit to 20 items
    if (history.length > 20) {
      history.removeLast();
    }

    await prefs.setStringList(_key, history);
  }

  static Future<List<WarisResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];

    return history.map((e) => WarisResult.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> deleteHistoryItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];

    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      await prefs.setStringList(_key, history);
    }
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
