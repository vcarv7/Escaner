import 'package:flutter_test/flutter_test.dart';
import 'package:escaner_1/data/datasources/persona_api_datasource.dart';
import 'package:escaner_1/domain/entities/persona.dart';

void main() {
  Persona persona(String id) => Persona(
        idPersona: id,
        codigoSolapin: 'CODE$id',
        solapin: id,
        nombreCompleto: 'Persona $id',
      );

  group('calcularTotalPages', () {
    test('usa el page_size solicitado cuando la primera página viene llena', () {
      expect(PersonaApiDatasource.calcularTotalPages(6000, 1000, 1000), 6);
    });

    test('detecta el tope real del backend y no trunca la descarga', () {
      // El backend devolvió 500 aunque pedimos 1000: con el valor solicitado
      // se calcularían 6 páginas (3000 de 6000 personas, pérdida silenciosa).
      expect(PersonaApiDatasource.calcularTotalPages(6000, 500, 1000), 12);
    });

    test('la última página parcial no altera el conteo', () {
      // 650 personas con page_size 1000 caben en una sola página.
      expect(PersonaApiDatasource.calcularTotalPages(650, 650, 1000), 1);
    });

    test('devuelve 1 cuando la lista está vacía', () {
      expect(PersonaApiDatasource.calcularTotalPages(0, 0, 1000), 1);
      expect(PersonaApiDatasource.calcularTotalPages(0, 50, 1000), 1);
    });

    test('devuelve 1 cuando el API no devolvió registros en la primera página', () {
      expect(PersonaApiDatasource.calcularTotalPages(6000, 0, 1000), 1);
    });

    test('redondea hacia arriba con resto', () {
      expect(PersonaApiDatasource.calcularTotalPages(1050, 1000, 1000), 2);
      expect(PersonaApiDatasource.calcularTotalPages(1001, 1000, 1000), 2);
      expect(PersonaApiDatasource.calcularTotalPages(1000, 1000, 1000), 1);
    });
  });

  group('aplanarPaginas', () {
    test('ordena por número de página, no por orden de llegada', () {
      final porPagina = <int, List<Persona>>{
        3: [persona('7'), persona('8')],
        1: [persona('1')],
        2: [persona('4'), persona('5')],
      };

      final resultado = PersonaApiDatasource.aplanarPaginas(porPagina, 3);

      expect(resultado.map((p) => p.idPersona).toList(), ['1', '4', '5', '7', '8']);
    });

    test('tolera páginas faltantes sin romper el orden', () {
      final porPagina = <int, List<Persona>>{
        1: [persona('1')],
        3: [persona('5')],
      };

      final resultado = PersonaApiDatasource.aplanarPaginas(porPagina, 3);

      expect(resultado.map((p) => p.idPersona).toList(), ['1', '5']);
    });

    test('devuelve lista vacía sin páginas', () {
      expect(PersonaApiDatasource.aplanarPaginas({}, 3), isEmpty);
    });

    test('ignora páginas fuera de rango', () {
      final porPagina = <int, List<Persona>>{
        1: [persona('1')],
        4: [persona('99')],
      };

      final resultado = PersonaApiDatasource.aplanarPaginas(porPagina, 2);

      expect(resultado.map((p) => p.idPersona).toList(), ['1']);
    });
  });
}
