import 'package:dio/dio.dart';
import 'dart:async';
import '../../domain/entities/persona.dart';
import '../../domain/repositories/persona_repository.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart' as app_logger;
import '../services/api_client.dart';

/// Página ya decodificada de la respuesta del API.
class _PaginaPersonas {
  final int totalCount;

  /// Registros crudos que devolvió el servidor, antes de descartar los que
  /// vienen sin `id` o `codigoSolapin`. Es lo que hay que usar para calcular
  /// cuántas páginas hay: el tamaño de página real del API, no el tamaño de la
  /// lista ya filtrada.
  final int registrosRecibidos;
  final List<Persona> personas;

  const _PaginaPersonas({
    required this.totalCount,
    required this.registrosRecibidos,
    required this.personas,
  });
}

class PersonaApiDatasource {
  final ApiClient _apiClient;

  PersonaApiDatasource(this._apiClient);

  /// Timeout total por página. Dio ya corta en la conexión y en la recepción
  /// con los timeouts de [ApiConstants]; este margen cubre el tiempo total de la
  /// llamada, incluida la estancia en la cola del cliente de Dio.
  static const Duration _requestTimeout = Duration(seconds: 30);

  /// Descarga todas las personas en 3 fases:
  ///  1. La página 1 va sola: es la única que trae `count` y por lo tanto
  ///     cuántas páginas existen.
  ///  2. Las páginas restantes se piden en lotes de [ApiConstants.personasSyncConcurrency].
  ///  3. Los resultados se aplanan en orden de página, no de llegada.
  Future<PersonaSyncResult> syncAllPersonas({bool onlyActive = true}) async {
    final primera = await _cargarPagina(1, onlyActive);
    final totalPages = calcularTotalPages(
      primera.totalCount,
      primera.registrosRecibidos,
      ApiConstants.defaultPageSize,
    );

    final Map<int, List<Persona>> porPagina = {1: primera.personas};

    for (var inicio = 2; inicio <= totalPages; inicio += ApiConstants.personasSyncConcurrency) {
      final lote = <Future<void>>[];
      for (var p = inicio; p < inicio + ApiConstants.personasSyncConcurrency && p <= totalPages; p++) {
        lote.add(() async {
          final pagina = await _cargarPagina(p, onlyActive);
          porPagina[p] = pagina.personas;
        }());
      }
      await Future.wait(lote);
    }

    final allPersonas = aplanarPaginas(porPagina, totalPages);

    _advertirSiFaltanRegistros(allPersonas.length, primera.totalCount, totalPages);

    return PersonaSyncResult(
      personas: allPersonas,
      totalCount: primera.totalCount,
      totalPages: totalPages,
      syncedAt: DateTime.now(),
    );
  }

  /// Cuántas páginas existen según lo que el servidor REALMENTE devolvió en la
  /// primera, no según lo que se pidió. Si el backend tiene un tope menor que
  /// [pageSizeSolicitado] (tope de DRF, proxy, etc) y se calculara con el valor
  /// solicitado, se dejarían de descargar páginas y se perderían personas en
  /// silencio.
  static int calcularTotalPages(
    int totalCount,
    int recibidosPrimeraPagina,
    int pageSizeSolicitado,
  ) {
    if (totalCount <= 0 || recibidosPrimeraPagina <= 0) return 1;

    // El servidor devolvió todo de una (no pagina, o devuelve más de lo pedido):
    // pedir páginas inexistentes devolvería 404 y tumbaría la sincronización.
    if (recibidosPrimeraPagina >= totalCount) return 1;

    final effective = recibidosPrimeraPagina < pageSizeSolicitado ? recibidosPrimeraPagina : pageSizeSolicitado;
    return (totalCount / effective).ceil();
  }

  /// Aplana las páginas en orden ascendente. El orden importa porque las
  /// peticiones van en paralelo y llegan desordenadas.
  static List<Persona> aplanarPaginas(Map<int, List<Persona>> porPagina, int totalPages) {
    final todas = <Persona>[];
    for (var p = 1; p <= totalPages; p++) {
      todas.addAll(porPagina[p] ?? const <Persona>[]);
    }
    return todas;
  }

  /// _mapToPersona descarta registros sin `id` o `codigoSolapin`, así que una
  /// diferencia pequeña es esperable. Un desajuste grande significa que el
  /// backend no sirvió todas las páginas y la app quedaría con una lista
  /// incompleta creyendo que está completa.
  static void _advertirSiFaltanRegistros(int recibidos, int totalCount, int totalPages) {
    if (totalCount <= 0) return;
    if (recibidos >= totalCount) return;

    final faltan = totalCount - recibidos;
    if (faltan <= recibidos * 0.05) return;

    app_logger.log.warning(
      'Sync de personas incompleta: $recibidos de $totalCount en $totalPages páginas. '
      'Revisar el tope de page_size del backend.',
    );
  }

  Future<_PaginaPersonas> _cargarPagina(int page, bool onlyActive) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': ApiConstants.defaultPageSize,
    };
    if (onlyActive) {
      queryParams['activo'] = 'true';
    }

    Response<dynamic> response;
    try {
      response = await _apiClient
          .get(ApiConstants.personas, queryParameters: queryParams)
          .timeout(_requestTimeout, onTimeout: () {
        throw AppException.timeout('La descarga de personas tardó más de $_requestTimeout');
      });
    } on TimeoutException {
      throw AppException.timeout('La descarga de personas tardó más de $_requestTimeout');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }

    if (response.statusCode != 200) {
      throw AppException.fromStatusCode(response.statusCode!);
    }

    final data = response.data as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? const [];

    final personas = <Persona>[];
    for (final item in results) {
      if (item is Map<String, dynamic>) {
        final persona = _mapToPersona(item);
        if (persona != null) {
          personas.add(persona);
        }
      }
    }

    return _PaginaPersonas(
      totalCount: data['count'] as int? ?? 0,
      registrosRecibidos: results.length,
      personas: personas,
    );
  }

  Persona? _mapToPersona(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final codigoSolapin = json['codigoSolapin']?.toString() ?? '';
    final solapin = json['solapin']?.toString() ?? '';
    final nombreCompleto = json['nombreCompleto']?.toString() ?? '';
    final categoriaResidente = json['categoriaResidente'] as int? ?? 1;

    if (id == null || id.isEmpty || codigoSolapin.isEmpty) {
      return null;
    }

    return Persona(
      idPersona: id,
      codigoSolapin: codigoSolapin,
      solapin: solapin,
      nombreCompleto: nombreCompleto,
      categoriaResidente: categoriaResidente,
    );
  }
}