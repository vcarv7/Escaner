import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:escaner_1/data/datasources/persona_api_datasource.dart';
import 'package:escaner_1/data/repositories/persona_repository_impl.dart';
import 'package:escaner_1/data/services/api_client.dart';
import 'package:escaner_1/data/services/persona_cache_service.dart';
import 'package:escaner_1/domain/entities/persona.dart';
import 'package:escaner_1/domain/repositories/persona_repository.dart';

/// Datasource que explota si alguien toca red. Si el repositorio está en
/// modo solo-manual, este método jamás debe ejecutarse desde `getAllPersonas`.
class _NoNetworkDatasource extends PersonaApiDatasource {
  int calls = 0;

  _NoNetworkDatasource() : super(ApiClient());

  @override
  Future<PersonaSyncResult> syncAllPersonas({
    bool onlyActive = true,
    SyncProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) {
    calls++;
    throw StateError('getAllPersonas tocó red: solo el botón puede hacerlo');
  }
}

class _MemoryCache extends PersonaCacheService {
  List<Persona> personas;
  _MemoryCache(this.personas);

  @override
  Future<List<Persona>> loadCache() async => personas;
}

Persona _p(String id) => Persona(
      idPersona: id,
      codigoSolapin: 'C$id',
      solapin: 'S$id',
      nombreCompleto: 'P $id',
    );

void main() {
  group('Repositorio solo-manual: getAllPersonas jamás toca red', () {
    test('disco vacío → [] sin llamar al datasource', () async {
      final datasource = _NoNetworkDatasource();
      final repo = PersonaRepositoryImpl(
        datasource,
        _MemoryCache(const []),
      );

      final result = await repo.getAllPersonas();

      expect(result, isEmpty);
      expect(datasource.calls, 0);
    });

    test('disco con datos → los devuelve sin llamar al datasource', () async {
      final datasource = _NoNetworkDatasource();
      final repo = PersonaRepositoryImpl(
        datasource,
        _MemoryCache([_p('1'), _p('2')]),
      );

      final result = await repo.getAllPersonas();

      expect(result, hasLength(2));
      expect(datasource.calls, 0);
    });

    test('findBy* con vacío → null sin red (scan offline)', () async {
      final datasource = _NoNetworkDatasource();
      final repo = PersonaRepositoryImpl(
        datasource,
        _MemoryCache(const []),
      );

      expect(await repo.findByCodigoSolapin('C1'), isNull);
      expect(await repo.findBySolapin('S1'), isNull);
      expect(datasource.calls, 0);
    });
  });
}
