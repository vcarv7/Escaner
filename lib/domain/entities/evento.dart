enum Evento {
  desayuno('Desayuno', false),
  desayunoDoble('Desayuno', true),
  almuerzo('Almuerzo', false),
  almuerzoDoble('Almuerzo', true),
  comida('Comida', false),
  comidaDoble('Comida', true);

  final String nombre;
  final bool esDoble;

  const Evento(this.nombre, this.esDoble);

  String get displayName => esDoble ? '$nombre Doble' : nombre;

  bool get isDoble => esDoble;

  static Evento? fromString(String value) {
    final lower = value.toLowerCase();
    for (final evento in Evento.values) {
      if (evento.displayName.toLowerCase() == lower) {
        return evento;
      }
    }
    return null;
  }
}