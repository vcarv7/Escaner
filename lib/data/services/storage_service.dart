import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/scan_item.dart';

class StorageService {
  static const String _itemsKey = 'scanned_items';
  static const String _trashKey = 'trash_items';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<List<ScanItem>> loadItems() async {
    try {
      final String? jsonString = _prefs.getString(_itemsKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => ScanItem(
        code: item['code'] as String,
        type: item['type'] == 'solapine' ? ScanType.solapine : ScanType.tarjeta,
        isDuplicate: item['isDuplicate'] as bool? ?? false,
        scannedAt: DateTime.parse(item['scannedAt'] as String),
      )).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveItems(List<ScanItem> items) async {
    try {
      final List<Map<String, dynamic>> jsonList = items.map((item) => {
        'code': item.code,
        'type': item.type == ScanType.solapine ? 'solapine' : 'tarjeta',
        'isDuplicate': item.isDuplicate,
        'scannedAt': item.scannedAt.toIso8601String(),
      }).toList();

      return await _prefs.setString(_itemsKey, json.encode(jsonList));
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clearItems() async {
    return await _prefs.remove(_itemsKey);
  }

  static Future<List<ScanItem>> loadTrash() async {
    try {
      final String? jsonString = _prefs.getString(_trashKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => ScanItem(
        code: item['code'] as String,
        type: item['type'] == 'solapine' ? ScanType.solapine : ScanType.tarjeta,
        isDuplicate: item['isDuplicate'] as bool? ?? false,
        scannedAt: DateTime.parse(item['scannedAt'] as String),
      )).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveTrash(List<ScanItem> items) async {
    try {
      final List<Map<String, dynamic>> jsonList = items.map((item) => {
        'code': item.code,
        'type': item.type == ScanType.solapine ? 'solapine' : 'tarjeta',
        'isDuplicate': item.isDuplicate,
        'scannedAt': item.scannedAt.toIso8601String(),
      }).toList();

      return await _prefs.setString(_trashKey, json.encode(jsonList));
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clearTrash() async {
    return await _prefs.remove(_trashKey);
  }
}