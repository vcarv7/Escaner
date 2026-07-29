class Persona {
  final String idPersona;
  final String codigoSolapin;
  final String solapin;
  final String nombreCompleto;
  final int categoriaResidente;

  const Persona({
    required this.idPersona,
    required this.codigoSolapin,
    required this.solapin,
    required this.nombreCompleto,
    this.categoriaResidente = 1,
  });

  factory Persona.fromMap(Map<String, dynamic> map) {
    return Persona(
      idPersona: map['idPersona'] as String? ?? '',
      codigoSolapin: map['codigoSolapin'] as String? ?? '',
      solapin: map['solapin'] as String? ?? '',
      nombreCompleto: map['nombreCompleto'] as String? ?? '',
      categoriaResidente: map['categoriaResidente'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idPersona': idPersona,
      'codigoSolapin': codigoSolapin,
      'solapin': solapin,
      'nombreCompleto': nombreCompleto,
      'categoriaResidente': categoriaResidente,
    };
  }
}