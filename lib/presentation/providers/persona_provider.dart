import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../domain/entities/persona.dart';
import '../../domain/repositories/persona_repository.dart';
import '../../data/repositories/persona_repository_impl.dart';
import '../../data/datasources/persona_api_datasource.dart';
import '../../data/services/persona_cache_service.dart';
import '../../data/services/api_client.dart';
import '../../core/errors/app_exception.dart';

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
    } on AppException catch (e) {
      _error = _mapError(e);
    } catch (e) {
      _error = _mapError(Exception(e.toString()));
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
    } on AppException catch (e) {
      _error = _mapError(e);
      if (_personas.isNotEmpty) {
        _isSyncing = false;
        notifyListeners();
        return false;
      }
      try {
        final cache = await _repository.getAllPersonas();
        if (cache.isNotEmpty) {
          _personas = cache;
          _buildIndexes(_personas);
          _totalCount = cache.length;
          _isSyncing = false;
          notifyListeners();
          return false;
        }
      } catch (_) {}
      _isSyncing = false;
      notifyListeners();
      return false;
    } on TimeoutException catch (e) {
      _error = _mapError(AppException.timeout(e.message));
      _isSyncing = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _mapError(Exception(e.toString()));
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  String _mapError(Object error) {
    if (error is AppException) {
      return error.message;
    }
    final msg = error.toString();
    if (msg.toLowerCase().contains('timeout')) {
      return 'Tiempo de espera agotado. Verifica tu conexión.';
    }
    if (msg.toLowerCase().contains('connection') || msg.toLowerCase().contains('socket')) {
      return 'Sin conexión. Verifica tu red.';
    }
    if (msg.contains('401') || msg.toLowerCase().contains('unauthorized')) {
      return 'Sesión expirada. Inicia sesión nuevamente.';
    }
    if (msg.contains('403') || msg.toLowerCase().contains('forbidden')) {
      return 'Acceso denegado.';
    }
    if (msg.contains('500') || msg.toLowerCase().contains('server')) {
      return 'Error del servidor. Intenta más tarde.';
    }
    if (msg.contains('404')) {
      return 'Recurso no encontrado.';
    }
    return 'Error: ${msg.replaceFirst('Exception: ', '')}';
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

  bool get isCacheStale {
    if (_lastSync == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_lastSync!);
    return difference.inDays > 30;
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