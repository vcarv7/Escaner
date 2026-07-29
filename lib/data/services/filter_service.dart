import '../../domain/entities/scan_record.dart';
import '../../presentation/providers/settings_provider.dart';

class FilterService {
  static List<ScanRecord> aplicarFiltros(List<ScanRecord> records, FiltroData filtro) {
    return records.where((record) {
      final fechaValida = filtro.fechaEnRango(record.scannedAt);
      final mismoEvento = filtro.evento == null || 
          record.eventos.any((e) => e.evento == filtro.evento);
      return fechaValida && mismoEvento;
    }).toList();
  }
}