import 'dart:async';
import '../../domain/entities/scan_item.dart';
import 'storage_service.dart';

class AutoDeleteNotification {
  final int itemsMovidosAPapelera;
  final int itemsEliminados;

  const AutoDeleteNotification({
    required this.itemsMovidosAPapelera,
    required this.itemsEliminados,
  });
}

class AutoDeleteService {
  static const int _diasHastaPapelera = 15;
  static const int _diasHastaEliminar = 30;
  static Timer? _timer;

  static final StreamController<AutoDeleteNotification> _notificationController =
      StreamController<AutoDeleteNotification>.broadcast();

  static Stream<AutoDeleteNotification> get notifications =>
      _notificationController.stream;

  static void iniciar() {
    _revisarEliminacion();
    _timer = Timer.periodic(const Duration(hours: 1), (_) => _revisarEliminacion());
  }

  static void detener() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _revisarEliminacion() async {
    final items = await StorageService.loadItems();
    final trashItems = await StorageService.loadTrash();
    final ahora = DateTime.now();

    final List<ScanItem> itemsAMover = [];
    final List<ScanItem> itemsAEliminar = [];
    final List<ScanItem> itemsRestantes = [];

    for (final item in items) {
      final dias = ahora.difference(item.scannedAt).inDays;
      if (dias >= _diasHastaPapelera) {
        itemsAMover.add(item);
      } else {
        itemsRestantes.add(item);
      }
    }

    for (final item in trashItems) {
      final dias = ahora.difference(item.scannedAt).inDays;
      if (dias >= _diasHastaEliminar) {
        itemsAEliminar.add(item);
      }
    }

    if (itemsAMover.isNotEmpty) {
      for (final item in itemsAMover) {
        trashItems.add(item);
      }
      itemsRestantes.removeWhere((i) => itemsAMover.contains(i));
    }

    if (itemsAEliminar.isNotEmpty) {
      for (final item in itemsAEliminar) {
        trashItems.removeWhere((t) => t.code == item.code);
      }
    }

    if (itemsAMover.isNotEmpty || itemsAEliminar.isNotEmpty) {
      await StorageService.saveItems(itemsRestantes);
      await StorageService.saveTrash(trashItems);
      _notificationController.add(AutoDeleteNotification(
        itemsMovidosAPapelera: itemsAMover.length,
        itemsEliminados: itemsAEliminar.length,
      ));
    }
  }
}