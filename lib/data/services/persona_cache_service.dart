import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/persona.dart';

class SyncMeta {
  final DateTime lastSync;
  final int totalCount;
  final String? etag;

  SyncMeta({
    required this.lastSync,
    required this.totalCount,
    this.etag,
  });

  Map<String, dynamic> toJson() => {
    'lastSync': lastSync.toIso8601String(),
    'totalCount': totalCount,
    'etag': etag,
  };

  factory SyncMeta.fromJson(Map<String, dynamic> json) => SyncMeta(
    lastSync: DateTime.parse(json['lastSync'] as String),
    totalCount: json['totalCount'] as int,
    etag: json['etag'] as String?,
  );
}

class PersonaCacheService {
  Future<File> _getCacheFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/personas_cache.json');
  }

  Future<File> _getMetaFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/sync_meta.json');
  }

  Future<List<Persona>> loadCache() async {
    try {
      final file = await _getCacheFile();
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      if (content.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(content);
      return jsonList
          .whereType<Map<String, dynamic>>()
          .map(Persona.fromMap)
          .toList();
    } catch (e) {
      debugPrint('PersonaCacheService.loadCache error: $e');
      return [];
    }
  }

  Future<void> saveCache(List<Persona> personas) async {
    try {
      final file = await _getCacheFile();
      final jsonList = personas.map((p) => p.toMap()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      debugPrint('PersonaCacheService.saveCache error: $e');
    }
  }

  Future<void> saveCacheWithMeta(List<Persona> personas, SyncMeta meta) async {
    try {
      await Future.wait([
        saveCache(personas),
        saveMeta(meta),
      ]);
    } catch (e) {
      debugPrint('PersonaCacheService.saveCacheWithMeta error: $e');
    }
  }

  Future<SyncMeta?> loadMeta() async {
    try {
      final file = await _getMetaFile();
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      if (content.isEmpty) return null;

      return SyncMeta.fromJson(json.decode(content) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('PersonaCacheService.loadMeta error: $e');
      return null;
    }
  }

  Future<void> saveMeta(SyncMeta meta) async {
    try {
      final file = await _getMetaFile();
      await file.writeAsString(json.encode(meta.toJson()));
    } catch (e) {
      debugPrint('PersonaCacheService.saveMeta error: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final cacheFile = await _getCacheFile();
      final metaFile = await _getMetaFile();
      await Future.wait([
        cacheFile.delete(),
        metaFile.delete(),
      ]);
    } catch (e) {
      debugPrint('PersonaCacheService.clearCache error: $e');
    }
  }
}
