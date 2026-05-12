import 'package:flutter_test/flutter_test.dart';
import 'package:escaner_1/domain/entities/scan_item.dart';
import 'package:escaner_1/domain/entities/evento.dart';

void main() {
  group('ScanItem', () {
    group('constructor', () {
      test('creates ScanItem with required fields', () {
        final now = DateTime.now();
        final item = ScanItem(
          code: 'ABC123',
          type: ScanType.solapine,
          scannedAt: now,
        );

        expect(item.code, equals('ABC123'));
        expect(item.type, equals(ScanType.solapine));
        expect(item.scannedAt, equals(now));
        expect(item.isDuplicate, isFalse);
        expect(item.status, equals(ScanStatus.reserved));
      });

      test('creates ScanItem with all fields', () {
        final now = DateTime.now();
        final item = ScanItem(
          code: 'ABC123',
          type: ScanType.solapine,
          isDuplicate: true,
          scannedAt: now,
          evento: Evento.almuerzo,
          personaSolapine: '001',
          personaNombre: 'Juan Perez',
          status: ScanStatus.duplicate,
        );

        expect(item.code, equals('ABC123'));
        expect(item.type, equals(ScanType.solapine));
        expect(item.isDuplicate, isTrue);
        expect(item.scannedAt, equals(now));
        expect(item.evento, equals(Evento.almuerzo));
        expect(item.personaSolapine, equals('001'));
        expect(item.personaNombre, equals('Juan Perez'));
        expect(item.status, equals(ScanStatus.duplicate));
      });

      test('default values are applied correctly', () {
        final now = DateTime.now();
        final item = ScanItem(
          code: 'ABC123',
          type: ScanType.tarjeta,
          scannedAt: now,
        );

        expect(item.isDuplicate, isFalse);
        expect(item.evento, isNull);
        expect(item.personaSolapine, isNull);
        expect(item.personaNombre, isNull);
        expect(item.status, equals(ScanStatus.reserved));
      });
    });

    group('copyWith', () {
      test('copies with new code', () {
        final original = ScanItem(
          code: 'ABC123',
          type: ScanType.solapine,
          scannedAt: DateTime.now(),
        );

        final copied = original.copyWith(code: 'XYZ789');

        expect(copied.code, equals('XYZ789'));
        expect(copied.type, equals(original.type));
        expect(copied.scannedAt, equals(original.scannedAt));
      });

      test('copies with new isDuplicate', () {
        final original = ScanItem(
          code: 'ABC123',
          type: ScanType.solapine,
          isDuplicate: false,
          scannedAt: DateTime.now(),
        );

        final copied = original.copyWith(isDuplicate: true);

        expect(copied.isDuplicate, isTrue);
        expect(copied.code, equals(original.code));
      });

      test('copies with new status', () {
        final original = ScanItem(
          code: 'ABC123',
          type: ScanType.solapine,
          status: ScanStatus.reserved,
          scannedAt: DateTime.now(),
        );

        final copied = original.copyWith(status: ScanStatus.notReserved);

        expect(copied.status, equals(ScanStatus.notReserved));
        expect(copied.code, equals(original.code));
      });

      test('copies with persona info', () {
        final original = ScanItem(
          code: 'ABC123',
          type: ScanType.solapine,
          scannedAt: DateTime.now(),
        );

        final copied = original.copyWith(
          personaSolapine: '001',
          personaNombre: 'Juan Perez',
        );

        expect(copied.personaSolapine, equals('001'));
        expect(copied.personaNombre, equals('Juan Perez'));
      });

      test('preserves all other fields when copying single field', () {
        final now = DateTime.now();
        final original = ScanItem(
          code: 'ABC123',
          type: ScanType.solapine,
          isDuplicate: true,
          scannedAt: now,
          evento: Evento.almuerzo,
          personaSolapine: '001',
          personaNombre: 'Juan Perez',
          status: ScanStatus.duplicate,
        );

        final copied = original.copyWith(status: ScanStatus.notReservedDuplicate);

        expect(copied.code, equals('ABC123'));
        expect(copied.type, equals(ScanType.solapine));
        expect(copied.isDuplicate, isTrue);
        expect(copied.scannedAt, equals(now));
        expect(copied.evento, equals(Evento.almuerzo));
        expect(copied.personaSolapine, equals('001'));
        expect(copied.personaNombre, equals('Juan Perez'));
        expect(copied.status, equals(ScanStatus.notReservedDuplicate));
      });
    });
  });

  group('ScanStatus', () {
    test('has all expected values', () {
      expect(ScanStatus.values, contains(ScanStatus.reserved));
      expect(ScanStatus.values, contains(ScanStatus.notReserved));
      expect(ScanStatus.values, contains(ScanStatus.duplicate));
      expect(ScanStatus.values, contains(ScanStatus.notReservedDuplicate));
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
}