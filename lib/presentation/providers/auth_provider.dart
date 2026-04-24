import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:escaner_1/core/utils/hash_utils.dart';
import 'package:escaner_1/data/datasources/secure_users_datasource.dart';
import 'package:escaner_1/data/models/authorized_user.dart';

class AuthProvider extends ChangeNotifier {
  static const _currentUserKey = 'current_user_session';

  final SecureUsersDatasource _datasource;
  final FlutterSecureStorage _sessionStorage;

  AuthorizedUser? _currentUser;
  List<AuthorizedUser> _users = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _isDisposed = false;

  AuthProvider({SecureUsersDatasource? datasource})
      : _datasource = datasource ?? SecureUsersDatasource(),
        _sessionStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  AuthorizedUser? get currentUser => _currentUser;
  List<AuthorizedUser> get users => _users;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<void> init() async {
    _isLoading = true;
    _notify();

    await _loadUsers();

    if (_users.isEmpty) {
      await _createDefaultAdmin();
    }

    await _restoreSession();

    _isLoading = false;
    _notify();
  }

  Future<void> _createDefaultAdmin() async {
    const defaultUsername = 'admin';
    const defaultPassword = 'admin123';

    final salt = HashUtils.generateSalt();
    final passwordHash = HashUtils.hashPassword(defaultPassword, salt);

    final defaultUser = AuthorizedUser(
      username: defaultUsername,
      passwordHash: passwordHash,
      salt: salt,
      isAdmin: true,
      createdAt: DateTime.now(),
    );

    await _datasource.addUser(defaultUser);
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    _users = await _datasource.getUsers();
  }

  Future<void> _restoreSession() async {
    final sessionData = await _sessionStorage.read(key: _currentUserKey);
    if (sessionData != null && sessionData.isNotEmpty) {
      final username = sessionData;
      _currentUser = await _datasource.getUser(username);
      if (_currentUser != null) {
        _isAuthenticated = true;
      }
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _notify();

    final user = await _datasource.authenticate(username, password);

    _isLoading = false;
    _notify();

    if (user != null) {
      _currentUser = user;
      _isAuthenticated = true;
      await _sessionStorage.write(key: _currentUserKey, value: username);
      _notify();
      return true;
    }

    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    await _sessionStorage.delete(key: _currentUserKey);
    _notify();
  }

  Future<void> createUser({
    required String username,
    required String password,
    bool isAdmin = false,
  }) async {
    _isLoading = true;
    _notify();

    final salt = HashUtils.generateSalt();
    final passwordHash = HashUtils.hashPassword(password, salt);

    final user = AuthorizedUser(
      username: username,
      passwordHash: passwordHash,
      salt: salt,
      isAdmin: isAdmin,
      createdAt: DateTime.now(),
    );

    await _datasource.addUser(user);
    await _loadUsers();

    _isLoading = false;
    _notify();
  }

  Future<void> updateUserPassword(
    String username,
    String newPassword,
  ) async {
    _isLoading = true;
    _notify();

    final user = await _datasource.getUser(username);
    if (user != null) {
      final newSalt = HashUtils.generateSalt();
      final newPasswordHash = HashUtils.hashPassword(newPassword, newSalt);

      final updatedUser = user.copyWith(
        passwordHash: newPasswordHash,
        salt: newSalt,
      );

      await _datasource.updateUser(updatedUser);
      await _loadUsers();
    }

    _isLoading = false;
    _notify();
  }

  Future<void> deleteUser(String username) async {
    _isLoading = true;
    _notify();

    await _datasource.deleteUser(username);
    await _loadUsers();

    if (_currentUser?.username == username) {
      await logout();
    }

    _isLoading = false;
    _notify();
  }

  Future<void> toggleAdmin(String username) async {
    _isLoading = true;
    _notify();

    final user = await _datasource.getUser(username);
    if (user != null) {
      final updatedUser = user.copyWith(isAdmin: !user.isAdmin);
      await _datasource.updateUser(updatedUser);
      await _loadUsers();

      if (_currentUser?.username == username) {
        _currentUser = updatedUser;
      }
    }

    _isLoading = false;
    _notify();
  }

  Future<bool> hasUsers() async {
    final users = await _datasource.getUsers();
    return users.isNotEmpty;
  }

  void _notify() {
    if (!_isDisposed) {
      _notify();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sessionStorage.delete(key: _currentUserKey);
    super.dispose();
  }
}