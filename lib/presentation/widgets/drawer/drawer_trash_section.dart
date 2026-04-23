import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/scan_provider.dart';
import 'drawer_constants.dart';
import 'drawer_colors.dart';
import 'drawer_clear_trash_dialog.dart';

class DrawerTrashSection extends StatelessWidget {
  const DrawerTrashSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        final trashItems = provider.trashItems;
        final isEmpty = trashItems.isEmpty;
        final itemCount = trashItems.length;

        return ExpansionTile(
          leading: Container(
            width: DrawerConstants.iconContainerSize,
            height: DrawerConstants.iconContainerSize,
            decoration: BoxDecoration(
              color: DrawerColors.trashBackground,
              borderRadius: BorderRadius.circular(DrawerConstants.smallRadius),
            ),
            child: const Icon(Icons.delete_outline, color: DrawerColors.trashIcon),
          ),
          title: const Text(
            'Papelera',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('$itemCount elementos'),
          children: [
            if (isEmpty)
              const Padding(
                padding: EdgeInsets.all(DrawerConstants.spacingMedium),
                child: Text('La papelera está vacía', style: TextStyle(color: Colors.grey)),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DrawerConstants.spacingSmall,
                  vertical: DrawerConstants.spacingSmall / 2,
                ),
                child: ElevatedButton.icon(
                  onPressed: () => provider.restoreAll(),
                  icon: const Icon(Icons.restore, size: DrawerConstants.iconSize),
                  label: Text('Restaurar todos ($itemCount)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DrawerColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(DrawerConstants.spacingSmall),
                child: TextButton.icon(
                  onPressed: () => _showClearDialog(context, provider),
                  icon: const Icon(Icons.delete_sweep, color: DrawerColors.error),
                  label: const Text(
                    'Vaciar papelera',
                    style: TextStyle(color: DrawerColors.error),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showClearDialog(BuildContext context, ScanProvider provider) {
    DrawerClearTrashDialog.show(
      context,
      onConfirm: () => provider.clearTrash(),
    );
  }
}