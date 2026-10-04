import 'package:dio/dio.dart';
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
  bool _isCancelling = false;
  bool _syncWasCancelled = false;
  String? _error;
  DateTime? _lastSync;
  int _totalCount = 0;
  PersonaListStatus _status = PersonaListStatus.cargando;

  // Progreso de la sincronización en curso. `syncProgress == null`
  // significa "conectando" (página 1 aún sin responder, total desconocido).
  double? _syncProgress;
  int _syncPaginaActual = 0;
  int _syncTotalPaginas = 0;
  int _syncRecibidos = 0;

  /// Registros del último sync descartados por venir sin código válido.
  /// Solo informativo para la UI; en carga desde disco se desconoce (0).
  int _syncDescartados = 0;
  Duration _syncElapsed = Duration.zero;
  DateTime? _syncStartedAt;
  CancelToken? _syncCancelToken;
  Timer? _elapsedTimer;

  List<Persona> get personas => List.unmodifiable(_personas);
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isCancelling => _isCancelling;
  bool get syncWasCancelled => _syncWasCancelled;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;
  int get totalCount => _totalCount;
  bool get hasPersonas => _personas.isNotEmpty;
  PersonaListStatus get status => _status;
  double? get syncProgress => _syncProgress;
  int get syncPaginaActual => _syncPaginaActual;
  int get syncTotalPaginas => _syncTotalPaginas;
  int get syncRecibidos => _syncRecibidos;
  int get syncDescartados => _syncDescartados;
  Duration get syncElapsed => _syncElapsed;

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
    // Lo descartado por el último sync se desconoce al leer disco.
    _syncDescartados = 0;
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
    _isCancelling = false;
    _syncWasCancelled = false;
    _error = null;
    _syncProgress = null;
    _syncPaginaActual = 0;
    _syncTotalPaginas = 0;
    _syncRecibidos = 0;
    _syncDescartados = 0;
    _syncElapsed = Duration.zero;
    _syncStartedAt = DateTime.now();
    _syncCancelToken = CancelToken();
    notifyListeners();

    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isSyncing) return;
      final started = _syncStartedAt;
      if (started != null) {
        _syncElapsed = DateTime.now().difference(started);
        notifyListeners();
      }
    });

    try {
      final result = await _repository.syncPersonas(
        cancelToken: _syncCancelToken,
        onProgress: ({
          required int paginaActual,
          required int totalPaginas,
          required int recibidos,
        }) {
          _syncPaginaActual = paginaActual;
          _syncTotalPaginas = totalPaginas;
          _syncRecibidos = recibidos;
          _syncProgress = totalPaginas > 0
              ? (paginaActual / totalPaginas).clamp(0.0, 1.0)
              : null;
          notifyListeners();
        },
      );
      _personas = result.personas;
      _buildIndexes(_personas);
      // Lo que ve el operador es lo real en disco, no el `count` del
      // servidor (puede incluir registros sin código que se descartan).
      _totalCount = result.personas.length;
      _syncDescartados = result.descartados;
      _lastSync = result.syncedAt;
      _status = _personas.isNotEmpty
          ? PersonaListStatus.lista
          : PersonaListStatus.vacia;
      return true;
    } on AppException catch (e) {
      if (e.type == AppErrorType.requestCancelled) {
        // Cancelación del usuario: no es error, se conserva la lista previa.
        _error = null;
        _syncWasCancelled = true;
        return false;
      }
      _error = _mapError(e);
      if (_personas.isNotEmpty) {
        return false;
      }
      _status = PersonaListStatus.error;
      // Último recurso: disco local. Desde el modo solo-manual
      // `getAllPersonas()` jamás toca red, así que no hay recursión.
      try {
        final cache = await _repository.getAllPersonas();
        if (cache.isNotEmpty) {
          _personas = cache;
          _buildIndexes(_personas);
          _totalCount = cache.length;
          _status = PersonaListStatus.lista;
          return false;
        }
      } catch (_) {}
      return false;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        _error = null;
        _syncWasCancelled = true;
        return false;
      }
      _error = _mapError(AppException.fromDioException(e));
      if (_personas.isEmpty) _status = PersonaListStatus.error;
      return false;
    } on TimeoutException catch (e) {
      _error = _mapError(AppException.timeout(e.message));
      if (_personas.isEmpty) _status = PersonaListStatus.error;
      return false;
    } catch (e) {
      _error = _mapError(Exception(e.toString()));
      if (_personas.isEmpty) _status = PersonaListStatus.error;
      return false;
    } finally {
      _elapsedTimer?.cancel();
      _elapsedTimer = null;
      _syncCancelToken = null;
      _isSyncing = false;
      _isCancelling = false;
      notifyListeners();
    }
  }

  /// Cancela la sincronización en curso abortando las peticiones en vuelo.
  ///
  /// La lista previa se conserva intacta y no se marca error: el llamador
  /// debe leer [syncWasCancelled] para mostrar un aviso neutro.
  Future<void> cancelSync() async {
    if (!_isSyncing || _isCancelling) return;
    _isCancelling = true;
    notifyListeners();
    try {
      _syncCancelToken?.cancel('Usuario canceló la sincronización');
    } catch (_) {
      // Cancelar dos veces o con el token ya liberado no es error.
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
    // Si hay una sincronización en vuelo (p. ej. logout desde otra
    // pantalla), abortarla antes de vaciar para no escribir caché después.
    try {
      _syncCancelToken?.cancel('Sesión cerrada');
    } catch (_) {}
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _syncCancelToken = null;
    _personas = [];
    _byCodigoSolapin = {};
    _bySolapin = {};
    _totalCount = 0;
    _lastSync = null;
    _error = null;
    _isLoading = false;
    _isSyncing = false;
    _isCancelling = false;
    _syncWasCancelled = false;
    _syncProgress = null;
    _syncPaginaActual = 0;
    _syncTotalPaginas = 0;
    _syncRecibidos = 0;
    _syncDescartados = 0;
    _syncElapsed = Duration.zero;
    _status = PersonaListStatus.vacia;
    notifyListeners();
    await _repository.clearSession();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
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