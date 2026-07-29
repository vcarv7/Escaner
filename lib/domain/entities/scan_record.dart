import 'evento.dart';

enum ScanStatus { reserved, notReserved, inactive, denied }

enum ScanType { solapine, tarjeta }

class EventoScan {
  final Evento evento;
  final DateTime timestamp;
  final String? puerta;

  const EventoScan({
    required this.evento,
    required this.timestamp,
    this.puerta,
  });

  Map<String, dynamic> toJson() => {
    'evento': evento.name,
    'timestamp': timestamp.toIso8601String(),
    'puerta': puerta,
  };

  factory EventoScan.fromJson(Map<String, dynamic> json) => EventoScan(
    evento: Evento.values.firstWhere((e) => e.name == json['evento']),
    timestamp: DateTime.parse(json['timestamp'] as String),
    puerta: json['puerta'] as String?,
  );
}

class ScanRecord {
  final String id;
  final String code;
  final ScanType type;
  final DateTime scannedAt;
  final String? personaId;
  final String? personaSolapine;
  final String? personaNombre;
  final int categoriaResidente;
  final List<EventoScan> eventos;
  final ScanStatus status;
  final bool isDuplicate;

  const ScanRecord({
    required this.id,
    required this.code,
    required this.type,
    required this.scannedAt,
    this.personaId,
    this.personaSolapine,
    this.personaNombre,
    this.categoriaResidente = 1,
    required this.eventos,
    required this.status,
    this.isDuplicate = false,
  });

  ScanRecord copyWith({
    String? id,
    String? code,
    ScanType? type,
    DateTime? scannedAt,
    String? personaId,
    String? personaSolapine,
    String? personaNombre,
    int? categoriaResidente,
    List<EventoScan>? eventos,
    ScanStatus? status,
    bool? isDuplicate,
  }) {
    return ScanRecord(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      scannedAt: scannedAt ?? this.scannedAt,
      personaId: personaId ?? this.personaId,
      personaSolapine: personaSolapine ?? this.personaSolapine,
      personaNombre: personaNombre ?? this.personaNombre,
      categoriaResidente: categoriaResidente ?? this.categoriaResidente,
      eventos: eventos ?? this.eventos,
      status: status ?? this.status,
      isDuplicate: isDuplicate ?? this.isDuplicate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'type': type == ScanType.solapine ? 'solapine' : 'tarjeta',
    'scannedAt': scannedAt.toIso8601String(),
    'personaId': personaId,
    'personaSolapine': personaSolapine,
    'personaNombre': personaNombre,
    'categoriaResidente': categoriaResidente,
    'eventos': eventos.map((e) => e.toJson()).toList(),
    'status': status.name,
    'isDuplicate': isDuplicate,
  };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
    id: json['id'] as String,
    code: json['code'] as String,
    type: (json['type'] as String) == 'solapine' ? ScanType.solapine : ScanType.tarjeta,
    scannedAt: DateTime.parse(json['scannedAt'] as String),
    personaId: json['personaId'] as String?,
    personaSolapine: json['personaSolapine'] as String?,
    personaNombre: json['personaNombre'] as String?,
    categoriaResidente: json['categoriaResidente'] as int? ?? 1,
    eventos: (json['eventos'] as List<dynamic>?)
        ?.map((e) => EventoScan.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    status: ScanStatus.values.firstWhere((s) => s.name == json['status']),
    isDuplicate: json['isDuplicate'] as bool? ?? false,
  );
}