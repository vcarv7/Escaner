import 'package:flutter/foundation.dart';
import '../../domain/entities/persona.dart';
import '../../domain/repositories/persona_repository.dart';
import '../../data/repositories/persona_repository_impl.dart';
import '../../data/datasources/persona_api_datasource.dart';
import '../../data/services/persona_cache_service.dart';
import '../../data/services/api_client.dart';

class PersonaProvider extends ChangeNotifier {
  final PersonaRepository _repository;

  List<Persona> _personas = [];
  Map<String, Persona> _byCodigoSolapin = {};
  Map<String, Persona> _bySolapin = {};
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  DateTime? _lastSync;
  int _totalCount = 0;

  List<Persona> get personas => List.unmodifiable(_personas);
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;
  int get totalCount => _totalCount;
  bool get hasPersonas => _personas.isNotEmpty;

  PersonaProvider({PersonaRepository? repository})
      : _repository = repository ?? PersonaRepositoryImpl(
          PersonaApiDatasource(ApiClient()),
          PersonaCacheService(),
        );

  Future<void> init() async {
    if (_personas.isNotEmpty) return;
    await loadFromCache();
  }

  Future<void> loadFromCache() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _personas = await _repository.getAllPersonas();
      _buildIndexes(_personas);
      _totalCount = _personas.length;
      final hasCache = await _repository.hasCache();
      if (hasCache) {
        final meta = await PersonaCacheService().loadMeta();
        _lastSync = meta?.lastSync;
      }
    } catch (e) {
      _error = 'Error cargando caché: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> syncPersonas() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.syncPersonas();
      _personas = result.personas;
      _buildIndexes(_personas);
      _totalCount = result.totalCount;
      _lastSync = result.syncedAt;
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error sincronizando: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  Persona? findByCodigoSolapin(String codigo) {
    return _byCodigoSolapin[codigo.toLowerCase()];
  }

  Persona? findBySolapin(String solapin) {
    return _bySolapin[solapin.toLowerCase()];
  }

  Persona? findPersona(String code) {
    final lower = code.toLowerCase();
    return _byCodigoSolapin[lower] ?? _bySolapin[lower];
  }

  void _buildIndexes(List<Persona> personas) {
    _byCodigoSolapin = {};
    _bySolapin = {};
    for (final persona in personas) {
      if (persona.codigoSolapin.isNotEmpty) {
        _byCodigoSolapin[persona.codigoSolapin.toLowerCase()] = persona;
      }
      if (persona.solapin.isNotEmpty) {
        _bySolapin[persona.solapin.toLowerCase()] = persona;
      }
    }
  }
}