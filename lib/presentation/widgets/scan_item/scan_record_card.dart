import 'package:flutter/material.dart';
import '../../../domain/entities/scan_record.dart';
import 'scan_item_constants.dart';

class ScanRecordCard extends StatelessWidget {
  final ScanRecord record;

  const ScanRecordCard({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final isSolapine = record.type == ScanType.solapine;
    final screenWidth = MediaQuery.of(context).size.width;

    final card = Semantics(
      container: true,
      label: _buildSemanticsLabel(),
      child: Card(
        margin: const EdgeInsets.only(bottom: ScanItemConstants.cardMargin),
        child: Padding(
          padding: const EdgeInsets.all(ScanItemConstants.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBadge(isSolapine),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNombre(),
                        const SizedBox(height: 4),
                        _buildSolapin(),
                        const SizedBox(height: 6),
                        _buildCategoria(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildEventos(context),
              const SizedBox(height: 8),
              _buildBadgeRow(context),
            ],
          ),
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

  String _buildSemanticsLabel() {
    final statusText = _statusLabel();
    final categoriaText = record.categoriaResidente == 1 ? 'Interno' : 'Externo';
    final eventosText = record.eventos.map((e) => e.evento.displayName).join(', ');
    return '${record.personaNombre ?? statusText}, solapín ${record.personaSolapine ?? record.code}, $categoriaText, $eventosText, $statusText';
  }

  Widget _buildNombre() {
    if (record.status == ScanStatus.reserved || record.status == ScanStatus.denied) {
      if (record.personaNombre != null) {
        return Text(
          record.personaNombre!,
          style: TextStyle(
            fontSize: ScanItemConstants.nombreFontSize,
            fontWeight: FontWeight.w600,
            color: record.status == ScanStatus.denied
                ? ScanItemColors.denied
                : null,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      }
      return const SizedBox.shrink();
    }

    final label = record.status == ScanStatus.inactive
        ? 'Usuario Inactivo'
        : 'No Reservado';

    return Text(
      label,
      style: TextStyle(
        fontSize: ScanItemConstants.nombreFontSize,
        fontWeight: FontWeight.w600,
        color: Colors.orange.shade800,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildSolapin() {
    if (record.personaSolapine != null) {
      return Text(
        'Solapín: ${record.personaSolapine}',
        style: TextStyle(
          fontSize: ScanItemConstants.infoFontSize,
          color: Colors.grey.shade700,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCategoria() {
    final isInterno = record.categoriaResidente == 1;
    final color = isInterno ? Colors.blue : Colors.orange;
    final bgColor = isInterno ? Colors.blue.shade50 : Colors.orange.shade50;
    final label = isInterno ? 'Interno' : 'Externo';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEventos(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: record.eventos.map((eventoScan) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.restaurant,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  eventoScan.evento.displayName,
                  style: TextStyle(
                    fontSize: ScanItemConstants.infoFontSize,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (eventoScan.puerta != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.door_front_door,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  eventoScan.puerta!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBadgeRow(BuildContext context) {
    return Row(
      children: [
        Text(
          ScanItemConstants.formatDate(record.scannedAt),
          style: const TextStyle(fontSize: ScanItemConstants.infoFontSize),
        ),
        const SizedBox(width: 12),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    if (record.status == ScanStatus.notReserved) {
      return const SizedBox.shrink();
    }

    final (bgColor, textColor, text) = switch (record.status) {
      ScanStatus.reserved => (Colors.green.shade100, Colors.green.shade800, 'Reservado'),
      ScanStatus.inactive => (Colors.orange.shade100, Colors.orange.shade800, 'Usuario Inactivo'),
      ScanStatus.denied => (Colors.red.shade100, Colors.red.shade800, 'Acceso Denegado'),
      ScanStatus.notReserved => (Colors.green.shade100, Colors.green.shade800, 'Reservado'),
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

  String _statusLabel() {
    return switch (record.status) {
      ScanStatus.reserved => 'Reservado',
      ScanStatus.inactive => 'Usuario Inactivo',
      ScanStatus.denied => 'Acceso Denegado',
      ScanStatus.notReserved => 'No reservado',
    };
  }

  Widget _buildBadge(bool isSolapine) {
    final bgColor = ScanItemColors.getBackgroundColor(isSolapine);
    final iconColor = ScanItemColors.getTypeColor(isSolapine);
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
        icon,
        color: iconColor,
        size: 28,
      ),
    );
  }
}