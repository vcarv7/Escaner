import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:escaner_1/presentation/providers/auth_provider.dart';
import 'package:escaner_1/data/datasources/auth_api_datasource.dart';
import 'package:escaner_1/data/services/auth_token_storage.dart';
import 'package:escaner_1/core/errors/app_exception.dart';
import 'package:escaner_1/data/services/session_events.dart';
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

      test('devuelve false y limpia storage cuando refresh token falla por sesión expirada', () async {
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

      test('devuelve false y NO limpia storage cuando refresh token falla por red', () async {
        when(mockTokenStorage.isTokenValid()).thenAnswer((_) async => false);
        when(mockTokenStorage.getRefreshToken()).thenAnswer((_) async => 'refresh_token');
        when(mockAuthApi.refreshToken()).thenThrow(
          DioException(requestOptions: RequestOptions(path: '/'), type: DioExceptionType.connectionError)
        );

        final result = await authProvider.tryAutoLogin();

        expect(result, isFalse);
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.username, isNull);
        // No debe limpiar storage si es error de red
        verifyNever(mockTokenStorage.clear());
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

        expect(result.success, isTrue);
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

        expect(result.success, isFalse);
        expect(authProvider.isAuthenticated, isFalse);
        expect(result.error, contains('Credenciales inválidas'));
      });

      test('401 con statusCode se reporta como credenciales incorrectas', () async {
        // El test anterior lanza la excepción SIN statusCode, así que nunca
        // entra por la rama del 401. Esta es la rama que convierte cualquier 401
        // en "contraseña incorrecta", y la que hace que un 401 emitido por un
        // proxy con la aplicación caída culpe al operador.
        when(mockAuthApi.login('user', 'correcta', cancelToken: anyNamed('cancelToken')))
            .thenThrow(AppException(
          type: AppErrorType.unauthorized,
          message: 'Sesión expirada. Inicia sesión nuevamente.',
          statusCode: 401,
        ));

        final result = await authProvider.login('user', 'correcta');

        expect(result.success, isFalse);
        expect(result.error, 'Usuario o contraseña incorrectos');
      });

      test('un error de conexión NO se reporta como credenciales incorrectas', () async {
        // Este es el síntoma reportado con el servidor caído: la app culpaba al
        // operador. El datasource ahora aborta antes del POST cuando el probe
        // de CSRF falla, así que este mensaje debe llegarle al operador tal cual.
        when(mockAuthApi.login('user', 'correcta', cancelToken: anyNamed('cancelToken')))
            .thenThrow(AppException.noConnection(
          'No se puede conectar con el servidor. Verifica la red o contacta a soporte.',
        ));

        final result = await authProvider.login('user', 'correcta');

        expect(result.success, isFalse);
        expect(result.error, contains('No se puede conectar con el servidor'));
        expect(result.error, isNot(contains('incorrectos')));
      });

      test('cada intento lleva su propio error, sin estado compartido', () async {
        when(mockAuthApi.login('user', 'wrong', cancelToken: anyNamed('cancelToken')))
            .thenThrow(AppException(
          type: AppErrorType.unauthorized,
          message: 'Credenciales inválidas',
        ));

        final fallido = await authProvider.login('user', 'wrong');

        expect(fallido.success, isFalse);
        expect(fallido.error, contains('Credenciales inválidas'));

        when(mockAuthApi.login('user', 'bien', cancelToken: anyNamed('cancelToken')))
            .thenAnswer((_) async => AuthTokens(
                  accessToken: 'a',
                  refreshToken: 'r',
                  expiresIn: 3600,
                  tokenType: 'Bearer',
                ));

        final exitoso = await authProvider.login('user', 'bien');

        // El error viaja con el resultado, así que un login bueno no puede
        // devolver el mensaje del anterior ni pisarlo.
        expect(exitoso.success, isTrue);
        expect(exitoso.error, isNull);
        expect(exitoso.cancelled, isFalse);
      });

      test('una cancelación no se reporta como error', () async {
        // Solo la dispara el CancelToken de la pantalla (doble submit o salida).
        // Antes terminaba en el toast como "Petición cancelada.".
        when(mockAuthApi.login('user', 'pass', cancelToken: anyNamed('cancelToken')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.cancel,
        ));

        final result = await authProvider.login('user', 'pass');

        expect(result.cancelled, isTrue);
        expect(result.error, isNull);
      });

      test('falla red: setea error de conexión', () async {
        when(mockAuthApi.login('user', 'pass', cancelToken: anyNamed('cancelToken')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ));

        final result = await authProvider.login('user', 'pass');

        expect(result.success, isFalse);
        expect(result.error, contains('Sin conexión'));
      });

      test('falla timeout: setea error de timeout', () async {
        when(mockAuthApi.login('user', 'pass', cancelToken: anyNamed('cancelToken')))
            .thenThrow(AppException.timeout('Tiempo agotado'));

        final result = await authProvider.login('user', 'pass');

        expect(result.success, isFalse);
        expect(result.error, contains('Tiempo agotado'));
      });

      test('credenciales vacías: devuelve failure con error', () async {
        final result1 = await authProvider.login('', 'pass');
        final result2 = await authProvider.login('user', '');

        expect(result1.success, isFalse);
        expect(result2.success, isFalse);
        expect(result1.error, contains('requeridos'));
        expect(result2.error, contains('requeridos'));
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

    group('sesión expirada', () {
      Future<void> autenticar() async {
        when(mockTokenStorage.isTokenValid()).thenAnswer((_) async => true);
        when(mockTokenStorage.getAccessToken()).thenAnswer((_) async => 'valid_token');
        when(mockAuthApi.verifyToken('valid_token')).thenAnswer((_) async => true);
        when(mockTokenStorage.getUsername()).thenAnswer((_) async => 'testuser');
        await authProvider.tryAutoLogin();
      }

      test('desloguea al recibir el evento del interceptor', () async {
        await autenticar();
        expect(authProvider.isAuthenticated, isTrue);

        SessionEvents.instance.notifyExpired();
        await pumpEventQueue();

        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.username, isNull);
      });

      test('notifica a listeners al recibir el evento', () async {
        await autenticar();

        int notifyCount = 0;
        authProvider.addListener(() => notifyCount++);

        SessionEvents.instance.notifyExpired();
        await pumpEventQueue();

        expect(notifyCount, greaterThanOrEqualTo(1));
      });

      test('login() posterior vuelve a autenticar', () async {
        await autenticar();

        SessionEvents.instance.notifyExpired();
        await pumpEventQueue();
        expect(authProvider.isAuthenticated, isFalse);

        final mockTokens = MockAuthTokens();
        when(mockTokens.accessToken).thenReturn('access_token');
        when(mockTokens.refreshToken).thenReturn('refresh_token');
        when(mockTokens.expiresIn).thenReturn(3600);
        when(mockTokens.tokenType).thenReturn('Bearer');
        when(mockTokens.user).thenReturn({'username': 'test_user'});
        when(mockAuthApi.login('user', 'pass', cancelToken: anyNamed('cancelToken')))
            .thenAnswer((_) async => mockTokens);

        final result = await authProvider.login('user', 'pass');

        expect(result.success, isTrue);
        expect(authProvider.isAuthenticated, isTrue);
      });

      test('logout() no dispara el evento de sesión expirada', () async {
        await autenticar();

        var expirations = 0;
        final sub = SessionEvents.instance.onExpired.listen((_) => expirations++);
        when(mockTokenStorage.clear()).thenAnswer((_) async {});

        await authProvider.logout();
        await pumpEventQueue();

        expect(expirations, 0);
        expect(authProvider.isAuthenticated, isFalse);
        await sub.cancel();
      });
    });

    group('estados iniciales', () {
      test('inicia con isAuthenticated = false, isLoading = false', () {
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.isLoading, isFalse);
        expect(authProvider.username, isNull);
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

      test('isInitializing pasa a false después de terminar tryAutoLogin', () async {
        when(mockTokenStorage.isTokenValid()).thenAnswer((_) async => false);
        when(mockTokenStorage.getRefreshToken()).thenAnswer((_) async => null);

        await authProvider.tryAutoLogin();

        expect(authProvider.isInitializing, isFalse);
      });
    });

    group('_mapError (método privado testeado via login)', () {
      test('mapea timeout correctamente', () async {
        when(mockAuthApi.login('user', 'pass', cancelToken: anyNamed('cancelToken')))
            .thenThrow(AppException.timeout('Tiempo de espera agotado. Verifica tu conexión.'));

        final result = await authProvider.login('user', 'pass');

        expect(result.error, contains('Tiempo de espera'));
      });

      test('mapea no connection correctamente', () async {
        when(mockAuthApi.login('user', 'pass', cancelToken: anyNamed('cancelToken')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ));

        final result = await authProvider.login('user', 'pass');

        expect(result.error, contains('Sin conexión'));
      });

      test('mapea server error correctamente', () async {
        when(mockAuthApi.login('user', 'pass', cancelToken: anyNamed('cancelToken')))
            .thenThrow(AppException(
          type: AppErrorType.serverError,
          message: 'Error del servidor',
        ));

        final result = await authProvider.login('user', 'pass');

        expect(result.error, contains('servidor'));
      });
    });
  });
}