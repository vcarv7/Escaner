import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/authorized_user.dart';

class SecureUsersDatasource {
  static const _usersKey = 'authorized_users';
  static const _firstUserKey = 'first_user_created';

  final FlutterSecureStorage _storage;

  SecureUsersDatasource({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  Future<List<AuthorizedUser>> getUsers() async {
    final usersJson = await _storage.read(key: _usersKey);
    if (usersJson == null || usersJson.isEmpty) {
      return [];
    }
    final List<dynamic> usersList = jsonDecode(usersJson) as List<dynamic>;
    return usersList
        .map((json) => AuthorizedUser.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveUsers(List<AuthorizedUser> users) async {
    final usersJson = jsonEncode(users.map((u) => u.toJson()).toList());
    await _storage.write(key: _usersKey, value: usersJson);
  }

  Future<void> addUser(AuthorizedUser user) async {
    final users = await getUsers();
    final existingIndex = users.indexWhere((u) => u.username == user.username);
    if (existingIndex >= 0) {
      users[existingIndex] = user;
    } else {
      users.add(user);
    }
    await saveUsers(users);
  }

  Future<void> updateUser(AuthorizedUser user) async {
    final users = await getUsers();
    final index = users.indexWhere((u) => u.username == user.username);
    if (index >= 0) {
      users[index] = user;
      await saveUsers(users);
    }
  }

  Future<void> deleteUser(String username) async {
    final users = await getUsers();
    users.removeWhere((u) => u.username == username);
    await saveUsers(users);
  }

  Future<AuthorizedUser?> getUser(String username) async {
    final users = await getUsers();
    try {
      return users.firstWhere((u) => u.username == username);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isFirstUser() async {
    final value = await _storage.read(key: _firstUserKey);
    return value != 'true';
  }

  Future<void> setFirstUserCreated() async {
    await _storage.write(key: _firstUserKey, value: 'true');
  }

  Future<AuthorizedUser?> authenticate(
    String username,
    String password,
  ) async {
    final users = await getUsers();
    try {
      final user = users.firstWhere((u) => u.username == username);
      final isValid = _verifyPassword(password, user.salt, user.passwordHash);
      return isValid ? user : null;
    } catch (_) {
      return null;
    }
  }

  bool _verifyPassword(String password, String salt, String expectedHash) {
    final computedHash = _hashPassword(password, salt);
    return computedHash == expectedHash;
  }

  String _hashPassword(String password, String salt) {
    final saltedPassword = '$salt$password';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> clearAllUsers() async {
    await _storage.delete(key: _usersKey);
    await _storage.delete(key: _firstUserKey);
  }
}