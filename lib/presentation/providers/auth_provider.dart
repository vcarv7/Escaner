import 'package:flutter/foundation.dart';
import '../../data/datasources/auth_api_datasource.dart';
import '../../data/services/auth_token_storage.dart';
import '../../data/services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiDatasource _authApi;
  final AuthTokenStorage _tokenStorage;

  String? _username;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  String? get username => _username;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider({
    AuthApiDatasource? authApi,
    AuthTokenStorage? tokenStorage,
  })  : _authApi = authApi ?? AuthApiDatasource(ApiClient(), AuthTokenStorage()),
        _tokenStorage = tokenStorage ?? AuthTokenStorage() {
    _init();
  }

  Future<void> _init() async {
    await _tokenStorage.init();
    await tryAutoLogin();
  }

  Future<bool> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isValid = await _tokenStorage.isTokenValid();
      if (!isValid) {
        final refreshToken = await _tokenStorage.getRefreshToken();
        if (refreshToken != null) {
          await _authApi.refreshToken();
          _isAuthenticated = true;
          _username = await _tokenStorage.getUsername();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } else {
        final accessToken = await _tokenStorage.getAccessToken();
        if (accessToken != null) {
          final verified = await _authApi.verifyToken(accessToken);
          if (verified) {
            _isAuthenticated = true;
            _username = await _tokenStorage.getUsername();
            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
      }

      await _tokenStorage.clear();
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      await _tokenStorage.clear();
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      _error = 'Usuario y contraseña son requeridos';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authApi.login(username.trim(), password);
      _isAuthenticated = true;
      _username = username.trim();
      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = _mapError(e);
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _isAuthenticated = false;
    _username = null;
    _error = null;
    notifyListeners();
  }

  String _mapError(Exception e) {
    final msg = e.toString();
    if (msg.contains('401') || msg.toLowerCase().contains('unauthorized') || msg.toLowerCase().contains('invalid')) {
      return 'Credenciales inválidas';
    }
    if (msg.contains('500') || msg.toLowerCase().contains('server')) {
      return 'Error del servidor. Intenta más tarde.';
    }
    if (msg.toLowerCase().contains('timeout') || msg.toLowerCase().contains('connection')) {
      return 'Sin conexión. Verifica tu red.';
    }
    return 'Error: ${msg.replaceFirst('Exception: ', '')}';
  }
}