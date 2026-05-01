import 'package:flutter/foundation.dart';
import '../../domain/entities/evento.dart';

class EventoProvider extends ChangeNotifier {
  Evento? _eventoActual;

  Evento? get eventoActual => _eventoActual;
  bool get tieneEventoSeleccionado => _eventoActual != null;

  void seleccionarEvento(Evento evento) {
    _eventoActual = evento;
    notifyListeners();
  }

  void limpiarEvento() {
    _eventoActual = null;
    notifyListeners();
  }
}