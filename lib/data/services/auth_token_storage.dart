import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokenStorage {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyExpiresAt = 'token_expires_at';
  static const _keyUsername = 'username';
  static const _keyUserData = 'user_data';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> init() async {
    // No-op, just for consistency with other services
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
    String? username,
    Map<String, dynamic>? userData,
  }) async {
    final expiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds)).toIso8601String();
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      _storage.write(key: _keyExpiresAt, value: expiresAt),
      if (username != null) _storage.write(key: _keyUsername, value: username),
      if (userData != null) _storage.write(key: _keyUserData, value: jsonEncode(userData)),
    ]);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  Future<String?> getUsername() async {
    return _storage.read(key: _keyUsername);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: _keyUserData);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<bool> isTokenValid() async {
    final expiresAtStr = await _storage.read(key: _keyExpiresAt);
    if (expiresAtStr == null) return false;
    final expiresAt = DateTime.tryParse(expiresAtStr);
    if (expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt.subtract(const Duration(minutes: 1)));
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyExpiresAt),
      _storage.delete(key: _keyUsername),
      _storage.delete(key: _keyUserData),
    ]);
  }
}