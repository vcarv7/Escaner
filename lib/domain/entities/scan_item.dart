import 'evento.dart';

enum ScanStatus { reserved, notReserved, duplicate, notReservedDuplicate }

enum ScanType { solapine, tarjeta }

class ScanItem {
  final String code;
  final ScanType type;
  final bool isDuplicate;
  final DateTime scannedAt;
  final Evento? evento;
  final String? personaSolapine;
  final String? personaNombre;
  final ScanStatus status;

  const ScanItem({
    required this.code,
    required this.type,
    this.isDuplicate = false,
    required this.scannedAt,
    this.evento,
    this.personaSolapine,
    this.personaNombre,
    this.status = ScanStatus.reserved,
  });

  ScanItem copyWith({
    String? code,
    ScanType? type,
    bool? isDuplicate,
    DateTime? scannedAt,
    Evento? evento,
    String? personaSolapine,
    String? personaNombre,
    ScanStatus? status,
  }) {
    return ScanItem(
      code: code ?? this.code,
      type: type ?? this.type,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      scannedAt: scannedAt ?? this.scannedAt,
      evento: evento ?? this.evento,
      personaSolapine: personaSolapine ?? this.personaSolapine,
      personaNombre: personaNombre ?? this.personaNombre,
      status: status ?? this.status,
    );
  }
}