import '../../domain/repositories/persona_repository.dart';
import '../../domain/entities/persona.dart';
import '../datasources/persona_api_datasource.dart';
import '../services/persona_cache_service.dart';

class PersonaRepositoryImpl implements PersonaRepository {
  final PersonaApiDatasource _apiDatasource;
  final PersonaCacheService _cacheService;

  List<Persona>? _cachedPersonas;
  Map<String, Persona>? _byCodigoSolapin;
  Map<String, Persona>? _bySolapin;

  PersonaRepositoryImpl(this._apiDatasource, this._cacheService);

  @override
  Future<List<Persona>> getAllPersonas({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPersonas != null && _cachedPersonas!.isNotEmpty) {
      return _cachedPersonas!;
    }

    final cache = await _cacheService.loadCache();
    if (cache.isNotEmpty && !forceRefresh) {
      _cachedPersonas = cache;
      _buildIndexes(cache);
      return _cachedPersonas!;
    }

    return syncPersonas().then((_) => _cachedPersonas ?? []);
  }

  @override
  Future<PersonaSyncResult> syncPersonas() async {
    final result = await _apiDatasource.syncAllPersonas(onlyActive: true);

    await _cacheService.saveCacheWithMeta(
      result.personas,
      SyncMeta(
        lastSync: result.syncedAt,
        totalCount: result.totalCount,
      ),
    );

    _cachedPersonas = result.personas;
    _buildIndexes(result.personas);

    return result;
  }

  @override
  Future<Persona?> findByCodigoSolapin(String codigo) async {
    await _ensureLoaded();
    return _byCodigoSolapin?[codigo.toLowerCase()];
  }

  @override
  Future<Persona?> findBySolapin(String solapin) async {
    await _ensureLoaded();
    return _bySolapin?[solapin.toLowerCase()];
  }

  @override
  Future<bool> hasCache() async {
    if (_cachedPersonas != null && _cachedPersonas!.isNotEmpty) return true;
    final cache = await _cacheService.loadCache();
    return cache.isNotEmpty;
  }

  Future<void> _ensureLoaded() async {
    if (_cachedPersonas == null || _cachedPersonas!.isEmpty) {
      await getAllPersonas();
    }
  }

  void _buildIndexes(List<Persona> personas) {
    _byCodigoSolapin = {};
    _bySolapin = {};
    for (final persona in personas) {
      if (persona.codigoSolapin.isNotEmpty) {
        _byCodigoSolapin![persona.codigoSolapin.toLowerCase()] = persona;
      }
      if (persona.solapin.isNotEmpty) {
        _bySolapin![persona.solapin.toLowerCase()] = persona;
      }
    }
  }
}