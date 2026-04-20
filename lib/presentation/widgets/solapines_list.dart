import 'package:flutter/material.dart';
import '../../domain/entities/scan_item.dart';

class SolapinesList extends StatelessWidget {
  final List<ScanItem> items;
  final VoidCallback onClearAll;

  const SolapinesList({
    super.key,
    required this.items,
    required this.onClearAll,
  });

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todos los códigos'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todos los códigos escaneados?',
        ),
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().substring(2);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final solapineCount = items.where((i) => i.type == ScanType.solapine).length;
    final tarjetaCount = items.where((i) => i.type == ScanType.tarjeta).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text('No hay códigos escaneados'),
                )
              : ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isDuplicate = item.isDuplicate;
                    final typeLabel = item.type == ScanType.solapine ? 'S' : 'T';
                    
                    return Card(
                      color: isDuplicate
                          ? Colors.red.shade700.withValues(alpha: 0.2)
                          : null,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDuplicate
                              ? Colors.red.shade700
                              : item.type == ScanType.solapine
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.blue,
                          foregroundColor: isDuplicate || item.type == ScanType.tarjeta
                              ? Colors.white
                              : Theme.of(context).colorScheme.onPrimary,
                          child: Text(typeLabel),
                        ),
                        title: Text(item.code),
                        subtitle: Text(_formatDate(item.scannedAt)),
                        trailing: isDuplicate
                            ? Icon(Icons.warning, color: Colors.red.shade700)
                            : Icon(
                                item.type == ScanType.solapine 
                                    ? Icons.qr_code 
                                    : Icons.credit_card,
                                color: Colors.blue,
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}