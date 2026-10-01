import 'package:flutter_test/flutter_test.dart';
import 'package:escaner_1/domain/entities/scan_record.dart';
import 'package:escaner_1/domain/entities/evento.dart';

void main() {
  group('ScanRecord', () {
    group('constructor', () {
      test('creates ScanRecord with required fields', () {
        final now = DateTime.now();
        final record = ScanRecord(
          id: 'test-id',
          code: 'ABC123',
          type: ScanType.solapine,
          scannedAt: now,
          eventos: [],
          status: ScanStatus.reserved,
        );

        expect(record.id, equals('test-id'));
        expect(record.code, equals('ABC123'));
        expect(record.type, equals(ScanType.solapine));
        expect(record.scannedAt, equals(now));
        expect(record.eventos, isEmpty);
        expect(record.status, equals(ScanStatus.reserved));
        expect(record.isDuplicate, isFalse);
        expect(record.categoriaResidente, equals(1));
      });

      test('creates ScanRecord with all fields', () {
        final now = DateTime.now();
        final eventos = [EventoScan(evento: Evento.almuerzo, timestamp: now)];
        final record = ScanRecord(
          id: 'test-id',
          code: 'ABC123',
          type: ScanType.solapine,
          scannedAt: now,
          personaId: '1',
          personaSolapine: '001',
          personaNombre: 'Juan Perez',
          categoriaResidente: 2,
          eventos: eventos,
          status: ScanStatus.denied,
          isDuplicate: true,
        );

        expect(record.id, equals('test-id'));
        expect(record.code, equals('ABC123'));
        expect(record.type, equals(ScanType.solapine));
        expect(record.scannedAt, equals(now));
        expect(record.personaId, equals('1'));
        expect(record.personaSolapine, equals('001'));
        expect(record.personaNombre, equals('Juan Perez'));
        expect(record.categoriaResidente, equals(2));
        expect(record.eventos, equals(eventos));
        expect(record.status, equals(ScanStatus.denied));
        expect(record.isDuplicate, isTrue);
      });
    });

    group('copyWith', () {
      test('copies with new code', () {
        final original = ScanRecord(
          id: 'test-id',
          code: 'ABC123',
          type: ScanType.solapine,
          scannedAt: DateTime.now(),
          eventos: [],
          status: ScanStatus.reserved,
        );

        final copied = original.copyWith(code: 'XYZ789');

        expect(copied.code, equals('XYZ789'));
        expect(copied.type, equals(original.type));
        expect(copied.scannedAt, equals(original.scannedAt));
      });

      test('copies with new status', () {
        final original = ScanRecord(
          id: 'test-id',
          code: 'ABC123',
          type: ScanType.solapine,
          scannedAt: DateTime.now(),
          eventos: [],
          status: ScanStatus.reserved,
        );

        final copied = original.copyWith(status: ScanStatus.denied);

        expect(copied.status, equals(ScanStatus.denied));
        expect(copied.code, equals(original.code));
      });

      test('copies with new eventos', () {
        final original = ScanRecord(
          id: 'test-id',
          code: 'ABC123',
          type: ScanType.solapine,
          scannedAt: DateTime.now(),
          eventos: [],
          status: ScanStatus.reserved,
        );

        final newEventos = [EventoScan(evento: Evento.almuerzo, timestamp: DateTime.now())];
        final copied = original.copyWith(eventos: newEventos);

        expect(copied.eventos, equals(newEventos));
        expect(copied.code, equals(original.code));
      });
    });

    group('toJson/fromJson', () {
      test('serializes and deserializes correctly', () {
        final now = DateTime.now();
        final record = ScanRecord(
          id: 'test-id',
          code: 'ABC123',
          type: ScanType.solapine,
          scannedAt: now,
          personaId: '1',
          personaSolapine: '001',
          personaNombre: 'Juan Perez',
          categoriaResidente: 2,
          eventos: [EventoScan(evento: Evento.almuerzo, timestamp: now, puerta: '111')],
          status: ScanStatus.reserved,
          isDuplicate: false,
        );

        final json = record.toJson();
        final deserialized = ScanRecord.fromJson(json);

        expect(deserialized.id, equals(record.id));
        expect(deserialized.code, equals(record.code));
        expect(deserialized.type, equals(record.type));
        expect(deserialized.scannedAt, equals(record.scannedAt));
        expect(deserialized.personaId, equals(record.personaId));
        expect(deserialized.personaSolapine, equals(record.personaSolapine));
        expect(deserialized.personaNombre, equals(record.personaNombre));
        expect(deserialized.categoriaResidente, equals(record.categoriaResidente));
        expect(deserialized.eventos.length, equals(record.eventos.length));
        expect(deserialized.eventos.first.evento, equals(record.eventos.first.evento));
        expect(deserialized.eventos.first.puerta, equals(record.eventos.first.puerta));
        expect(deserialized.status, equals(record.status));
        expect(deserialized.isDuplicate, equals(record.isDuplicate));
      });
    });
  });

  group('ScanStatus', () {
    test('has all expected values', () {
      expect(ScanStatus.values, contains(ScanStatus.reserved));
      expect(ScanStatus.values, contains(ScanStatus.notReserved));
      expect(ScanStatus.values, contains(ScanStatus.inactive));
      expect(ScanStatus.values, contains(ScanStatus.denied));
    });

    test('has exactly 4 values', () {
      expect(ScanStatus.values.length, equals(4));
    });
  });

  group('ScanType', () {
    test('has all expected values', () {
      expect(ScanType.values, contains(ScanType.solapine));
      expect(ScanType.values, contains(ScanType.tarjeta));
    });

    test('has exactly 2 values', () {
      expect(ScanType.values.length, equals(2));
    });
  });

  group('EventoScan', () {
    test('serializes and deserializes correctly', () {
      final now = DateTime.now();
      final eventoScan = EventoScan(
        evento: Evento.almuerzo,
        timestamp: now,
        puerta: '111',
      );

      final json = eventoScan.toJson();
      final deserialized = EventoScan.fromJson(json);

      expect(deserialized.evento, equals(eventoScan.evento));
      expect(deserialized.timestamp, equals(eventoScan.timestamp));
      expect(deserialized.puerta, equals(eventoScan.puerta));
    });

    test('serializes without puerta', () {
      final now = DateTime.now();
      final eventoScan = EventoScan(
        evento: Evento.desayuno,
        timestamp: now,
      );

      final json = eventoScan.toJson();
      final deserialized = EventoScan.fromJson(json);

      expect(deserialized.puerta, isNull);
    });
  });
}