import '../entities/persona.dart';

class PersonaSyncResult {
  final List<Persona> personas;
  final int totalCount;
  final int totalPages;
  final DateTime syncedAt;

  PersonaSyncResult({
    required this.personas,
    required this.totalCount,
    required this.totalPages,
    required this.syncedAt,
  });
}

abstract class PersonaRepository {
  Future<List<Persona>> getAllPersonas({bool forceRefresh = false});
  Future<PersonaSyncResult> syncPersonas();
  Future<Persona?> findByCodigoSolapin(String codigo);
  Future<Persona?> findBySolapin(String solapin);
  Future<bool> hasCache();
}