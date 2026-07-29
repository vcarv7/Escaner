class Puerta {
  final String numero;
  final String comedor;

  const Puerta({required this.numero, required this.comedor});
}

class PuertaService {
  static const List<Puerta> puertas = [
    Puerta(numero: '111', comedor: 'Comedor 1'),
    Puerta(numero: '112', comedor: 'Comedor 1'),
    Puerta(numero: '121', comedor: 'Comedor 1'),
    Puerta(numero: '122', comedor: 'Comedor 1'),
    Puerta(numero: '131', comedor: 'Comedor 1'),
    Puerta(numero: '132', comedor: 'Comedor 1'),
    Puerta(numero: '221', comedor: 'Comedor 2'),
    Puerta(numero: '222', comedor: 'Comedor 2'),
    Puerta(numero: '241', comedor: 'Comedor 2'),
    Puerta(numero: '242', comedor: 'Comedor 2'),
    Puerta(numero: '311', comedor: 'Comedor 3'),
    Puerta(numero: '312', comedor: 'Comedor 3'),
    Puerta(numero: '321', comedor: 'Comedor 3'),
    Puerta(numero: '322', comedor: 'Comedor 3'),
    Puerta(numero: '331', comedor: 'Comedor 3'),
    Puerta(numero: '332', comedor: 'Comedor 3'),
  ];

  static List<String> get comedores =>
      puertas.map((p) => p.comedor).toSet().toList()..sort();

  static List<Puerta> getPuertasPorComedor(String comedor) =>
      puertas.where((p) => p.comedor == comedor).toList();
}