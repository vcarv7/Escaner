import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/scan_record.dart';

class StorageService {
  static const String _recordsKey = 'scanned_records';
  static const String _trashKey = 'trash_records';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static Future<void> init() async {}

  static Future<List<ScanRecord>> loadRecords() async {
    try {
      final String? jsonString = await _storage.read(key: _recordsKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .whereType<Map<String, dynamic>>()
          .map(ScanRecord.fromJson)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveRecords(List<ScanRecord> records) async {
    try {
      final jsonList = records.map((r) => r.toJson()).toList();
      await _storage.write(key: _recordsKey, value: json.encode(jsonList));
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clearRecords() async {
    try {
      await _storage.delete(key: _recordsKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<ScanRecord>> loadTrash() async {
    try {
      final String? jsonString = await _storage.read(key: _trashKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .whereType<Map<String, dynamic>>()
          .map(ScanRecord.fromJson)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveTrash(List<ScanRecord> records) async {
    try {
      final jsonList = records.map((r) => r.toJson()).toList();
      await _storage.write(key: _trashKey, value: json.encode(jsonList));
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