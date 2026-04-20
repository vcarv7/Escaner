import 'package:flutter/material.dart';
import '../../domain/entities/scan_item.dart';
import 'scan_item_card.dart';

class SolapinesList extends StatelessWidget {
  final List<ScanItem> items;
  final VoidCallback onClearAll;

  const SolapinesList({
    super.key,
    required this.items,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final solapineCount = items.where((i) => i.type == ScanType.solapine).length;
    final tarjetaCount = items.where((i) => i.type == ScanType.tarjeta).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, solapineCount, tarjetaCount),
        Expanded(child: _buildList(context)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int solapineCount, int tarjetaCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$solapineCount solapines y $tarjetaCount tarjetas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearConfirmation(context),
              tooltip: 'Eliminar todos',
            ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No hay códigos escaneados'));
    }

    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) => ScanItemCard(item: items[index]),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todos los códigos'),
        content: const Text('¿Estás seguro de que quieres eliminar todos los códigos escaneados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onClearAll();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}