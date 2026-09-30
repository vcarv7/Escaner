import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../services/auth_token_storage.dart';
import '../services/session_events.dart';

class AuthInterceptor extends Interceptor {
  final AuthTokenStorage _tokenStorage;
  final Dio _dio;

  bool _isRefreshing = false;
  final List<_QueuedRequest> _requestQueue = [];

  AuthInterceptor(this._tokenStorage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final skipAuth = options.path.contains('/auth/token');
    if (!skipAuth) {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !err.requestOptions.path.contains('/auth/token')) {
      await _handle401(err, handler);
      return;
    }
    handler.next(err);
  }

  Future<void> _handle401(DioException err, ErrorInterceptorHandler handler) async {
    if (_isRefreshing) {
      await _queueRequest(err.requestOptions, handler);
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        await _clearSession();
        _failQueuedRequests(Exception('No refresh token'));
        handler.next(err);
        return;
      }

      final response = await _dio.post(
        ApiConstants.authRefresh,
        data: {'refresh': refreshToken},
        options: Options(
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final accessToken = data['access'] as String;
        // El backend no rota el refresh y lo omite en la respuesta: conservar
        // el que ya teníamos en lugar de sobrescribirlo con una cadena vacía.
        final newRefreshToken = data['refresh'] as String? ?? refreshToken;

        await _tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: newRefreshToken,
          expiresInSeconds: data['expiresIn'] as int? ?? 3600,
          username: await _tokenStorage.getUsername(),
        );

        err.requestOptions.headers['Authorization'] = 'Bearer $accessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);

        await _processQueue(accessToken);
      } else {
        await _clearSession();
        _failQueuedRequests(Exception('Token refresh failed'));
        handler.next(err);
      }
    } catch (e) {
      if (e is DioException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.unknown)) {
        // Fallo de red: conservar tokens, no cerrar sesión
        _failQueuedRequests(e);
        handler.next(err);
      } else {
        await _clearSession();
        _failQueuedRequests(e is Exception ? e : Exception(e.toString()));
        handler.next(err);
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// Limpia los tokens y avisa a la capa de presentación para que AuthProvider
  /// sincronice su estado en vez de quedar desincronizado.
  Future<void> _clearSession() async {
    await _tokenStorage.clear();
    SessionEvents.instance.notifyExpired();
  }

  Future<void> _queueRequest(RequestOptions options, ErrorInterceptorHandler handler) async {
    final completer = Completer<Response<dynamic>>();
    _requestQueue.add(_QueuedRequest(options, completer, handler));

    try {
      final response = await completer.future;
      handler.resolve(response);
    } catch (e) {
      final dioErr = e is DioException
          ? e
          : DioException(
              requestOptions: options,
              type: DioExceptionType.unknown,
              message: e.toString(),
            );
      handler.next(dioErr);
    }
  }

  Future<void> _processQueue(String newAccessToken) async {
    final pending = List<_QueuedRequest>.from(_requestQueue);
    _requestQueue.clear();
    for (final request in pending) {
      request.options.headers['Authorization'] = 'Bearer $newAccessToken';
      try {
        final response = await _dio.fetch(request.options);
        request.completer.complete(response);
      } catch (e) {
        request.completer.completeError(e);
      }
    }
  }

  void _failQueuedRequests(Exception error) {
    for (final request in _requestQueue) {
      request.completer.completeError(error);
    }
    _requestQueue.clear();
  }
}

class _QueuedRequest {
  final RequestOptions options;
  final Completer<Response<dynamic>> completer;
  final ErrorInterceptorHandler handler;

  _QueuedRequest(this.options, this.completer, this.handler);
}