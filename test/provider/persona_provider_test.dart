import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:escaner_1/presentation/providers/persona_provider.dart';
import 'package:escaner_1/domain/entities/persona.dart';
import 'package:escaner_1/domain/repositories/persona_repository.dart';
import 'package:escaner_1/data/services/persona_cache_service.dart';

import 'persona_provider_test.mocks.dart';

@GenerateMocks([PersonaRepository, PersonaCacheService])

void main() {
  group('PersonaProvider.clearSession', () {
    late MockPersonaRepository mockRepository;
    late MockPersonaCacheService mockCacheService;
    late PersonaProvider provider;

    setUp(() {
      mockRepository = MockPersonaRepository();
      mockCacheService = MockPersonaCacheService();
      provider = PersonaProvider(
        repository: mockRepository,
        cacheService: mockCacheService,
      );
    });

    tearDown(() {
      provider.dispose();
    });

    Future<void> cargarPersonas() async {
      final personas = const [
        Persona(
          idPersona: '1',
          codigoSolapin: 'ABC123',
          solapin: '9999',
          nombreCompleto: 'Juan Perez',
        ),
        Persona(
          idPersona: '2',
          codigoSolapin: 'XYZ789',
          solapin: '8888',
          nombreCompleto: 'Ana Lopez',
        ),
      ];
      when(mockRepository.getAllPersonas()).thenAnswer((_) async => personas);
      when(mockRepository.hasCache()).thenAnswer((_) async => true);
      when(mockCacheService.loadMeta()).thenAnswer((_) async => null);
      await provider.loadFromCache();
    }

    test('vacía lista, índices y contadores', () async {
      await cargarPersonas();
      expect(provider.hasPersonas, isTrue);
      expect(provider.totalCount, 2);

      await provider.clearSession();

      expect(provider.hasPersonas, isFalse);
      expect(provider.personas, isEmpty);
      expect(provider.totalCount, 0);
      expect(provider.lastSync, isNull);
      expect(provider.findByCodigoSolapin('ABC123'), isNull);
      expect(provider.findBySolapin('9999'), isNull);
    });

    test('delega en el repositorio para limpiar su caché en memoria', () async {
      when(mockRepository.clearSession()).thenAnswer((_) async {});

      await provider.clearSession();

      verify(mockRepository.clearSession()).called(1);
    });

    test('NO borra la caché en disco', () async {
      when(mockRepository.clearSession()).thenAnswer((_) async {});

      await provider.clearSession();

      verifyNever(mockCacheService.clearCache());
    });

    test('notifica a listeners', () async {
      when(mockRepository.clearSession()).thenAnswer((_) async {});
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.clearSession();

      expect(notifyCount, 1);
    });

    test('permite recargar desde caché tras limpiar', () async {
      await cargarPersonas();
      when(mockRepository.clearSession()).thenAnswer((_) async {});
      await provider.clearSession();
      expect(provider.hasPersonas, isFalse);

      await provider.loadFromCache();

      expect(provider.hasPersonas, isTrue);
      expect(provider.totalCount, 2);
      expect(provider.findByCodigoSolapin('ABC123')?.nombreCompleto, 'Juan Perez');
    });
  });
}
