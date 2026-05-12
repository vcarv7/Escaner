import 'package:flutter_test/flutter_test.dart';
import 'package:escaner_1/domain/entities/persona.dart';

void main() {
  group('Persona', () {
    group('constructor', () {
      test('creates Persona with all required fields', () {
        const persona = Persona(
          idPersona: '1',
          codigoSolapin: 'ABC001',
          solapin: '001',
          nombreCompleto: 'Juan Perez',
        );

        expect(persona.idPersona, equals('1'));
        expect(persona.codigoSolapin, equals('ABC001'));
        expect(persona.solapin, equals('001'));
        expect(persona.nombreCompleto, equals('Juan Perez'));
      });

      test('creates Persona with empty strings', () {
        const persona = Persona(
          idPersona: '',
          codigoSolapin: '',
          solapin: '',
          nombreCompleto: '',
        );

        expect(persona.idPersona, isEmpty);
        expect(persona.codigoSolapin, isEmpty);
        expect(persona.solapin, isEmpty);
        expect(persona.nombreCompleto, isEmpty);
      });
    });

    group('fromMap', () {
      test('creates Persona from valid map', () {
        final map = {
          'idPersona': '1',
          'codigoSolapin': 'ABC001',
          'solapin': '001',
          'nombreCompleto': 'Juan Perez',
        };

        final persona = Persona.fromMap(map);

        expect(persona.idPersona, equals('1'));
        expect(persona.codigoSolapin, equals('ABC001'));
        expect(persona.solapin, equals('001'));
        expect(persona.nombreCompleto, equals('Juan Perez'));
      });

      test('creates Persona from map with null values', () {
        final map = <String, dynamic>{
          'idPersona': null,
          'codigoSolapin': null,
          'solapin': null,
          'nombreCompleto': null,
        };

        final persona = Persona.fromMap(map);

        expect(persona.idPersona, equals(''));
        expect(persona.codigoSolapin, equals(''));
        expect(persona.solapin, equals(''));
        expect(persona.nombreCompleto, equals(''));
      });

      test('creates Persona from map with missing keys', () {
        final map = <String, dynamic>{};

        final persona = Persona.fromMap(map);

        expect(persona.idPersona, equals(''));
        expect(persona.codigoSolapin, equals(''));
        expect(persona.solapin, equals(''));
        expect(persona.nombreCompleto, equals(''));
      });
    });

    group('toMap', () {
      test('converts Persona to map correctly', () {
        const persona = Persona(
          idPersona: '1',
          codigoSolapin: 'ABC001',
          solapin: '001',
          nombreCompleto: 'Juan Perez',
        );

        final map = persona.toMap();

        expect(map['idPersona'], equals('1'));
        expect(map['codigoSolapin'], equals('ABC001'));
        expect(map['solapin'], equals('001'));
        expect(map['nombreCompleto'], equals('Juan Perez'));
      });

      test('roundtrip: fromMap -> toMap -> fromMap preserves data', () {
        const original = Persona(
          idPersona: '42',
          codigoSolapin: 'SOL42',
          solapin: '42',
          nombreCompleto: 'Maria Garcia',
        );

        final map = original.toMap();
        final restored = Persona.fromMap(map);

        expect(restored.idPersona, equals(original.idPersona));
        expect(restored.codigoSolapin, equals(original.codigoSolapin));
        expect(restored.solapin, equals(original.solapin));
        expect(restored.nombreCompleto, equals(original.nombreCompleto));
      });
    });
  });
}