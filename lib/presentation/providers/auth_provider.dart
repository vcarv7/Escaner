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

  /// Log del ciclo de auto-login. Es la unica forma de saber por que la
  /// sesion murio sin depender de credenciales para reproducir.
  void _authDebug(String message) {
    if (kDebugMode) debugPrint('AUTH: $message');
  }

  String? get username => _username;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;

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
    notifyListeners();

    try {
      final isValid = await _tokenStorage.isTokenValid();
      _authDebug('autoLogin: token vigente? $isValid');
      if (isValid) {
        final accessToken = await _tokenStorage.getAccessToken();
        _authDebug('autoLogin: access token ${accessToken == null ? "ausente" : "presente"}');
        if (accessToken != null) {
          try {
            final verified = await _authApi.verifyToken(accessToken);
            _authDebug('autoLogin: verifyToken -> $verified');
            if (verified) {
              _isAuthenticated = true;
              _username = await _tokenStorage.getUsername();
              _isLoading = false;
              notifyListeners();
              return true;
            }
          } catch (e) {
            // Si falla verifyToken por red, intentar con refresh token
            _authDebug('autoLogin: verifyToken fallo -> $e');
          }
        }
      }

      final refreshToken = await _tokenStorage.getRefreshToken();
      _authDebug('autoLogin: refresh token ${refreshToken == null ? "ausente" : (refreshToken.isEmpty ? "VACIO" : "presente")}');
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          await _authApi.refreshToken();
          _isAuthenticated = true;
          _username = await _tokenStorage.getUsername();
          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          _authDebug('autoLogin: refresh fallo -> $e');
          if (_isAuthError(e)) {
            _authDebug('autoLogin: refresh rechazado (401/403), limpiando tokens');
            await _tokenStorage.clear();
          }
        }
      }

      _authDebug('autoLogin: sin sesion, el operador va al login');
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _authDebug('autoLogin: excepcion inesperada -> $e');
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
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
      // En el login un 401 no es "sesión expirada": son credenciales malas.
      // El mensaje genérico de sesión expirada hace pensar al operador que
      // su sesión se cayó y lo manda a reiniciar algo que no se cayó.
      _error = e.statusCode == 401 ? 'Usuario o contraseña incorrectos' : _mapError(e);
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } on TimeoutException catch (e) {
      final appEx = AppException.timeout(e.message);
      _error = _mapError(appEx);
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      final appEx = AppException.fromDioException(e);
      _error = _mapError(appEx);
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      final appEx = AppException(
        type: AppErrorType.unknown,
        message: 'Error: ${e.toString().replaceFirst('Exception: ', '')}',
      );
      _error = _mapError(appEx);
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