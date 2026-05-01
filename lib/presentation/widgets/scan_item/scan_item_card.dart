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
    final isDuplicate = item.isDuplicate || 
        item.status == ScanStatus.duplicate || 
        item.status == ScanStatus.notReservedDuplicate;
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
                  if (item.personaNombre != null)
                    Text(
                      item.personaNombre!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDuplicate
                                ? ScanItemColors.duplicate
                                : null,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  if (item.personaNombre == null)
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
                  Row(
                    children: [
                      if (item.personaSolapine != null) ...[
                        Text(
                          'Solapín: ${item.personaSolapine}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (item.evento != null)
                        Text(
                          item.evento!.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        ScanItemConstants.formatDate(item.scannedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(),
                    ],
                  ),
                ],
              ),
            ),
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

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (item.status) {
      case ScanStatus.reserved:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        text = 'Reservado';
        break;
      case ScanStatus.notReserved:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        text = 'No reservado';
        break;
      case ScanStatus.duplicate:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        text = 'Duplicado';
        break;
      case ScanStatus.notReservedDuplicate:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        text = 'No reservado + Dup.';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
}