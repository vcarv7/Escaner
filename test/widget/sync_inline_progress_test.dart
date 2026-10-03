import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:escaner_1/domain/entities/persona.dart';
import 'package:escaner_1/domain/repositories/persona_repository.dart';
import 'package:escaner_1/data/services/persona_cache_service.dart';
import 'package:escaner_1/presentation/providers/persona_provider.dart';
import 'package:escaner_1/presentation/widgets/sync_progress_inline.dart';

class _HangingRepo implements PersonaRepository {
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
  }) async {
    // Nunca completa salvo cancelación: mantiene el inline en "Conectando".
    await cancelToken?.whenCancel;
    throw DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.cancel,
    );
  }
}

class _ProgressRepo implements PersonaRepository {
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
  }) async {
    onProgress?.call(paginaActual: 5, totalPaginas: 10, recibidos: 250);
    // Queda colgado para poder leer la línea de estado.
    await cancelToken?.whenCancel;
    throw DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.cancel,
    );
  }
}

Future<void> _pumpInline(
  WidgetTester tester,
  PersonaProvider provider,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<PersonaProvider>.value(
        value: provider,
        child: const Scaffold(body: SyncProgressInline()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('conectando: barra + aviso y Cancelar aborta sin error',
      (tester) async {
    final provider = PersonaProvider(
      repository: _HangingRepo(),
      cacheService: PersonaCacheService(),
    );
    addTearDown(provider.dispose);

    final future = provider.syncPersonas();
    await tester.pump();
    await _pumpInline(tester, provider);

    expect(find.byKey(const ValueKey('sync_progress_bar')), findsOneWidget);
    expect(find.textContaining('Conectando'), findsOneWidget);
    expect(find.byKey(const ValueKey('sync_cancel_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sync_cancel_button')));
    await tester.pump();

    final ok = await future;
    await tester.pump();
    expect(ok, isFalse);
    expect(provider.syncWasCancelled, isTrue);
    expect(provider.error, isNull);
    expect(provider.isSyncing, isFalse);
  });

  testWidgets('descargando: línea X de Y · N personas y barra a 0.5',
      (tester) async {
    final provider = PersonaProvider(
      repository: _ProgressRepo(),
      cacheService: PersonaCacheService(),
    );
    addTearDown(provider.dispose);

    final future = provider.syncPersonas();
    await tester.pump();
    await _pumpInline(tester, provider);

    expect(find.textContaining('página 5 de 10'), findsOneWidget);
    expect(find.textContaining('250 personas'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('sync_progress_bar')),
    );
    expect(bar.value, 0.5);

    await provider.cancelSync();
    await future;
  });
}
