import 'package:flutter/material.dart';
import '../../../domain/entities/scan_item.dart';
import 'scan_item_constants.dart';

class ScanItemCard extends StatelessWidget {
  final ScanItem item;

  const ScanItemCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final isDuplicate = item.isDuplicate;
    final isSolapine = item.type == ScanType.solapine;
    final typeLabel = isSolapine ? ScanItemConstants.solapineLabel : ScanItemConstants.tarjetaLabel;

    return Card(
      color: isDuplicate ? ScanItemColors.duplicateBackground : null,
      margin: const EdgeInsets.only(bottom: ScanItemConstants.cardMargin),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAvatarColor(isDuplicate, isSolapine),
          foregroundColor: _getAvatarForegroundColor(isDuplicate, isSolapine, context),
          child: Text(typeLabel),
        ),
        title: Text(item.code),
        subtitle: Text(ScanItemConstants.formatDate(item.scannedAt)),
        trailing: _buildTrailing(isDuplicate, isSolapine),
      ),
    );
  }

  Color _getAvatarColor(bool isDuplicate, bool isSolapine) {
    if (isDuplicate) return ScanItemColors.duplicate;
    return ScanItemColors.getTypeColor(isSolapine);
  }

  Color _getAvatarForegroundColor(bool isDuplicate, bool isSolapine, BuildContext context) {
    if (isDuplicate || !isSolapine) return Colors.white;
    return Theme.of(context).colorScheme.onPrimary;
  }

  Widget _buildTrailing(bool isDuplicate, bool isSolapine) {
    if (isDuplicate) {
      return const Icon(Icons.warning, color: ScanItemColors.duplicate);
    }
    return Icon(
      isSolapine ? Icons.qr_code : Icons.credit_card,
      color: ScanItemColors.tarjeta,
    );
  }
}