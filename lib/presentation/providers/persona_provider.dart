import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../domain/entities/persona.dart';
import '../../domain/repositories/persona_repository.dart';
import '../../data/repositories/persona_repository_impl.dart';
import '../../data/datasources/persona_api_datasource.dart';
import '../../data/services/persona_cache_service.dart';
import '../../data/services/api_client.dart';
import '../../core/errors/app_exception.dart';

/// Estado del catálogo local de personas. La UI lo necesita para distinguir
/// "todavía no sé" de "no hay" de "falló", que son tres situaciones con
/// mensajes y acciones distintas.
enum PersonaListStatus {
  cargando,
  lista,
  vacia,
  error,
}

class PersonaProvider extends ChangeNotifier {
  final PersonaRepository _repository;
  final PersonaCacheService _cacheService;

  List<Persona> _personas = [];
  Map<String, Persona> _byCodigoSolapin = {};
  Map<String, Persona> _bySolapin = {};
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  DateTime? _lastSync;
  int _totalCount = 0;
  PersonaListStatus _status = PersonaListStatus.cargando;

  List<Persona> get personas => List.unmodifiable(_personas);
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;
  int get totalCount => _totalCount;
  bool get hasPersonas => _personas.isNotEmpty;
  PersonaListStatus get status => _status;

  /// Escanear contra una lista vacía marca a todo el mundo como inactivo
  /// (ver `ScanProvider.processScan`), así que la UI debe bloquearlo en vez
  /// de dejar que el operador registre decisiones de acceso equivocadas.
  bool get puedeEscanear => _personas.isNotEmpty;

  PersonaProvider({PersonaRepository? repository, PersonaCacheService? cacheService})
      : _repository = repository ?? PersonaRepositoryImpl(
          PersonaApiDatasource(ApiClient()),
          PersonaCacheService(),
        ),
        _cacheService = cacheService ?? PersonaCacheService();

  Future<void> init() async {
    if (_personas.isNotEmpty) return;
    await loadFromCache();
  }

  Future<void> loadFromCache() async {
    _isLoading = true;
    _error = null;
    _status = PersonaListStatus.cargando;
    notifyListeners();

    try {
      _personas = await _repository.getAllPersonas();
      _buildIndexes(_personas);
      _totalCount = _personas.length;
      final hasCache = await _repository.hasCache();
      if (hasCache) {
        final meta = await _cacheService.loadMeta();
        _lastSync = meta?.lastSync;
      }
      _status = _personas.isNotEmpty ? PersonaListStatus.lista : PersonaListStatus.vacia;
    } on AppException catch (e) {
      _error = _mapError(e);
      _status = PersonaListStatus.error;
    } catch (e) {
      _error = _mapError(Exception(e.toString()));
      _status = PersonaListStatus.error;
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
      _status = _personas.isNotEmpty ? PersonaListStatus.lista : PersonaListStatus.vacia;
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
      _status = PersonaListStatus.error;
      try {
        final cache = await _repository.getAllPersonas();
        if (cache.isNotEmpty) {
          _personas = cache;
          _buildIndexes(_personas);
          _totalCount = cache.length;
          _status = PersonaListStatus.lista;
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
      if (_personas.isEmpty) _status = PersonaListStatus.error;
      _isSyncing = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _mapError(Exception(e.toString()));
      if (_personas.isEmpty) _status = PersonaListStatus.error;
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Vacía la lista de personas SOLO en memoria (provider y repositorio).
  ///
  /// No toca `personas_cache.json`: el catálogo es un dataset del dispositivo,
  /// no de la sesión, y debe sobrevivir a la expiración del token, al cierre de
  /// sesión y a la falta de conexión para que el escaneo siga siendo offline.
  ///
  /// Ojo: el caché en disco no está namespacado por usuario, así que esto NO
  /// aísla datos entre usuarios distintos. Solo libera memoria; el siguiente
  /// `loadFromCache()` recupera el mismo catálogo del disco, sin importar quién
  /// lo haya descargado. Como la lista de personas no filtra por usuario, hoy eso
  /// no supone una fuga, pero no lo trates como si la supusiera.
  Future<void> clearSession() async {
    _personas = [];
    _byCodigoSolapin = {};
    _bySolapin = {};
    _totalCount = 0;
    _lastSync = null;
    _error = null;
    _isLoading = false;
    _isSyncing = false;
    _status = PersonaListStatus.vacia;
    notifyListeners();
    await _repository.clearSession();
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