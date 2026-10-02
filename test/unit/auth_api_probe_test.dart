import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:escaner_1/core/errors/app_exception.dart';
import 'package:escaner_1/data/datasources/auth_api_datasource.dart';
import 'package:escaner_1/data/services/api_client.dart';
import 'package:escaner_1/data/services/auth_token_storage.dart';

/// El datasource solo usa `apiClient.dio`, así que alcanza con eso. No sirve un
/// `Mock` de mockito: `noSuchMethod` devuelve null y `dio` es no-nullable.
class _FakeApiClient implements ApiClient {
  _FakeApiClient(this._dio);

  final Dio _dio;

  @override
  Dio get dio => _dio;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Adapter mínimo: responde en vez de tocar la red, y registra qué se pidió para
/// poder afirmar si el POST al login se intentó o no.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;
  final List<String> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add('${options.method} ${options.path}');
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

const _loginPath = 'POST /api/v1/auth/token/';

ResponseBody _probeConCookie() => ResponseBody.fromString(
  '{}',
  200,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
    'set-cookie': ['csrftoken=TOKEN123; Path=/'],
  },
);

ResponseBody _probeSinCookie() =>
    ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });

Matcher _esNoConnection() => throwsA(
  isA<AppException>().having(
    (e) => e.type,
    'type',
    AppErrorType.noConnection,
  ),
);

void main() {
  late _FakeAdapter adapter;

  AuthApiDatasource buildWith(
    Future<ResponseBody> Function(RequestOptions) handler,
  ) {
    adapter = _FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://ejemplo.test/'));
    dio.httpClientAdapter = adapter;
    return AuthApiDatasource(_FakeApiClient(dio), AuthTokenStorage());
  }

  /// El POST siempre responde 401: acá importa si se intentó, no el resultado.
  AuthApiDatasource buildProbeandoProbe(
    Future<ResponseBody> Function(RequestOptions) probe,
  ) =>
      buildWith((options) async {
        if (options.method == 'GET') return probe(options);
        return ResponseBody.fromString('{"detail":"no"}', 401);
      });

  group('el login solo se aborta si el servidor no responde', () {
    test('sin respuesta HTTP: aborta sin intentar el POST', () async {
      final datasource = buildProbeandoProbe((options) async {
        throw DioException(
          requestOptions: RequestOptions(path: options.path),
          type: DioExceptionType.connectionError,
        );
      });

      await expectLater(datasource.login('user', 'pass'), _esNoConnection());
      expect(adapter.requests, ['GET /']);
    });

    test('timeout en el probe: aborta sin intentar el POST', () async {
      final datasource = buildWith((options) async {
        // Para simular el timeout del `.timeout()` hay que lanzar el error.
        throw TimeoutException('probe', _requestTimeoutProbe);
      });

      await expectLater(datasource.login('user', 'pass'), _esNoConnection());
      expect(adapter.requests, ['GET /']);
    });
  });

  group('si el servidor responde, el login sigue adelante', () {
    // Este grupo cubre el bug que se detectó probando en el dispositivo real:
    // el backend responde 200 a `/` pero NO manda el cookie `csrftoken`.
    // Tratar la falta de cookie como "servidor caído" dejaba el login
    // imposible para todo el mundo con el servidor sano.
    test('probe 200 sin cookie: el POST se intenta igual', () async {
      final datasource = buildProbeandoProbe((_) async => _probeSinCookie());

      await expectLater(
        datasource.login('user', 'pass'),
        throwsA(
          isA<AppException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );

      expect(adapter.requests, ['GET /', _loginPath]);
    });

    test('probe 200 sin cookie: el POST va sin header X-CSRFToken', () async {
      String? csrf;
      final datasource = buildWith((options) async {
        if (options.method == 'GET') return _probeSinCookie();
        csrf = options.headers['X-CSRFToken'] as String?;
        return ResponseBody.fromString('{"detail":"no"}', 401);
      });

      await expectLater(datasource.login('user', 'pass'), throwsA(isA<AppException>()));

      expect(csrf, isNull);
    });

    test('probe 200 con cookie: el POST lleva el token CSRF', () async {
      String? csrf;
      final datasource = buildWith((options) async {
        if (options.method == 'GET') return _probeConCookie();
        csrf = options.headers['X-CSRFToken'] as String?;
        return ResponseBody.fromString('{"detail":"no"}', 401);
      });

      await expectLater(datasource.login('user', 'pass'), throwsA(isA<AppException>()));

      expect(csrf, 'TOKEN123');
    });

    test('probe 401: hay respuesta, así que hay server y el POST sigue', () async {
      final datasource = buildProbeandoProbe(
        (_) async => ResponseBody.fromString('Unauthorized', 401),
      );

      await expectLater(
        datasource.login('user', 'correcta'),
        throwsA(
          isA<AppException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );

      expect(adapter.requests, ['GET /', _loginPath]);
    });

    test('probe 500: hay respuesta, así que el POST sigue', () async {
      final datasource = buildProbeandoProbe(
        (_) async => ResponseBody.fromString('Error', 500),
      );

      await expectLater(
        datasource.login('user', 'correcta'),
        throwsA(
          isA<AppException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );

      expect(adapter.requests, ['GET /', _loginPath]);
    });
  });

  group('el 401 del POST se propaga como 401', () {
    test('llega con statusCode para que el provider pueda mapearlo', () async {
      final datasource = buildProbeandoProbe((_) async => _probeSinCookie());

      await expectLater(
        datasource.login('user', 'mala'),
        throwsA(
          isA<AppException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.type, 'type', isNot(AppErrorType.noConnection)),
        ),
      );
    });
  });
}

const _requestTimeoutProbe = Duration(seconds: 15);