class Persona {
  final String idPersona;
  final String codigoSolapin;
  final String solapin;
  final String nombreCompleto;

  const Persona({
    required this.idPersona,
    required this.codigoSolapin,
    required this.solapin,
    required this.nombreCompleto,
  });

  factory Persona.fromMap(Map<String, dynamic> map) {
    return Persona(
      idPersona: map['idPersona'] as String? ?? '',
      codigoSolapin: map['codigoSolapin'] as String? ?? '',
      solapin: map['solapin'] as String? ?? '',
      nombreCompleto: map['nombreCompleto'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idPersona': idPersona,
      'codigoSolapin': codigoSolapin,
      'solapin': solapin,
      'nombreCompleto': nombreCompleto,
    };
  }
}