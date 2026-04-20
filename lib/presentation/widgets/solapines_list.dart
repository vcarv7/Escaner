import 'package:flutter/material.dart';
import '../../domain/entities/solapine_item.dart';

class SolapinesList extends StatelessWidget {
  final List<SolapineItem> solapines;
  final VoidCallback onClearAll;

  const SolapinesList({
    super.key,
    required this.solapines,
    required this.onClearAll,
  });

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todos los solapines'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todos los solapines escaneados?',
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
    final duplicateCount = solapines.where((s) => s.isDuplicate).length;
    final totalCount = solapines.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalCount solapines y $duplicateCount duplicados',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (solapines.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showClearConfirmation(context),
                  tooltip: 'Eliminar todos',
                ),
            ],
          ),
        ),
        Expanded(
          child: solapines.isEmpty
              ? const Center(
                  child: Text('No hay solapines escaneados'),
                )
              : ListView.builder(
                  itemCount: solapines.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final item = solapines[index];
                    return Card(
                      color: item.isDuplicate
                          ? Colors.yellow.withValues(alpha: 0.3)
                          : null,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item.isDuplicate
                              ? Colors.yellow
                              : Theme.of(context).colorScheme.primary,
                          foregroundColor: item.isDuplicate
                              ? Colors.black87
                              : Theme.of(context).colorScheme.onPrimary,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(item.code),
                        subtitle: Text(_formatDate(item.scannedAt)),
                        trailing: item.isDuplicate
                            ? const Icon(Icons.warning, color: Colors.orange)
                            : const Icon(Icons.qr_code),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}