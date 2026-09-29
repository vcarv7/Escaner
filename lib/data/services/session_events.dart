import 'dart:async';

/// Bus que conecta la capa de datos con la capa de presentación cuando el
/// interceptor se ve obligado a limpiar la sesión por un 401 no recuperable.
/// La capa de datos solo emite; AuthProvider y HomePage escuchan.
class SessionEvents {
  SessionEvents._();

  static final SessionEvents instance = SessionEvents._();

  final StreamController<void> _expiredController = StreamController<void>.broadcast();

  Stream<void> get onExpired => _expiredController.stream;

  void notifyExpired() {
    if (_expiredController.isClosed) return;
    _expiredController.add(null);
  }
}
