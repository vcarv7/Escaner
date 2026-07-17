import '../../domain/entities/scan_item.dart';
import '../constants/app_constants.dart';

class ValidationUtils {
  static int get minLength => AppConstants.minCodeLength;
  static int get maxLength => AppConstants.maxCodeLength;

  // Solapín: longitud válida + contiene al menos un dígito (mutuamente
  // exclusivo con tarjeta para que detectType discrimine correctamente).
  static bool isValidSolapine(String value) {
    if (value.isEmpty) return false;
    final length = value.length;
    if (length < minLength || length > maxLength) return false;
    return RegExp(r'[0-9]').hasMatch(value);
  }

  // Tarjeta: solo letras, longitud válida.
  static bool isValidTarjeta(String value) {
    if (value.length < minLength || value.length > maxLength) return false;
    return RegExp(r'^[A-Za-z]+$').hasMatch(value);
  }

  static bool isValidCode(String value) {
    return isValidSolapine(value) || isValidTarjeta(value);
  }

  static ScanType detectType(String code) {
    if (isValidTarjeta(code)) {
      return ScanType.tarjeta;
    }
    return ScanType.solapine;
  }

  static String? validateCode(String code) {
    if (code.isEmpty) {
      return 'El Solapin no puede estar vacío';
    }
    if (code.length < minLength || code.length > maxLength) {
      return 'El Solapin debe tener entre $minLength y $maxLength caracteres';
    }
    return null;
  }
}