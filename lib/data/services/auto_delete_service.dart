import 'dart:async';
import '../../domain/entities/scan_record.dart';

class AutoDeleteNotification {
  final int itemsMovidosAPapelera;
  final int itemsEliminados;
  final List<ScanRecord> recordsRestantes;
  final List<ScanRecord> trashActualizada;

  const AutoDeleteNotification({
    required this.itemsMovidosAPapelera,
    required this.itemsEliminados,
    required this.recordsRestantes,
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

  static AutoDeleteNotification revisarScanRecords(
    List<ScanRecord> records,
    List<ScanRecord> trashRecords,
  ) {
    final ahora = DateTime.now();

    final List<ScanRecord> recordsRestantes = [];
    final List<ScanRecord> trashActualizada = List<ScanRecord>.from(trashRecords);
    int itemsMovidos = 0;
    int itemsEliminados = 0;

    for (final record in records) {
      final dias = ahora.difference(record.scannedAt).inDays;
      if (dias >= _diasHastaPapelera) {
        final yaEnTrash = trashActualizada.any(
          (t) => t.id == record.id,
        );
        if (!yaEnTrash) {
          trashActualizada.add(record);
          itemsMovidos++;
        }
      } else {
        recordsRestantes.add(record);
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
      recordsRestantes: recordsRestantes,
      trashActualizada: trashActualizada,
    );
  }
}