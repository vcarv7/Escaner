class SolapineItem {
  final String code;
  final bool isDuplicate;
  final DateTime scannedAt;

  const SolapineItem({
    required this.code,
    this.isDuplicate = false,
    required this.scannedAt,
  });

  SolapineItem copyWith({
    String? code,
    bool? isDuplicate,
    DateTime? scannedAt,
  }) {
    return SolapineItem(
      code: code ?? this.code,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }
}