import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/scan_item.dart';
import '../../domain/entities/evento.dart';

class StorageService {
  static const String _itemsKey = 'scanned_items';
  static const String _trashKey = 'trash_items';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static Future<void> init() async {}

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

  static List<ScanItem> _parseItems(List<dynamic> jsonList) {
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
  }

  static String _encodeItems(List<ScanItem> items) {
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
    return json.encode(jsonList);
  }

  static Future<List<ScanItem>> loadItems() async {
    try {
      final String? jsonString = await _storage.read(key: _itemsKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return _parseItems(jsonList);
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveItems(List<ScanItem> items) async {
    try {
      final jsonString = _encodeItems(items);
      await _storage.write(key: _itemsKey, value: jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clearItems() async {
    try {
      await _storage.delete(key: _itemsKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<ScanItem>> loadTrash() async {
    try {
      final String? jsonString = await _storage.read(key: _trashKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return _parseItems(jsonList);
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveTrash(List<ScanItem> items) async {
    try {
      final jsonString = _encodeItems(items);
      await _storage.write(key: _trashKey, value: jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clearTrash() async {
    try {
      await _storage.delete(key: _trashKey);
      return true;
    } catch (e) {
      return false;
    }
  }
}