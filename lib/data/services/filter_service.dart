import '../../domain/entities/scan_item.dart';
import '../../presentation/providers/settings_provider.dart';

class FilterService {
  static List<ScanItem> aplicarFiltros(List<ScanItem> items, FiltroData filtro) {
    return items.where((item) {
      final fechaValida = filtro.fechaEnRango(item.scannedAt);
      final mismoEvento = filtro.evento == null ||
          (item.evento != null && item.evento!.displayName == filtro.eventoNombre);
      return fechaValida && mismoEvento;
    }).toList();
  }
}
