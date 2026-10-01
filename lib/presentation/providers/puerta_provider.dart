import 'package:flutter/foundation.dart';

class PuertaProvider extends ChangeNotifier {
  String? _puertaSeleccionada;

  String? get puertaSeleccionada => _puertaSeleccionada;
  bool get tienePuertaSeleccionada => _puertaSeleccionada != null;

  void seleccionarPuerta(String puerta) {
    _puertaSeleccionada = puerta;
    notifyListeners();
  }

  void limpiarPuerta() {
    _puertaSeleccionada = null;
    notifyListeners();
  }
}