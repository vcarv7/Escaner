import 'dart:async';
import 'package:dio/dio.dart';
import '../services/auth_token_storage.dart';

class AuthInterceptor extends Interceptor {
  final AuthTokenStorage _tokenStorage;

  bool _isRefreshing = false;
  final List<_QueuedRequest> _requestQueue = [];

  AuthInterceptor(this._tokenStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for login/refresh/verify endpoints
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
    // Only handle 401 errors on authenticated requests
    if (err.response?.statusCode == 401 && !err.requestOptions.path.contains('/auth/token')) {
      await _handle401(err, handler);
      return;
    }
    handler.next(err);
  }

  Future<void> _handle401(DioException err, ErrorInterceptorHandler handler) async {
    // If already refreshing, queue this request
    if (_isRefreshing) {
      await _queueRequest(err.requestOptions, handler);
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        await _tokenStorage.clear();
        _failQueuedRequests(Exception('No refresh token'));
        handler.next(err);
        return;
      }

      // Attempt to refresh token
      final response = await Dio().post(
        'http://10.11.6.48:7000/api/v1/auth/token/refresh/',
        data: {'refresh': refreshToken},
        options: Options(
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final accessToken = data['access'] as String;
        final refreshToken = data['refresh'] as String;

        // Save new tokens
        final tokenStorage = AuthTokenStorage();
        await tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresInSeconds: data['expiresIn'] as int? ?? 3600,
          username: await AuthTokenStorage().getUsername(),
        );

        // Retry original request with new token
        err.requestOptions.headers['Authorization'] = 'Bearer $accessToken';
        final retryResponse = await Dio().fetch(err.requestOptions);
        handler.resolve(retryResponse);

        // Process queued requests with new token
        _processQueue(accessToken);
      } else {
        // Refresh failed - clear tokens and fail
        final tokenStorage = AuthTokenStorage();
        await tokenStorage.clear();
        _failQueuedRequests(Exception('Token refresh failed'));
        handler.next(err);
      }
} catch (e) {
        final tokenStorage = AuthTokenStorage();
        await tokenStorage.clear();
        _failQueuedRequests(e is Exception ? e : Exception(e.toString()));
        handler.next(err);
      } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _queueRequest(RequestOptions options, ErrorInterceptorHandler handler) async {
    final completer = Completer<Response<dynamic>>();
    _requestQueue.add(_QueuedRequest(options, completer, handler));

    try {
      final response = await completer.future;
      handler.resolve(response);
    } catch (e) {
      handler.next(e as DioException);
    }
  }

  void _processQueue(String newAccessToken) {
    for (final request in _requestQueue) {
      request.options.headers['Authorization'] = 'Bearer $newAccessToken';
      try {
        final response = Dio().fetch(request.options);
        request.completer.complete(response);
      } catch (e) {
        request.completer.completeError(e);
      }
    }
    _requestQueue.clear();
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