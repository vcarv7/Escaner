import 'package:flutter_test/flutter_test.dart';
import 'package:escaner_1/core/utils/validation_utils.dart';
import 'package:escaner_1/domain/entities/scan_record.dart';

void main() {
  group('ValidationUtils', () {
    group('isValidSolapine', () {
      test('returns true for valid solapine with 5 characters', () {
        expect(ValidationUtils.isValidSolapine('ABC12'), isTrue);
      });

      test('returns true for valid solapine with 10 characters', () {
        expect(ValidationUtils.isValidSolapine('ABC1234567'), isTrue);
      });

      test('returns true for valid solapine with 15 characters', () {
        expect(ValidationUtils.isValidSolapine('ABC123456789012'), isTrue);
      });

      test('returns false for empty string', () {
        expect(ValidationUtils.isValidSolapine(''), isFalse);
      });

      test('returns false for string shorter than 5 characters', () {
        expect(ValidationUtils.isValidSolapine('AB12'), isFalse);
      });

      test('returns false for string longer than 15 characters', () {
        expect(ValidationUtils.isValidSolapine('ABC1234567890123'), isFalse);
      });

      test('returns true for string with only numbers', () {
        expect(ValidationUtils.isValidSolapine('12345'), isTrue);
      });

      test('returns true for string with mixed case', () {
        expect(ValidationUtils.isValidSolapine('AbC12'), isTrue);
      });
    });

    group('isValidTarjeta', () {
      test('returns true for valid tarjeta with only letters', () {
        expect(ValidationUtils.isValidTarjeta('ABCDEF'), isTrue);
      });

      test('returns true for valid tarjeta with minimum length', () {
        expect(ValidationUtils.isValidTarjeta('ABCDE'), isTrue);
      });

      test('returns true for valid tarjeta with maximum length', () {
        expect(ValidationUtils.isValidTarjeta('ABCDEFGHIJKLMNO'), isTrue);
      });

      test('returns false for empty string', () {
        expect(ValidationUtils.isValidTarjeta(''), isFalse);
      });

      test('returns false for string with numbers', () {
        expect(ValidationUtils.isValidTarjeta('ABC12'), isFalse);
      });

      test('returns false for string shorter than 5 characters', () {
        expect(ValidationUtils.isValidTarjeta('ABCD'), isFalse);
      });

      test('returns false for string longer than 15 characters', () {
        expect(ValidationUtils.isValidTarjeta('ABCDEFGHIJKLMNOP'), isFalse);
      });

      test('returns false for single letter string', () {
        expect(ValidationUtils.isValidTarjeta('A'), isFalse);
      });
    });

    group('isValidCode', () {
      test('returns true for valid solapine', () {
        expect(ValidationUtils.isValidCode('ABC12'), isTrue);
      });

      test('returns true for valid tarjeta', () {
        expect(ValidationUtils.isValidCode('ABCDEF'), isTrue);
      });

      test('returns false for invalid code', () {
        expect(ValidationUtils.isValidCode('AB'), isFalse);
      });

      test('returns false for empty string', () {
        expect(ValidationUtils.isValidCode(''), isFalse);
      });
    });

    group('detectType', () {
      test('returns ScanType.tarjeta for valid tarjeta', () {
        expect(ValidationUtils.detectType('ABCDEF'), equals(ScanType.tarjeta));
      });

      test('returns ScanType.solapine for valid solapine', () {
        expect(ValidationUtils.detectType('ABC123'), equals(ScanType.solapine));
      });

      test('returns ScanType.solapine for invalid code', () {
        expect(ValidationUtils.detectType('AB'), equals(ScanType.solapine));
      });
    });

    group('validateCode', () {
      test('returns null for valid code', () {
        expect(ValidationUtils.validateCode('ABC12'), isNull);
      });

      test('returns error message for empty string', () {
        expect(ValidationUtils.validateCode(''), equals('El Solapin no puede estar vacío'));
      });

      test('returns error message for short code', () {
        expect(ValidationUtils.validateCode('AB'), equals('El Solapin debe tener entre 5 y 15 caracteres'));
      });

      test('returns error message for long code', () {
        expect(ValidationUtils.validateCode('ABC1234567890123'), equals('El Solapin debe tener entre 5 y 15 caracteres'));
      });

      test('returns null for valid tarjeta code', () {
        expect(ValidationUtils.validateCode('ABCDEF'), isNull);
      });
    });

    group('minLength and maxLength', () {
      test('minLength returns 5', () {
        expect(ValidationUtils.minLength, equals(5));
      });

      test('maxLength returns 15', () {
        expect(ValidationUtils.maxLength, equals(15));
      });
    });
  });
}