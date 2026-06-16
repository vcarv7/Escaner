import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/persona.dart';

class CsvService {
  static const String _cacheFileName = 'personas_cache.json';

  static Map<String, String> get _headers {
    if (AppConstants.gitlabToken.isNotEmpty) {
      return {'PRIVATE-TOKEN': AppConstants.gitlabToken};
    }
    return {};
  }

  static Future<bool> checkUrl() async {
    try {
      final response = await http.head(
        Uri.parse(AppConstants.csvUrl),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Persona>> downloadAndParse() async {
    try {
      print('=== CSV DEBUG ===');
      print('Token: ${AppConstants.gitlabToken.isEmpty ? "VACÍO" : "SET"}');
      print('URL: ${AppConstants.csvUrl}');
      
      final response = await http.get(
        Uri.parse(AppConstants.csvUrl),
        headers: _headers,
      );
      
      print('Status: ${response.statusCode}');
      print('Body preview: ${response.body.substring(0, response.body.length.clamp(0, 300))}');
      print('=================');
      
      if (response.statusCode != 200) {
        return [];
      }
      return _parseCsv(response.body);
    } catch (e) {
      print('Exception: $e');
      return [];
    }
  }

  static List<Persona> _parseCsv(String csvContent) {
    final List<Persona> personas = [];
    final lines = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (i == 0) continue;

      final parts = _parseCsvLine(line);
      if (parts.length < 22) continue;

      final idPersona = parts[0].replaceAll('"', '').trim();
      final nombreCompleto = parts[4].replaceAll('"', '').trim();
      final solapin = parts[6].replaceAll('"', '').trim();
      final codigoSolapin = parts[21].replaceAll('"', '').trim();

      if (idPersona.isNotEmpty) {
        personas.add(Persona(
          idPersona: idPersona,
          codigoSolapin: codigoSolapin,
          solapin: solapin,
          nombreCompleto: nombreCompleto,
        ));
      }
    }
    return personas;
  }

  static List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  static Future<List<Persona>> loadFromCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_cacheFileName');
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((p) => Persona.fromMap(p as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveToCache(List<Persona> personas) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_cacheFileName');
      final jsonList = personas.map((p) => p.toMap()).toList();
      await file.writeAsString(json.encode(jsonList));
      return true;
    } catch (e) {
      return false;
    }
  }
}