import 'package:dio/dio.dart';
import 'dart:async';
import '../../domain/entities/persona.dart';
import '../../domain/repositories/persona_repository.dart';
import '../../core/errors/app_exception.dart';
import '../services/api_client.dart';

class PersonaApiDatasource {
  final ApiClient _apiClient;

  PersonaApiDatasource(this._apiClient);

  static const Duration _requestTimeout = Duration(seconds: 15);

  Future<PersonaSyncResult> syncAllPersonas({bool onlyActive = true}) async {
    final List<Persona> allPersonas = [];
    int currentPage = 1;
    int totalPages = 1;
    int totalCount = 0;

    do {
      final queryParams = <String, dynamic>{
        'page': currentPage,
        'page_size': 100,
      };
      if (onlyActive) {
        queryParams['activo'] = 'true';
      }

      Response<dynamic> response;
      try {
        response = await _apiClient
            .get('/api/v1/base/personas/', queryParameters: queryParams)
            .timeout(_requestTimeout, onTimeout: () {
          throw AppException.timeout('La descarga de personas tardó más de 15 segundos');
        });
      } on TimeoutException {
        throw AppException.timeout('La descarga de personas tardó más de 15 segundos');
      } on DioException catch (e) {
        throw AppException.fromDioException(e);
      }

      if (response.statusCode != 200) {
        throw AppException.fromStatusCode(response.statusCode!);
      }

      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      for (final item in results) {
        if (item is Map<String, dynamic>) {
          final persona = _mapToPersona(item);
          if (persona != null) {
            allPersonas.add(persona);
          }
        }
      }

      totalCount = data['count'] as int? ?? 0;
      totalPages = (totalCount / 100).ceil();

      currentPage++;
    } while (currentPage <= totalPages);

    return PersonaSyncResult(
      personas: allPersonas,
      totalCount: totalCount,
      totalPages: totalPages,
      syncedAt: DateTime.now(),
    );
  }

  Persona? _mapToPersona(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final codigoSolapin = json['codigoSolapin']?.toString() ?? '';
    final solapin = json['solapin']?.toString() ?? '';
    final nombreCompleto = json['nombreCompleto']?.toString() ?? '';

    if (id == null || id.isEmpty || codigoSolapin.isEmpty) {
      return null;
    }

    return Persona(
      idPersona: id,
      codigoSolapin: codigoSolapin,
      solapin: solapin,
      nombreCompleto: nombreCompleto,
    );
  }
}