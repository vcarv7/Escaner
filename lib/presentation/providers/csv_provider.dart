import 'package:flutter/foundation.dart';
import '../../domain/entities/persona.dart';
import '../../data/services/csv_service.dart';

class CsvProvider extends ChangeNotifier {
  List<Persona> _personas = [];
  bool _isLoading = false;
  String? _error;

  List<Persona> get personas => _personas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get tienePersonas => _personas.isNotEmpty;

  Future<void> init() async {
    _personas = await CsvService.loadFromCache();
    notifyListeners();
  }

  Future<bool> actualizarLista(String url) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final personas = await CsvService.downloadAndParse(url);
      if (personas.isNotEmpty) {
        _personas = personas;
        await CsvService.saveToCache(personas);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'No se encontraron personas';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error al descargar: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Persona? findByCodigo(String codigo) {
    for (final persona in _personas) {
      if (persona.codigo == codigo) {
        return persona;
      }
    }
    return null;
  }
}