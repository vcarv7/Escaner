import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class HashUtils {
  static const int _saltLength = 16;

  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(_saltLength, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  static String hashPassword(String password, String salt) {
    final saltedPassword = '$salt$password';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPassword(String password, String salt, String expectedHash) {
    final computedHash = hashPassword(password, salt);
    return computedHash == expectedHash;
  }

  static List<int> sha256Bytes(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).bytes;
  }
}