import 'package:flutter/material.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../domain/entities/scan_item.dart';

class ScanItemCard extends StatelessWidget {
  final ScanItem item;
  final VoidCallback? onDelete;

  const ScanItemCard({
    super.key,
    required this.item,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDuplicate = item.isDuplicate;
    final typeLabel = item.type == ScanType.solapine ? 'S' : 'T';
    
    return Card(
      color: isDuplicate ? Colors.red.shade700.withValues(alpha: 0.2) : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAvatarColor(context),
          foregroundColor: _getAvatarForegroundColor(context),
          child: Text(typeLabel),
        ),
        title: Text(item.code),
        subtitle: Text(app_date.DateUtils.format(item.scannedAt)),
        trailing: _buildTrailing(context),
      ),
    );
  }

  Color _getAvatarColor(BuildContext context) {
    if (item.isDuplicate) return Colors.red.shade700;
    return item.type == ScanType.solapine 
        ? Theme.of(context).colorScheme.primary 
        : Colors.blue;
  }

  Color _getAvatarForegroundColor(BuildContext context) {
    if (item.isDuplicate || item.type == ScanType.tarjeta) {
      return Colors.white;
    }
    return Theme.of(context).colorScheme.onPrimary;
  }

  Widget? _buildTrailing(BuildContext context) {
    if (item.isDuplicate) {
      return const Icon(Icons.warning, color: Colors.red);
    }
    return Icon(
      item.type == ScanType.solapine ? Icons.qr_code : Icons.credit_card,
      color: Colors.blue,
    );
  }
}