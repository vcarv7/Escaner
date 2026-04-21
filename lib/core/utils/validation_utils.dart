import '../../domain/entities/scan_item.dart';
import '../constants/app_constants.dart';

class ValidationUtils {
  static int get minLength => AppConstants.minCodeLength;
  static int get maxLength => AppConstants.maxCodeLength;

  static bool isValidSolapine(String value) {
    if (value.isEmpty) return false;
    final length = value.length;
    return length >= minLength && length <= maxLength;
  }

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
      return 'El código no puede estar vacío';
    }
    if (code.length < minLength || code.length > maxLength) {
      return 'El código debe tener entre $minLength y $maxLength caracteres';
    }
    return null;
  }
}