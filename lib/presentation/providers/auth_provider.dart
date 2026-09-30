import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import '../../data/datasources/auth_api_datasource.dart';
import '../../data/services/auth_token_storage.dart';
import '../../data/services/api_client.dart';
import '../../data/services/session_events.dart';
import '../../core/errors/app_exception.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiDatasource _authApi;
  final AuthTokenStorage _tokenStorage;
  StreamSubscription<void>? _sessionExpiredSub;

  String? _username;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;
  String? _technicalError;

  String? get username => _username;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  String? get technicalError => _technicalError;

  AuthProvider({
    AuthApiDatasource? authApi,
    AuthTokenStorage? tokenStorage,
  })  : _tokenStorage = tokenStorage ?? AuthTokenStorage(),
        _authApi = authApi ?? AuthApiDatasource(ApiClient(), AuthTokenStorage()) {
    _sessionExpiredSub = SessionEvents.instance.onExpired.listen((_) => _onSessionExpired());
    _init();
  }

  @override
  void dispose() {
    _sessionExpiredSub?.cancel();
    _sessionExpiredSub = null;
    super.dispose();
  }

  /// El interceptor limpió los tokens por un 401 no recuperable: el estado en
  /// memoria debe seguir al almacenamiento para que la UI no quede desincronizada.
  void _onSessionExpired() {
    _isAuthenticated = false;
    _username = null;
    _error = 'Tu sesión expiró. Inicia sesión nuevamente.';
    notifyListeners();
  }

  Future<void> _init() async {
    await _tokenStorage.init();
    await tryAutoLogin();
  }

  Future<bool> tryAutoLogin() async {
    _isLoading = true;
    _error = null;
    _technicalError = null;
    notifyListeners();

    try {
      final isValid = await _tokenStorage.isTokenValid();
      if (isValid) {
        final accessToken = await _tokenStorage.getAccessToken();
        if (accessToken != null) {
          try {
            final verified = await _authApi.verifyToken(accessToken);
            if (verified) {
              _isAuthenticated = true;
              _username = await _tokenStorage.getUsername();
              _isLoading = false;
              notifyListeners();
              return true;
            }
          } catch (e) {
            // Si falla verifyToken por red, intentar con refresh token
          }
        }
      }

      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          await _authApi.refreshToken();
          _isAuthenticated = true;
          _username = await _tokenStorage.getUsername();
          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          if (_isAuthError(e)) {
            await _tokenStorage.clear();
          }
        }
      }

      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      _technicalError = null;
      notifyListeners();
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  bool _isAuthError(Object e) =>
      e is AppException &&
      (e.type == AppErrorType.unauthorized || e.type == AppErrorType.forbidden);

  Future<bool> login(String username, String password, {bool rememberMe = false, CancelToken? cancelToken}) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      _error = 'Usuario y contraseña son requeridos';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authApi.login(username.trim(), password, cancelToken: cancelToken);
      _isAuthenticated = true;
      _username = username.trim();

      if (rememberMe) {
        await _tokenStorage.saveUsername(username.trim());
        await _tokenStorage.saveRememberMe(true);
      } else {
        await _tokenStorage.clearUsername();
        await _tokenStorage.saveRememberMe(false);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _error = _mapError(e);
      _technicalError = e.technicalMessage;
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } on TimeoutException catch (e) {
      final appEx = AppException.timeout(e.message);
      _error = _mapError(appEx);
      _technicalError = appEx.technicalMessage;
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      final appEx = AppException.fromDioException(e);
      _error = _mapError(appEx);
      _technicalError = appEx.technicalMessage;
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      final appEx = AppException(
        type: AppErrorType.unknown,
        message: 'Error: ${e.toString().replaceFirst('Exception: ', '')}',
        technicalMessage: e.toString(),
      );
      _error = _mapError(appEx);
      _technicalError = appEx.technicalMessage;
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
    _technicalError = null;
    notifyListeners();
  }

  String _mapError(Object error) {
    if (error is AppException) {
      return error.message;
    }
    if (error is DioException) {
      return AppException.fromDioException(error).message;
    }
    final msg = error.toString();
    if (msg.toLowerCase().contains('timeout')) {
      return 'Tiempo de espera agotado. Verifica tu conexión.';
    }
    if (msg.toLowerCase().contains('connection') || msg.toLowerCase().contains('socket')) {
      return 'Sin conexión. Verifica tu red.';
    }
    if (msg.contains('500') || msg.toLowerCase().contains('server')) {
      return 'Error del servidor. Intenta más tarde.';
    }
    return 'Error: ${msg.replaceFirst('Exception: ', '')}';
  }
}