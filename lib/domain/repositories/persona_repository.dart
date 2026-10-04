import 'package:dio/dio.dart';
import '../entities/persona.dart';

/// Progreso de la sincronización por páginas.
///
/// Se define en dominio para no duplicar la firma entre datasource,
/// repositorio y provider. `paginaActual` es 1-based.
typedef SyncProgressCallback =
    void Function({
      required int paginaActual,
      required int totalPaginas,
      required int recibidos,
    });

class PersonaSyncResult {
  final List<Persona> personas;

  /// `count` del servidor. Solo diagnóstico: puede incluir registros sin
  /// `codigoSolapin` que la app descarta. Lo que ve el operador y lo que
  /// usa el escaneo es siempre `personas.length`.
  final int totalCount;
  final int totalPages;

  /// Registros crudos descartados por venir sin `id` o `codigoSolapin`.
  final int descartados;
  final DateTime syncedAt;

  PersonaSyncResult({
    required this.personas,
    required this.totalCount,
    required this.totalPages,
    this.descartados = 0,
    required this.syncedAt,
  });
}

abstract class PersonaRepository {
  Future<List<Persona>> getAllPersonas({bool forceRefresh = false});
  Future<PersonaSyncResult> syncPersonas({
    SyncProgressCallback? onProgress,
    CancelToken? cancelToken,
  });
  Future<Persona?> findByCodigoSolapin(String codigo);
  Future<Persona?> findBySolapin(String solapin);
  Future<bool> hasCache();

  /// Descarta las personas retenidas en memoria sin borrar la caché en disco,
  /// para que no queden visibles tras un cambio de usuario.
  Future<void> clearSession();
}