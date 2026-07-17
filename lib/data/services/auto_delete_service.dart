import 'dart:async';
import '../../domain/entities/scan_item.dart';

class AutoDeleteNotification {
  final int itemsMovidosAPapelera;
  final int itemsEliminados;
  final List<ScanItem> itemsRestantes;
  final List<ScanItem> trashActualizada;

  const AutoDeleteNotification({
    required this.itemsMovidosAPapelera,
    required this.itemsEliminados,
    required this.itemsRestantes,
    required this.trashActualizada,
  });
}

class AutoDeleteService {
  static const int _diasHastaPapelera = 15;
  static const int _diasHastaEliminar = 30;
  static Timer? _timer;
  static bool _iniciado = false;

  static final StreamController<AutoDeleteNotification> _notificationController =
      StreamController<AutoDeleteNotification>.broadcast();

  static Stream<AutoDeleteNotification> get notifications =>
      _notificationController.stream;

  static void iniciar() {
    if (_iniciado) return;
    _iniciado = true;
    _timer = Timer.periodic(const Duration(hours: 1), (_) {
      // El provider escucha este stream y aplica _revisar sobre sus listas
      // en memoria. Aquí no se toca storage directamente.
    });
  }

  static void detener() {
    _timer?.cancel();
    _timer = null;
    _iniciado = false;
  }

  /// Revisa items y trash (pertenecientes al ScanProvider) y devuelve el
  /// resultado de la limpieza. NO toca storage directamente: el provider
  /// debe aplicar el resultado y persistir.
  static AutoDeleteNotification revisar(
    List<ScanItem> items,
    List<ScanItem> trashItems,
  ) {
    final ahora = DateTime.now();

    final List<ScanItem> itemsRestantes = [];
    final List<ScanItem> trashActualizada = List<ScanItem>.from(trashItems);
    int itemsMovidos = 0;
    int itemsEliminados = 0;

    for (final item in items) {
      final dias = ahora.difference(item.scannedAt).inDays;
      if (dias >= _diasHastaPapelera) {
        // Evitar dup en trash (por code, case-insensitive).
        final yaEnTrash = trashActualizada.any(
          (t) => t.code.toUpperCase() == item.code.toUpperCase(),
        );
        if (!yaEnTrash) {
          trashActualizada.add(item);
          itemsMovidos++;
        }
      } else {
        itemsRestantes.add(item);
      }
    }

    final int antes = trashActualizada.length;
    trashActualizada.removeWhere(
      (t) => ahora.difference(t.scannedAt).inDays >= _diasHastaEliminar,
    );
    itemsEliminados = antes - trashActualizada.length;

    return AutoDeleteNotification(
      itemsMovidosAPapelera: itemsMovidos,
      itemsEliminados: itemsEliminados,
      itemsRestantes: itemsRestantes,
      trashActualizada: trashActualizada,
    );
  }
}