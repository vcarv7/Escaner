import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import '../../data/datasources/auth_api_datasource.dart';
import '../../data/services/auth_token_storage.dart';
import '../../data/services/api_client.dart';
import '../../data/services/session_events.dart';
import '../../core/errors/app_exception.dart';

/// Resultado de un intento de login.
///
/// El error viaja con el resultado en vez de quedar en un campo compartido del
/// provider: así el toast que se muestra corresponde a su propia request y un
/// login concurrente no puede pisar el mensaje de otro.
///
/// `cancelled` es un estado aparte y no un error: solo lo dispara el
/// `CancelToken` de esta pantalla (doble submit o salida de la página), nunca
/// es algo que el operador pueda corregir, así que no se le muestra nada.
class LoginResult {
  final bool success;
  final String? error;
  final bool cancelled;

  const LoginResult.success()
      : success = true,
        error = null,
        cancelled = false;

  const LoginResult.failure(String this.error)
      : success = false,
        cancelled = false;

  const LoginResult.cancelled()
      : success = false,
        error = null,
        cancelled = true;
}

class AuthProvider extends ChangeNotifier {
  final AuthApiDatasource _authApi;
  final AuthTokenStorage _tokenStorage;
  StreamSubscription<void>? _sessionExpiredSub;

  String? _username;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitializing = true;

  /// Log del ciclo de auto-login. Es la unica forma de saber por que la
  /// sesion murio sin depender de credenciales para reproducir.
  void _authDebug(String message) {
    if (kDebugMode) debugPrint('AUTH: $message');
  }

  String? get username => _username;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;

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
    notifyListeners();
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

  Future<LoginResult> login(String username, String password, {CancelToken? cancelToken}) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      notifyListeners();
      return const LoginResult.failure('Usuario y contraseña son requeridos');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _authApi.login(username.trim(), password, cancelToken: cancelToken);
      _isAuthenticated = true;
      _username = username.trim();

      // El nombre se guarda siempre: no promete sesión, solo evita que el
      // operador lo escriba en cada arranque.
      await _tokenStorage.saveUsername(username.trim());

      _isLoading = false;
      notifyListeners();
      return const LoginResult.success();
    } on AppException catch (e) {
      // En el login un 401 no es "sesión expirada": son credenciales malas.
      // El mensaje genérico de sesión expirada hace pensar al operador que
      // su sesión se cayó y lo manda a reiniciar algo que no se cayó.
      final error = e.statusCode == 401
          ? 'Usuario o contraseña incorrectos'
          : _mapError(e);
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return LoginResult.failure(error);
    } on TimeoutException catch (e) {
      final appEx = AppException.timeout(e.message);
      final error = _mapError(appEx);
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return LoginResult.failure(error);
    } on DioException catch (e) {
      // Una cancelación solo la produce el CancelToken de la pantalla de login.
      // No es un fallo que el operador pueda corregir, así que no se convierte en
      // un mensaje de error.
      if (e.type == DioExceptionType.cancel) {
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return const LoginResult.cancelled();
      }
      final appEx = AppException.fromDioException(e);
      final error = _mapError(appEx);
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return LoginResult.failure(error);
    } catch (e) {
      final appEx = AppException(
        type: AppErrorType.unknown,
        message: 'Error: ${e.toString().replaceFirst('Exception: ', '')}',
      );
      final error = _mapError(appEx);
      _isAuthenticated = false;
      _username = null;
      _isLoading = false;
      notifyListeners();
      return LoginResult.failure(error);
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _isAuthenticated = false;
    _username = null;
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