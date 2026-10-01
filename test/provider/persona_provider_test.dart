import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:escaner_1/presentation/providers/persona_provider.dart';
import 'package:escaner_1/presentation/providers/scan_provider.dart';
import 'package:escaner_1/domain/entities/persona.dart';
import 'package:escaner_1/domain/entities/evento.dart';
import 'package:escaner_1/domain/entities/scan_record.dart';
import 'package:escaner_1/domain/repositories/persona_repository.dart';
import 'package:escaner_1/data/services/persona_cache_service.dart';
import 'package:escaner_1/data/services/session_events.dart';
import 'package:escaner_1/core/errors/app_exception.dart';

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

  group('PersonaProvider.status', () {
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
      when(mockCacheService.loadMeta()).thenAnswer((_) async => null);
    });

    tearDown(() {
      provider.dispose();
    });

    const dosPersonas = [
      Persona(
        idPersona: '1',
        codigoSolapin: 'ABC123',
        solapin: '9999',
        nombreCompleto: 'Juan Perez',
      ),
    ];

    test('arranca en cargando y no permite escanear todavía', () {
      expect(provider.status, PersonaListStatus.cargando);
      expect(provider.puedeEscanear, isFalse);
    });

    test('pasa a lista y habilita el escaneo', () async {
      when(mockRepository.getAllPersonas()).thenAnswer((_) async => dosPersonas);
      when(mockRepository.hasCache()).thenAnswer((_) async => true);

      await provider.loadFromCache();

      expect(provider.status, PersonaListStatus.lista);
      expect(provider.puedeEscanear, isTrue);
    });

    test('pasa a vacia si no hay nada en disco ni en red', () async {
      when(mockRepository.getAllPersonas()).thenAnswer((_) async => <Persona>[]);
      when(mockRepository.hasCache()).thenAnswer((_) async => false);

      await provider.loadFromCache();

      expect(provider.status, PersonaListStatus.vacia);
      expect(provider.puedeEscanear, isFalse);
      expect(provider.error, isNull);
    });

    test('pasa a error si la carga falla', () async {
      when(mockRepository.getAllPersonas())
          .thenThrow(AppException.timeout('sin red'));

      await provider.loadFromCache();

      expect(provider.status, PersonaListStatus.error);
      expect(provider.puedeEscanear, isFalse);
      expect(provider.error, isNotNull);
    });

    test('clearSession deja la lista vacía y bloquea el escaneo', () async {
      when(mockRepository.getAllPersonas()).thenAnswer((_) async => dosPersonas);
      when(mockRepository.hasCache()).thenAnswer((_) async => true);
      when(mockRepository.clearSession()).thenAnswer((_) async {});
      await provider.loadFromCache();
      expect(provider.puedeEscanear, isTrue);

      await provider.clearSession();

      expect(provider.status, PersonaListStatus.vacia);
      expect(provider.puedeEscanear, isFalse);
    });
  });

  group('PersonaProvider sobrevive a la expiración de sesión', () {
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
      const personas = [
        Persona(
          idPersona: '1',
          codigoSolapin: 'ABC123',
          solapin: '9999',
          nombreCompleto: 'Juan Perez',
        ),
      ];
      when(mockRepository.getAllPersonas()).thenAnswer((_) async => personas);
      when(mockRepository.hasCache()).thenAnswer((_) async => true);
      when(mockCacheService.loadMeta()).thenAnswer((_) async => null);
      await provider.loadFromCache();
    }

    test('la expiración NO vacía el catálogo en memoria', () async {
      await cargarPersonas();
      expect(provider.puedeEscanear, isTrue);

      SessionEvents.instance.notifyExpired();
      await Future<void>.delayed(Duration.zero);

      expect(provider.hasPersonas, isTrue);
      expect(provider.status, PersonaListStatus.lista);
      expect(provider.puedeEscanear, isTrue);
      expect(
        provider.findByCodigoSolapin('ABC123')?.nombreCompleto,
        'Juan Perez',
      );
    });

    test('el escaneo sigue resolviendo contra la lista local tras expirar', () async {
      // Es el resultado que ve el operador: expirar la sesión no puede volver
      // a marcar como "Usuario Inactivo" a un residente ya sincronizado.
      await cargarPersonas();
      final scanProvider = ScanProvider();
      addTearDown(scanProvider.dispose);

      SessionEvents.instance.notifyExpired();
      await Future<void>.delayed(Duration.zero);

      final esNuevo = scanProvider.processScan(
        'ABC123',
        Evento.almuerzo,
        'Puerta 1',
        provider,
      );

      expect(esNuevo, isTrue);
      expect(scanProvider.records, hasLength(1));
      expect(scanProvider.records.first.status, ScanStatus.reserved);
      expect(scanProvider.records.first.personaNombre, 'Juan Perez');
    });
  });
}
