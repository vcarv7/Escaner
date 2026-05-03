import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/persona.dart';

class CsvService {
  static const String _cacheFileName = 'personas_cache.json';

  static Future<bool> checkUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Persona>> downloadAndParse(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return [];
      }
      return _parseCsv(response.body);
    } catch (e) {
      return [];
    }
  }

  static List<Persona> _parseCsv(String csvContent) {
    final List<Persona> personas = [];
    final lines = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (i == 0 && line.contains('codigo')) continue;

      final parts = line.split(',');
      if (parts.length < 4) continue;

      final codigo = parts[0].trim();
      final solapine = parts[1].trim();
      final nombre = parts[2].trim();
      final apellidos = parts[3].trim();

      if (codigo.isNotEmpty) {
        personas.add(Persona(
          codigo: codigo,
          solapine: solapine,
          nombre: nombre,
          apellidos: apellidos,
        ));
      }
    }
    return personas;
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