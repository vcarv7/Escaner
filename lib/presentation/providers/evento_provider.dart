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

  Evento? getEventoPorHora(DateTime hora) {
    final hour = hora.hour;
    if (hour >= 6 && hour < 10) return Evento.desayuno;
    if (hour >= 11 && hour < 15) return Evento.almuerzo;
    if (hour >= 18 && hour < 22) return Evento.comida;
    return null;
  }

  void autoSeleccionarEvento() {
    final evento = getEventoPorHora(DateTime.now());
    if (evento != null) {
      seleccionarEvento(evento);
    }
  }
}