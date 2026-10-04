import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:escaner_1/domain/entities/persona.dart';
import 'package:escaner_1/domain/repositories/persona_repository.dart';
import 'package:escaner_1/data/services/persona_cache_service.dart';
import 'package:escaner_1/presentation/providers/persona_provider.dart';

class _FakeRepo implements PersonaRepository {
  SyncProgressCallback? capturedOnProgress;
  CancelToken? capturedToken;
  int syncCalls = 0;
  final Future<PersonaSyncResult> Function(
    SyncProgressCallback?,
    CancelToken?,
  )? behavior;

  _FakeRepo({this.behavior});

  @override
  Future<List<Persona>> getAllPersonas({bool forceRefresh = false}) async =>
      const [];

  @override
  Future<bool> hasCache() async => false;

  @override
  Future<void> clearSession() async {}

  @override
  Future<Persona?> findByCodigoSolapin(String codigo) async => null;

  @override
  Future<Persona?> findBySolapin(String solapin) async => null;

  @override
  Future<PersonaSyncResult> syncPersonas({
    SyncProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) {
    syncCalls++;
    capturedOnProgress = onProgress;
    capturedToken = cancelToken;
    if (behavior != null) return behavior!(onProgress, cancelToken);
    throw UnimplementedError();
  }
}

Persona _p(String id) => Persona(
      idPersona: id,
      codigoSolapin: 'C$id',
      solapin: 'S$id',
      nombreCompleto: 'P $id',
    );

void main() {
  group('PersonaProvider sync con progreso', () {
    test('reporta páginas y calcula progreso 0..1', () async {
      final repo = _FakeRepo(
        behavior: (onProgress, _) async {
          onProgress?.call(
            paginaActual: 1,
            totalPaginas: 10,
            recibidos: 50,
          );
          onProgress?.call(
            paginaActual: 5,
            totalPaginas: 10,
            recibidos: 250,
          );
          return PersonaSyncResult(
            personas: [_p('1')],
            totalCount: 1,
            totalPages: 10,
            syncedAt: DateTime(2026, 1, 1),
          );
        },
      );
      final provider = PersonaProvider(
        repository: repo,
        cacheService: PersonaCacheService(),
      );
      addTearDown(provider.dispose);

      final ok = await provider.syncPersonas();

      expect(ok, isTrue);
      expect(provider.syncPaginaActual, 5);
      expect(provider.syncTotalPaginas, 10);
      expect(provider.syncRecibidos, 250);
      expect(provider.syncProgress, 0.5);
      expect(provider.isSyncing, isFalse);
    });

    test('cancelar conserva la lista previa sin marcar error', () async {
      final repo = _FakeRepo(
        behavior: (onProgress, cancelToken) async {
          onProgress?.call(
            paginaActual: 2,
            totalPaginas: 10,
            recibidos: 100,
          );
          // Espera hasta que el provider cancele el token.
          await cancelToken!.whenCancel;
          throw DioException(
            requestOptions: RequestOptions(path: '/personas'),
            type: DioExceptionType.cancel,
          );
        },
      );
      final provider = PersonaProvider(
        repository: repo,
        cacheService: PersonaCacheService(),
      );
      addTearDown(provider.dispose);

      final future = provider.syncPersonas();
      // Dar tiempo a que llegue a página 2 antes de cancelar.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.isSyncing, isTrue);

      await provider.cancelSync();
      final ok = await future;

      expect(ok, isFalse);
      expect(provider.syncWasCancelled, isTrue);
      expect(provider.error, isNull);
      expect(provider.isSyncing, isFalse);
      expect(provider.isCancelling, isFalse);
    });

    test('doble sync no lanza dos descargas', () async {
      var calls = 0;
      final repo = _FakeRepo(
        behavior: (_, _) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return PersonaSyncResult(
            personas: const [],
            totalCount: 0,
            totalPages: 1,
            syncedAt: DateTime(2026, 1, 1),
          );
        },
      );
      final provider = PersonaProvider(
        repository: repo,
        cacheService: PersonaCacheService(),
      );
      addTearDown(provider.dispose);

      final f1 = provider.syncPersonas();
      final f2 = await provider.syncPersonas();
      await f1;

      expect(f2, isFalse);
      expect(calls, 1);
    });
  });

  group('PersonaProvider solo-manual: login/arranque no descargan', () {
    test('loadFromCache con vacío → vacia, sin error y sin red', () async {
      final repo = _FakeRepo();
      final provider = PersonaProvider(
        repository: repo,
        cacheService: PersonaCacheService(),
      );
      addTearDown(provider.dispose);

      await provider.loadFromCache();

      expect(provider.status, PersonaListStatus.vacia);
      expect(provider.error, isNull);
      expect(provider.puedeEscanear, isFalse);
      expect(repo.syncCalls, 0);
    });
  });
}
