import 'package:dio/dio.dart';
import 'dart:async';
import '../services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../services/auth_token_storage.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
  final Map<String, dynamic>? user;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
    this.user,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access'] as String,
      refreshToken: json['refresh'] as String,
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 3600,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access': accessToken,
      'refresh': refreshToken,
      'expiresIn': expiresIn,
      'tokenType': tokenType,
      'user': user,
    };
  }
}

class AuthApiDatasource {
  final ApiClient _apiClient;
  final AuthTokenStorage _tokenStorage;

  AuthApiDatasource(this._apiClient, this._tokenStorage);

  static const Duration _requestTimeout = Duration(seconds: 15);

  Future<AuthTokens> login(String username, String password, {CancelToken? cancelToken}) async {
    String? csrfToken;
    try {
      final csrfResponse = await _apiClient.dio
          .get(
            '/',
            options: Options(
              headers: {
                'Accept': 'application/json',
              },
            ),
          )
          .timeout(_requestTimeout);
      final setCookie = csrfResponse.headers['set-cookie'];
      if (setCookie != null && setCookie.isNotEmpty) {
        for (final cookie in setCookie) {
          if (cookie.contains('csrftoken=')) {
            final start = cookie.indexOf('csrftoken=') + 'csrftoken='.length;
            final end = cookie.indexOf(';', start);
            csrfToken = end > start ? cookie.substring(start, end) : cookie.substring(start);
            break;
          }
        }
      }
    } on TimeoutException {
      csrfToken = null;
    } on DioException {
      csrfToken = null;
    } catch (_) {
      csrfToken = null;
    }

    Response<dynamic> response;
    try {
      response = await _apiClient.dio
          .post(
            '/api/v1/auth/token/',
            data: {
              'username': username,
              'password': password,
            },
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                if (csrfToken != null) 'X-CSRFToken': csrfToken,
              },
            ),
            cancelToken: cancelToken,
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw AppException.timeout('La conexión con el servidor tardó más de 15 segundos');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }

    if (response.statusCode == 200) {
      final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresInSeconds: tokens.expiresIn,
        username: tokens.user?['username'] as String? ?? '',
        userData: tokens.user,
      );
      return tokens;
    }
    throw AppException.fromStatusCode(response.statusCode!);
  }

  Future<AuthTokens> refreshToken() async {
    final refreshTokenVal = await _tokenStorage.getRefreshToken();
    if (refreshTokenVal == null) throw AppException.noConnection('No refresh token available');

    Response<dynamic> response;
    try {
      response = await _apiClient.dio
          .post(
            ApiConstants.authRefresh,
            data: {'refresh': refreshTokenVal},
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw AppException.timeout('La conexión con el servidor tardó más de 15 segundos');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }

    if (response.statusCode == 200) {
      final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresInSeconds: tokens.expiresIn,
        username: await _tokenStorage.getUsername(),
        userData: await _tokenStorage.getUserData(),
      );
      return tokens;
    }
    await _tokenStorage.clear();
    throw AppException.fromStatusCode(response.statusCode!);
  }

  Future<bool> verifyToken(String accessToken) async {
    Response<dynamic> response;
    try {
      response = await _apiClient.dio
          .post(
            ApiConstants.authVerify,
            data: {'token': accessToken},
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw AppException.timeout('La conexión con el servidor tardó más de 15 segundos');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
    return response.statusCode == 200;
  }
}