import 'dart:convert';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../services/auth_token_storage.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int? ?? 3600,
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }
}

class AuthApiDatasource {
  final ApiClient _apiClient;
  final AuthTokenStorage _tokenStorage;

  AuthApiDatasource(this._apiClient, this._tokenStorage);

  Future<AuthTokens> login(String username, String password) async {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    final response = await _apiClient.dio.post(
      '/api/v1/auth/token',
      options: Options(
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ),
    );

    if (response.statusCode == 200) {
      final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresInSeconds: tokens.expiresIn,
      );
      return tokens;
    } else {
      throw _handleError(response);
    }
  }

  Future<AuthTokens> refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token available');

    final response = await _apiClient.dio.post(
      '/api/v1/auth/token/refresh',
      data: {'refresh_token': refreshToken},
    );

    if (response.statusCode == 200) {
      final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresInSeconds: tokens.expiresIn,
      );
      return tokens;
    } else {
      await _tokenStorage.clear();
      throw _handleError(response);
    }
  }

  Future<bool> verifyToken(String accessToken) async {
    final response = await _apiClient.dio.post(
      '/api/v1/auth/token/verify',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    return response.statusCode == 200;
  }

  Exception _handleError(Response response) {
    final data = response.data;
    String message;
    if (data is Map && data.containsKey('detail')) {
      message = data['detail'] as String;
    } else if (data is Map && data.containsKey('message')) {
      message = data['message'] as String;
    } else {
      message = 'Error de autenticación (${response.statusCode})';
    }
    return Exception(message);
  }
}