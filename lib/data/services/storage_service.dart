import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/scan_item.dart';
import '../../domain/entities/evento.dart';

class StorageService {
  static const String _itemsKey = 'scanned_items';
  static const String _trashKey = 'trash_items';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Evento? _parseEvento(String? value) {
    if (value == null) return null;
    return Evento.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Evento.almuerzo,
    );
  }

  static ScanStatus _parseStatus(String? value) {
    if (value == null) return ScanStatus.reserved;
    return ScanStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ScanStatus.reserved,
    );
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
        evento: item['evento'] != null ? _parseEvento(item['evento'] as String) : null,
        personaSolapine: item['personaSolapine'] as String?,
        personaNombre: item['personaNombre'] as String?,
        status: _parseStatus(item['status'] as String?),
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
        'evento': item.evento?.name,
        'personaSolapine': item.personaSolapine,
        'personaNombre': item.personaNombre,
        'status': item.status.name,
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
        evento: item['evento'] != null ? _parseEvento(item['evento'] as String) : null,
        personaSolapine: item['personaSolapine'] as String?,
        personaNombre: item['personaNombre'] as String?,
        status: _parseStatus(item['status'] as String?),
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
        'evento': item.evento?.name,
        'personaSolapine': item.personaSolapine,
        'personaNombre': item.personaNombre,
        'status': item.status.name,
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