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
    final screenWidth = MediaQuery.of(context).size.width;
    
    final card = Card(
      margin: const EdgeInsets.only(bottom: ScanItemConstants.cardMargin),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildBadge(isSolapine, isDuplicate),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.code,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDuplicate
                              ? ScanItemColors.duplicate
                              : null,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ScanItemConstants.formatDate(item.scannedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            _buildTrailing(isDuplicate, isSolapine),
          ],
        ),
      ),
    );

    if (screenWidth > 600) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600),
        child: card,
      );
    }

    return card;
  }

  Widget _buildBadge(bool isSolapine, bool isDuplicate) {
    final backgroundColor = isDuplicate
        ? ScanItemColors.duplicateBackground
        : ScanItemColors.getBackgroundColor(isSolapine);
    final iconColor = isDuplicate
        ? ScanItemColors.duplicate
        : ScanItemColors.getTypeColor(isSolapine);
    final icon = isSolapine
        ? ScanItemConstants.getSolapineIcon()
        : ScanItemConstants.getTarjetaIcon();

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isDuplicate ? Icons.warning_rounded : icon,
        color: iconColor,
        size: 22,
      ),
    );
  }

  Widget _buildTrailing(bool isDuplicate, bool isSolapine) {
    if (isDuplicate) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ScanItemColors.duplicateBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Duplicado',
          style: TextStyle(
            color: ScanItemColors.duplicate,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ScanItemColors.getBackgroundColor(isSolapine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isSolapine ? 'Solapín' : 'Tarjeta',
        style: TextStyle(
          color: ScanItemColors.getTypeColor(isSolapine),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}