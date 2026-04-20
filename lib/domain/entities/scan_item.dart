enum ScanType { solapine, tarjeta }

class ScanItem {
  final String code;
  final ScanType type;
  final bool isDuplicate;
  final DateTime scannedAt;

  const ScanItem({
    required this.code,
    required this.type,
    this.isDuplicate = false,
    required this.scannedAt,
  });

  ScanItem copyWith({
    String? code,
    ScanType? type,
    bool? isDuplicate,
    DateTime? scannedAt,
  }) {
    return ScanItem(
      code: code ?? this.code,
      type: type ?? this.type,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }
}