import 'package:dio/dio.dart';
import '../services/api_client.dart';
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

  Future<AuthTokens> login(String username, String password) async {
    // Step 1: Get CSRF token by making a GET request to the base URL
    // This should set the csrftoken cookie
    String? csrfToken;
    try {
      final csrfResponse = await _apiClient.dio.get(
        '/',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );
      // Extract CSRF token from Set-Cookie header
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
    } catch (e) {
      // If CSRF fetch fails, continue without it - some configs may not require it
    }

    // Step 2: Login with credentials and CSRF token
    final response = await _apiClient.dio.post(
      '/api/v1/auth/token/',
      data: {
        'username': username,
        'password': password,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (csrfToken != null) 'X-CSRFToken': csrfToken!,
        },
      ),
    );

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
    } else {
      throw _handleError(response);
    }
  }

  Future<AuthTokens> refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token available');

    final response = await _apiClient.dio.post(
      '/api/v1/auth/token/refresh/',
      data: {'refresh': refreshToken},
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

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
    } else {
      await _tokenStorage.clear();
      throw _handleError(response);
    }
  }

  Future<bool> verifyToken(String accessToken) async {
    final response = await _apiClient.dio.post(
      '/api/v1/auth/token/verify/',
      data: {'token': accessToken},
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
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
    } else if (data is Map && data.containsKey('non_field_errors')) {
      final errors = data['non_field_errors'] as List;
      message = errors.join(', ');
    } else {
      message = 'Error de autenticación (${response.statusCode})';
    }
    return Exception(message);
  }
}