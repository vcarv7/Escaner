class Persona {
  final String codigo;
  final String solapine;
  final String nombre;
  final String apellidos;

  const Persona({
    required this.codigo,
    required this.solapine,
    required this.nombre,
    required this.apellidos,
  });

  String get nombreCompleto => '$nombre $apellidos';

  factory Persona.fromMap(Map<String, dynamic> map) {
    return Persona(
      codigo: map['codigo'] as String? ?? '',
      solapine: map['solapine'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      apellidos: map['apellidos'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'solapine': solapine,
      'nombre': nombre,
      'apellidos': apellidos,
    };
  }
}