import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:escaner_1/presentation/providers/auth_provider.dart';
import 'package:escaner_1/data/datasources/auth_api_datasource.dart';
import 'package:escaner_1/data/services/auth_token_storage.dart';
import 'package:escaner_1/core/errors/app_exception.dart';
import 'package:dio/dio.dart';

import 'auth_provider_test.mocks.dart';

@GenerateMocks([
  AuthApiDatasource,
  AuthTokenStorage,
  AuthTokens,
])

void main() {
  group('AuthProvider', () {
    late MockAuthApiDatasource mockAuthApi;
    late MockAuthTokenStorage mockTokenStorage;
    late AuthProvider authProvider;

    setUp(() {
      mockAuthApi = MockAuthApiDatasource();
      mockTokenStorage = MockAuthTokenStorage();
      authProvider = AuthProvider(
        authApi: mockAuthApi,
        tokenStorage: mockTokenStorage,
      );
    });

    tearDown(() {
      authProvider.dispose();
    });

    group('tryAutoLogin', () {
      test('devuelve true y setea autenticado cuando access token es válido', () async {
        when(mockTokenStorage.isTokenValid()).thenAnswer((_) async => true);
        when(mockTokenStorage.getAccessToken()).thenAnswer((_) async => 'valid_token');
        when(mockAuthApi.verifyToken('valid_token')).thenAnswer((_) async => true);
        when(mockTokenStorage.getUsername()).thenAnswer((_) async => 'testuser');

        final result = await authProvider.tryAutoLogin();

        expect(result, isTrue);
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.username, equals('testuser'));
        verify(mockTokenStorage.getUsername()).called(1);
      });

      test('intenta refresh token cuando access token expirado pero refresh token válido', () async {
        when(mockTokenStorage.isTokenValid()).thenAnswer((_) async => false);
        when(mockTokenStorage.getRefreshToken()).thenAnswer((_) async => 'valid_refresh');
        final mockTokens = MockAuthTokens();
        when(mockTokens.accessToken).thenReturn('new_access');
        when(mockTokens.refreshToken).thenReturn('new_refresh');
        when(mockTokens.expiresIn).thenReturn(3600);
        when(mockTokens.tokenType).thenReturn('Bearer');
        when(mockTokens.user).thenReturn({'username': 'refreshed_user'});
        when(mockAuthApi.refreshToken()).thenAnswer((_) async => mockTokens);
        when(mockTokenStorage.getUsername()).thenAnswer((_) async => 'refreshed_user');

        final result = await authProvider.tryAutoLogin();

        expect(result, isTrue);
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.username, equals('refreshed_user'));
        verify(mockAuthApi.refreshToken()).called(1);
      });

      test('devuelve false y limpia storage cuando refresh token falla', () async {
        when(mockTokenStorage.isTokenValid()).thenAnswer((_) async => false);
        when(mockTokenStorage.getRefreshToken()).thenAnswer((_) async => 'invalid_refresh');
        when(mockAuthApi.refreshToken()).thenThrow(AppException(
          type: AppErrorType.unauthorized,
          message: 'Invalid refresh token',
        ));

        final result = await authProvider.tryAutoLogin();

        expect(result, isFalse);
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.username, isNull);
        verify(mockTokenStorage.clear()).called(1);
      });

      test('devuelve false cuando no hay tokens guardados', () async {
        when(mockTokenStorage.isTokenValid()).thenAnswer((_) async => false);
        when(mockTokenStorage.getRefreshToken()).thenAnswer((_) async => null);

        final result = await authProvider.tryAutoLogin();

        expect(result, isFalse);
        expect(authProvider.isAuthenticated, isFalse);
      });

      test('devuelve false y NO limpia cuando verifyToken falla por red y no hay refresh token', () async {
        when(mockTokenStorage.isTokenValid()).thenAnswer((_) async => true);
        when(mockTokenStorage.getAccessToken()).thenAnswer((_) async => 'invalid_token');
        when(mockAuthApi.verifyToken('invalid_token')).thenThrow(
          DioException(requestOptions: RequestOptions(path: '/'), type: DioExceptionType.connectionError)
        );
        when(mockTokenStorage.getRefreshToken()).thenAnswer((_) async => null);

        final result = await authProvider.tryAutoLogin();

        expect(result, isFalse);
        expect(authProvider.isAuthenticated, isFalse);
        // No debe limpiar storage si es error de red
        verifyNever(mockTokenStorage.clear());
      });

      test('notifica a listeners durante el proceso', () async {
        when(mockTokenStorage.isTokenValid()).thenAnswer((_) async => true);
        when(mockTokenStorage.getAccessToken()).thenAnswer((_) async => 'token');
        when(mockAuthApi.verifyToken('token')).thenAnswer((_) async => true);
        when(mockTokenStorage.getUsername()).thenAnswer((_) async => 'user');

        int notifyCount = 0;
        authProvider.addListener(() => notifyCount++);

        await authProvider.tryAutoLogin();

        expect(notifyCount, greaterThanOrEqualTo(1));
      });
    });

    group('login', () {
      late MockAuthTokens mockTokens;

      setUp(() {
        mockTokens = MockAuthTokens();
        when(mockTokens.accessToken).thenReturn('access_token');
        when(mockTokens.refreshToken).thenReturn('refresh_token');
        when(mockTokens.expiresIn).thenReturn(3600);
        when(mockTokens.tokenType).thenReturn('Bearer');
        when(mockTokens.user).thenReturn({'username': 'test_user'});

        when(mockAuthApi.login('user', 'pass', cancelToken: anyNamed('cancelToken')))
            .thenAnswer((_) async => mockTokens);
        when(mockTokenStorage.getUsername()).thenAnswer((_) async => 'test_user');
      });

test('éxito: guarda tokens, setea autenticado', () async {
        final result = await authProvider.login('user', 'pass');

        expect(result, isTrue);
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.username, equals('user'));
        // El saveTokens se llama dentro de authApi.login, no en el provider
        verify(mockAuthApi.login('user', 'pass', cancelToken: anyNamed('cancelToken'))).called(1);
      });

      test('falla credenciales: no autentica, setea error', () async {
        when(mockAuthApi.login('user', 'wrong', cancelToken: anyNamed('cancelToken')))
            .thenThrow(AppException(
          type: AppErrorType.unauthorized,
          message: 'Credenciales inválidas',
        ));

        final result = await authProvider.login('user', 'wrong');

        expect(result, isFalse);
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.error, contains('Credenciales inválidas'));
      });

      test('falla red: setea error de conexión', () async {
        when(mockAuthApi.login('user', 'pass', cancelToken: anyNamed('cancelToken')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ));

        final result = await authProvider.login('user', 'pass');

        expect(result, isFalse);
        expect(authProvider.error, contains('Sin conexión'));
      });

      test('falla timeout: setea error de timeout', () async {
        when(mockAuthApi.login('user', 'pass', cancelToken: anyNamed('cancelToken')))
            .thenThrow(AppException.timeout('Tiempo agotado'));

        final result = await authProvider.login('user', 'pass');

        expect(result, isFalse);
        expect(authProvider.error, contains('Tiempo agotado'));
      });

      test('credenciales vacías: devuelve false con error', () async {
        final result1 = await authProvider.login('', 'pass');
        final result2 = await authProvider.login('user', '');

        expect(result1, isFalse);
        expect(result2, isFalse);
        expect(authProvider.error, contains('requeridos'));
      });

      test('notifica a listeners en login exitoso y fallido', () async {
        int notifyCount = 0;
        authProvider.addListener(() => notifyCount++);

        await authProvider.login('user', 'pass');

        expect(notifyCount, greaterThanOrEqualTo(1));
      });
    });

    group('logout', () {
      test('limpia storage y setea estado no autenticado', () async {
        when(mockTokenStorage.clear()).thenAnswer((_) async {});

        await authProvider.logout();

        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.username, isNull);
        expect(authProvider.error, isNull);
        verify(mockTokenStorage.clear()).called(1);
      });

      test('notifica a listeners', () async {
        when(mockTokenStorage.clear()).thenAnswer((_) async {});

        int notifyCount = 0;
        authProvider.addListener(() => notifyCount++);

        await authProvider.logout();

        expect(notifyCount, greaterThanOrEqualTo(1));
      });
    });

    group('estados iniciales', () {
      test('inicia con isAuthenticated = false, isLoading = false', () {
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.isLoading, isFalse);
        expect(authProvider.username, isNull);
        expect(authProvider.error, isNull);
      });

      test('setea isLoading durante tryAutoLogin', () async {
        when(mockTokenStorage.isTokenValid()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return false;
        });
        when(mockTokenStorage.getRefreshToken()).thenAnswer((_) async => null);

        expect(authProvider.isLoading, isFalse);
        
        final future = authProvider.tryAutoLogin();
        
        expect(authProvider.isLoading, isTrue);
        
        await future;
        
        expect(authProvider.isLoading, isFalse);
      });
    });

    group('_mapError (método privado testeado via login)', () {
      test('mapea timeout correctamente', () async {
        when(mockAuthApi.login('user', 'pass', cancelToken: anyNamed('cancelToken')))
            .thenThrow(AppException.timeout('Tiempo de espera agotado. Verifica tu conexión.'));

        await authProvider.login('user', 'pass');

        expect(authProvider.error, contains('Tiempo de espera'));
      });

      test('mapea no connection correctamente', () async {
        when(mockAuthApi.login('user', 'pass', cancelToken: anyNamed('cancelToken')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ));

        await authProvider.login('user', 'pass');

        expect(authProvider.error, contains('Sin conexión'));
      });

      test('mapea server error correctamente', () async {
        when(mockAuthApi.login('user', 'pass', cancelToken: anyNamed('cancelToken')))
            .thenThrow(AppException(
          type: AppErrorType.serverError,
          message: 'Error del servidor',
        ));

        await authProvider.login('user', 'pass');

        expect(authProvider.error, contains('servidor'));
      });
    });
  });
}