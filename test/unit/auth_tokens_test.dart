import 'package:flutter_test/flutter_test.dart';
import 'package:escaner_1/data/datasources/auth_api_datasource.dart';

void main() {
  group('AuthTokens.fromJson', () {
    test('no revienta si la respuesta de /refresh/ no trae la clave refresh', () {
      // Respuesta real del backend (ROTATE_REFRESH_TOKENS=False): solo `access`.
      final tokens = AuthTokens.fromJson({
        'access': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.clientes-ejemplo',
      });

      expect(tokens.accessToken, startsWith('eyJhbGciOiJIUzI1NiIs'));
      expect(tokens.refreshToken, isEmpty);
      expect(tokens.expiresIn, 3600);
      expect(tokens.tokenType, 'Bearer');
      expect(tokens.user, isNull);
    });

    test('parsea el login con las claves mínimas del backend', () {
      // El backend solo envía access + refresh en el login.
      final tokens = AuthTokens.fromJson({
        'access': 'access-token',
        'refresh': 'refresh-token',
      });

      expect(tokens.accessToken, 'access-token');
      expect(tokens.refreshToken, 'refresh-token');
      expect(tokens.expiresIn, 3600);
      expect(tokens.tokenType, 'Bearer');
    });

    test('parsea el resto de campos cuando el servidor los envía', () {
      final tokens = AuthTokens.fromJson({
        'access': 'access-token',
        'refresh': 'refresh-token',
        'expiresIn': 7200,
        'tokenType': 'Bearer',
        'user': {'id': 20, 'username': 'orestesvcv'},
      });

      expect(tokens.accessToken, 'access-token');
      expect(tokens.refreshToken, 'refresh-token');
      expect(tokens.expiresIn, 7200);
      expect(tokens.tokenType, 'Bearer');
      expect(tokens.user?['username'], 'orestesvcv');
    });
  });
}