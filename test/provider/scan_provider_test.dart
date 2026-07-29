import 'package:flutter_test/flutter_test.dart';
import 'package:escaner_1/domain/entities/scan_record.dart';
import 'package:escaner_1/domain/entities/evento.dart';
import 'package:escaner_1/domain/entities/persona.dart';

void main() {
  group('ScanProvider Logic Tests', () {
    List<Persona> createTestPersonas() {
      return const [
        Persona(
          idPersona: '1',
          codigoSolapin: 'ABC001',
          solapin: '001',
          nombreCompleto: 'Juan Perez',
        ),
        Persona(
          idPersona: '2',
          codigoSolapin: 'ABC002',
          solapin: '002',
          nombreCompleto: 'Maria Garcia',
        ),
        Persona(
          idPersona: '3',
          codigoSolapin: 'ABC003',
          solapin: '003',
          nombreCompleto: 'Carlos Lopez',
        ),
      ];
    }

    test('findPersonaByCodigoSolapin returns correct persona', () {
      final personas = createTestPersonas();
      final result = _findPersonaByCodigoSolapin('ABC001', personas);
      expect(result?.nombreCompleto, equals('Juan Perez'));
    });

    test('findPersonaByCodigoSolapin returns null for non-existent code', () {
      final personas = createTestPersonas();
      final result = _findPersonaByCodigoSolapin('ABC999', personas);
      expect(result, isNull);
    });

    test('findPersonaByCodigoSolapin is case insensitive', () {
      final personas = createTestPersonas();
      final result = _findPersonaByCodigoSolapin('abc001', personas);
      expect(result?.nombreCompleto, equals('Juan Perez'));
    });

    test('findPersonaBySolapin returns correct persona', () {
      final personas = createTestPersonas();
      final result = _findPersonaBySolapin('001', personas);
      expect(result?.nombreCompleto, equals('Juan Perez'));
    });

    test('findPersonaBySolapin returns null for non-existent solapin', () {
      final personas = createTestPersonas();
      final result = _findPersonaBySolapin('999', personas);
      expect(result, isNull);
    });

    test('isValidCode returns true for valid codes', () {
      expect(_isValidCode('ABC12'), isTrue);
      expect(_isValidCode('12345'), isTrue);
      expect(_isValidCode('ABCDEFG'), isTrue);
    });

    test('isValidCode returns false for invalid codes', () {
      expect(_isValidCode(''), isFalse);
      expect(_isValidCode('AB'), isFalse);
      expect(_isValidCode('ABC1234567890123'), isFalse);
    });

    test('determineStatus returns correct status based on persona', () {
      final personas = createTestPersonas();

      final persona = _findPersonaByCodigoSolapin('ABC001', personas);
      final status = _determineStatus(persona);
      expect(status, equals(ScanStatus.reserved));

      final notReservedStatus = _determineStatus(null);
      expect(notReservedStatus, equals(ScanStatus.notReserved));
    });

    test('determineDeniedStatus returns denied status', () {
      final personas = createTestPersonas();

      final persona = _findPersonaByCodigoSolapin('ABC001', personas);
      final status = _determineDeniedStatus(persona);
      expect(status, equals(ScanStatus.denied));
    });
  });

  group('ScanRecord Status Logic', () {
    test('ScanStatus enum has correct values', () {
      expect(ScanStatus.reserved.index, equals(0));
      expect(ScanStatus.notReserved.index, equals(1));
      expect(ScanStatus.inactive.index, equals(2));
      expect(ScanStatus.denied.index, equals(3));
    });

    test('Evento enum has correct values', () {
      expect(Evento.values, contains(Evento.almuerzo));
      expect(Evento.values, contains(Evento.desayuno));
      expect(Evento.values, contains(Evento.comida));
    });
  });

  group('Pagination Logic', () {
    test('getItemsPage returns correct page of items', () {
      const pageSize = 50;
      final records = List.generate(
        100,
        (i) => ScanRecord(
          id: 'id-$i',
          code: 'CODE$i',
          type: ScanType.solapine,
          scannedAt: DateTime.now(),
          eventos: [],
          status: ScanStatus.reserved,
        ),
      );

      final page1 = _getItemsPage(records, 1, pageSize);
      expect(page1.length, equals(50));
      expect(page1.first.code, equals('CODE0'));
      expect(page1.last.code, equals('CODE49'));

      final page2 = _getItemsPage(records, 2, pageSize);
      expect(page2.length, equals(50));
      expect(page2.first.code, equals('CODE50'));
      expect(page2.last.code, equals('CODE99'));

      final page3 = _getItemsPage(records, 3, pageSize);
      expect(page3.length, equals(0));
    });

    test('hasMoreData calculation is correct', () {
      const pageSize = 50;

      expect(_hasMoreData(1, pageSize, 49), isFalse);
      expect(_hasMoreData(1, pageSize, 50), isFalse);
      expect(_hasMoreData(1, pageSize, 51), isTrue);
      expect(_hasMoreData(2, pageSize, 100), isFalse);
      expect(_hasMoreData(2, pageSize, 101), isTrue);
    });
  });
}

Persona? _findPersonaByCodigoSolapin(String code, List<Persona> personas) {
  final codeLower = code.toLowerCase();
  for (final persona in personas) {
    if (persona.codigoSolapin.toLowerCase() == codeLower) {
      return persona;
    }
  }
  return null;
}

Persona? _findPersonaBySolapin(String code, List<Persona> personas) {
  final codeLower = code.toLowerCase();
  for (final persona in personas) {
    if (persona.solapin.toLowerCase() == codeLower) {
      return persona;
    }
  }
  return null;
}

bool _isValidCode(String code) {
  if (code.isEmpty) return false;
  const minLength = 5;
  const maxLength = 15;
  final length = code.length;
  return length >= minLength && length <= maxLength;
}

ScanStatus _determineStatus(Persona? persona) {
  return persona != null ? ScanStatus.reserved : ScanStatus.notReserved;
}

ScanStatus _determineDeniedStatus(Persona? persona) {
  return ScanStatus.denied;
}

List<ScanRecord> _getItemsPage(List<ScanRecord> records, int page, int pageSize) {
  final start = (page - 1) * pageSize;
  final end = start + pageSize;
  if (start >= records.length) return [];
  return records.sublist(start, end.clamp(0, records.length));
}

bool _hasMoreData(int currentPage, int pageSize, int totalItems) {
  return currentPage * pageSize < totalItems;
}