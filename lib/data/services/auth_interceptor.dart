import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../services/auth_token_storage.dart';

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
        await _tokenStorage.clear();
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
        final refreshToken = data['refresh'] as String;

        final tokenStorage = AuthTokenStorage();
        await tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresInSeconds: data['expiresIn'] as int? ?? 3600,
          username: await AuthTokenStorage().getUsername(),
        );

        err.requestOptions.headers['Authorization'] = 'Bearer $accessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);

        _processQueue(accessToken);
      } else {
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

  void _processQueue(String newAccessToken) {
    for (final request in _requestQueue) {
      request.options.headers['Authorization'] = 'Bearer $newAccessToken';
      try {
        final response = _dio.fetch(request.options);
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