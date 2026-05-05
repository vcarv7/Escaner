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
    final isDuplicate = item.status == ScanStatus.duplicate || 
        item.status == ScanStatus.notReservedDuplicate;
    final isSolapine = item.type == ScanType.solapine;
    final screenWidth = MediaQuery.of(context).size.width;

    final card = Card(
      margin: const EdgeInsets.only(bottom: ScanItemConstants.cardMargin),
      child: Padding(
        padding: const EdgeInsets.all(ScanItemConstants.cardPadding),
        child: Row(
          children: [
            _buildBadge(isSolapine, isDuplicate),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNombre(isDuplicate),
                  const SizedBox(height: 6),
                  _buildInfo(context),
                  const SizedBox(height: 4),
                  _buildBadgeRow(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (screenWidth > 600) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: card,
      );
    }

    return card;
  }

  Widget _buildNombre(bool isDuplicate) {
    final color = isDuplicate ? ScanItemColors.duplicate : null;

    if (item.status == ScanStatus.reserved || item.status == ScanStatus.duplicate) {
      if (item.personaNombre != null) {
        return Text(
          item.personaNombre!,
          style: TextStyle(
            fontSize: ScanItemConstants.nombreFontSize,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      }
      return const SizedBox.shrink();
    }

    return Text(
      'No Reservado',
      style: TextStyle(
        fontSize: ScanItemConstants.nombreFontSize,
        fontWeight: FontWeight.w600,
        color: Colors.orange.shade800,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildInfo(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: ScanItemConstants.infoFontSize,
      color: Theme.of(context).colorScheme.primary,
    );

    if (item.status == ScanStatus.reserved || item.status == ScanStatus.duplicate) {
      if (item.personaSolapine != null) {
        return Row(
          children: [
            Text(
              'Solapín: ${item.personaSolapine}',
              style: textStyle.copyWith(color: null),
            ),
            if (item.evento != null) ...[
              const SizedBox(width: 12),
              Text(item.evento!.displayName, style: textStyle),
            ],
          ],
        );
      }
      if (item.evento != null) {
        return Text(item.evento!.displayName, style: textStyle);
      }
      return const SizedBox.shrink();
    }

    if (item.evento != null) {
      return Text(item.evento!.displayName, style: textStyle);
    }
    return const SizedBox.shrink();
  }

  Widget _buildBadgeRow(BuildContext context) {
    return Row(
      children: [
        Text(
          ScanItemConstants.formatDate(item.scannedAt),
          style: const TextStyle(fontSize: ScanItemConstants.infoFontSize),
        ),
        const SizedBox(width: 12),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    if (item.status == ScanStatus.notReserved) {
      return const SizedBox.shrink();
    }

    final (bgColor, textColor, text) = switch (item.status) {
      ScanStatus.reserved => (Colors.green.shade100, Colors.green.shade800, 'Reservado'),
      ScanStatus.duplicate => (Colors.red.shade100, Colors.red.shade800, 'Duplicado'),
      ScanStatus.notReservedDuplicate => (Colors.red.shade100, Colors.red.shade800, 'Duplicado'),
      _ => (Colors.green.shade100, Colors.green.shade800, 'Reservado'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: ScanItemConstants.badgeFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBadge(bool isSolapine, bool isDuplicate) {
    final bgColor = isDuplicate
        ? ScanItemColors.duplicateBackground
        : ScanItemColors.getBackgroundColor(isSolapine);
    final iconColor = isDuplicate
        ? ScanItemColors.duplicate
        : ScanItemColors.getTypeColor(isSolapine);
    final icon = isSolapine
        ? ScanItemConstants.getSolapineIcon()
        : ScanItemConstants.getTarjetaIcon();

    return Container(
      width: ScanItemConstants.badgeIconSize,
      height: ScanItemConstants.badgeIconSize,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isDuplicate ? Icons.warning_rounded : icon,
        color: iconColor,
        size: 28,
      ),
    );
  }
}