import 'package:flutter/foundation.dart';
import '../../domain/entities/persona.dart';
import '../../data/services/csv_service.dart';

class CsvProvider extends ChangeNotifier {
  List<Persona> _personas = [];
  bool _isLoading = false;
  String? _error;
  bool _isConnected = false;
  DateTime? _lastConnectionCheck;

  List<Persona> get personas => _personas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get tienePersonas => _personas.isNotEmpty;
  bool get isConnected => _isConnected;
  DateTime? get lastConnectionCheck => _lastConnectionCheck;

  Future<void> init() async {
    _personas = await CsvService.loadFromCache();
    notifyListeners();
  }

  Future<bool> checkConnection() async {
    try {
      final isConnected = await CsvService.checkUrl();
      _isConnected = isConnected;
      _lastConnectionCheck = DateTime.now();
      notifyListeners();
      return isConnected;
    } catch (e) {
      _isConnected = false;
      _lastConnectionCheck = DateTime.now();
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarLista() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final personas = await CsvService.downloadAndParse();
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
}