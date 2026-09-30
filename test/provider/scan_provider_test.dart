import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:escaner_1/domain/entities/evento.dart';
import 'package:escaner_1/domain/entities/persona.dart';
import 'package:escaner_1/domain/entities/scan_record.dart';
import 'package:escaner_1/presentation/providers/persona_provider.dart';
import 'package:escaner_1/presentation/providers/scan_provider.dart';

import 'persona_provider_test.mocks.dart';

void main() {
  late PersonaProvider personaProvider;
  late ScanProvider scanProvider;
  late DateTime hoy;

  setUp(() async {
    final mockRepository = MockPersonaRepository();
    final mockCacheService = MockPersonaCacheService();
    personaProvider = PersonaProvider(
      repository: mockRepository,
      cacheService: mockCacheService,
    );
    when(mockRepository.getAllPersonas()).thenAnswer((_) async => const [
          Persona(idPersona: '1', codigoSolapin: 'ABC001', solapin: '001',
              nombreCompleto: 'Juan Perez'),
        ]);
    when(mockRepository.hasCache()).thenAnswer((_) async => true);
    when(mockCacheService.loadMeta()).thenAnswer((_) async => null);
    await personaProvider.loadFromCache();

    scanProvider = ScanProvider();
    hoy = DateTime.now();
  });

  tearDown(() {
    personaProvider.dispose();
    scanProvider.dispose();
  });

  ScanRecord? recordDe(String code) {
    final matches = scanProvider.records
        .where((r) => r.code.toUpperCase() == code.toUpperCase())
        .toList();
    return matches.isEmpty ? null : matches.last;
  }

  group('processScan - caso C (código nuevo)', () {
    test('resuelve contra el catálogo local y queda reserved', () {
      final isNew = scanProvider.processScan(
          'ABC001', Evento.desayuno, '1', personaProvider);

      expect(isNew, isTrue);
      final record = recordDe('ABC001');
      expect(record, isNotNull);
      expect(record!.status, ScanStatus.reserved);
      expect(record.personaNombre, 'Juan Perez');
      expect(record.eventos.single.evento, Evento.desayuno);
      expect(record.eventos.single.status, ScanStatus.reserved);
    });

    test('código en minúsculas se normaliza y resuelve igual', () {
      scanProvider.processScan('abc001', Evento.desayuno, null, personaProvider);

      final record = recordDe('ABC001');
      expect(record, isNotNull);
      expect(record!.code, 'ABC001');
      expect(record.status, ScanStatus.reserved);
    });

    test('código desconocido queda inactive', () {
      final isNew = scanProvider.processScan(
          'XYZ999', Evento.almuerzo, null, personaProvider);

      expect(isNew, isTrue);
      final record = recordDe('XYZ999');
      expect(record!.status, ScanStatus.inactive);
      expect(record.eventos.single.status, ScanStatus.inactive);
    });

    test('código inválido (símbolos) no registra nada', () {
      final isNew = scanProvider.processScan('!!!!!', Evento.desayuno, null, personaProvider);

      expect(isNew, isFalse);
      expect(scanProvider.records, isEmpty);
    });
  });

  group('processScan - caso A (duplicado mismo evento y día)', () {
    test('queda denied para ese evento y el registro global refleja denied', () {
      scanProvider.processScan('ABC001', Evento.desayuno, '1', personaProvider);
      final isNew = scanProvider.processScan('ABC001', Evento.desayuno, '1', personaProvider);

      expect(isNew, isFalse);
      final record = recordDe('ABC001')!;
      expect(record.status, ScanStatus.denied);
      expect(record.eventos.length, 2);
      expect(record.eventos.last.status, ScanStatus.denied);
      expect(record.eventos.first.status, ScanStatus.reserved);
    });
  });

  group('processScan - caso B (otro evento o día)', () {
    test('otro evento el mismo día pasa y desmarca el registro', () {
      scanProvider.processScan('ABC001', Evento.desayuno, '1', personaProvider);
      scanProvider.processScan('ABC001', Evento.desayuno, '1', personaProvider);
      final isNew = scanProvider.processScan('ABC001', Evento.almuerzo, '1', personaProvider);

      expect(isNew, isTrue);
      final record = recordDe('ABC001')!;
      expect(record.status, ScanStatus.reserved);
      expect(record.eventos.map((e) => e.evento),
          orderedEquals([Evento.desayuno, Evento.desayuno, Evento.almuerzo]));
      expect(record.eventos.map((e) => e.status),
          orderedEquals([ScanStatus.reserved, ScanStatus.denied, ScanStatus.reserved]));
    });

    test('otro evento el mismo día sin persona queda inactive pero pasa', () {
      scanProvider.processScan('XYZ999', Evento.desayuno, null, personaProvider);
      final isNew = scanProvider.processScan('XYZ999', Evento.comida, null, personaProvider);

      expect(isNew, isTrue);
      expect(recordDe('XYZ999')!.eventos.length, 2);
    });

    test('el mismo evento al día siguiente vuelve a pasar (dedup es por día)', () {
      scanProvider.processScan('ABC001', Evento.desayuno, '1', personaProvider);
      final manana = hoy.add(const Duration(days: 1));
      final isNew = scanProvider.processScan(
          'ABC001', Evento.desayuno, '1', personaProvider, timestamp: manana);

      expect(isNew, isTrue);
      final record = recordDe('ABC001')!;
      expect(record.status, ScanStatus.reserved);
      expect(record.eventos.map((e) => e.status),
          orderedEquals([ScanStatus.reserved, ScanStatus.reserved]));
    });
  });

  group('persistencia del status por EventoScan', () {
    test('fromJson sin status migra a reserved', () {
      final eventoScan = EventoScan.fromJson({
        'evento': 'almuerzo',
        'timestamp': DateTime(2026, 9, 29, 12, 30).toIso8601String(),
        'puerta': '1',
      });

      expect(eventoScan.status, ScanStatus.reserved);
    });

    test('fromJson respeta el status guardado', () {
      final eventoScan = EventoScan.fromJson({
        'evento': 'desayuno',
        'timestamp': DateTime(2026, 9, 29, 8, 0).toIso8601String(),
        'puerta': null,
        'status': 'denied',
      });

      expect(eventoScan.status, ScanStatus.denied);
    });

    test('round-trip del registro conserva status de eventos', () {
      final record = ScanRecord(
        id: 'id-1',
        code: 'ABC001',
        type: ScanType.solapine,
        scannedAt: DateTime(2026, 9, 29, 8, 0),
        personaId: '1',
        personaSolapine: '001',
        personaNombre: 'Juan Perez',
        eventos: [
          EventoScan(
            evento: Evento.desayuno,
            timestamp: DateTime(2026, 9, 29, 8, 0),
            status: ScanStatus.reserved,
          ),
        ],
        status: ScanStatus.denied,
      );

      final restored = ScanRecord.fromJson(record.toJson());

      expect(restored.status, ScanStatus.denied);
      expect(restored.eventos.single.status, ScanStatus.reserved);
    });
  });
}