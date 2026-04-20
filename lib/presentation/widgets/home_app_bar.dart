import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final bool hasUndoItem;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback? onUndo;

  const HomeAppBar({
    super.key,
    required this.selectedIndex,
    required this.hasUndoItem,
    required this.onImport,
    required this.onExport,
    this.onUndo,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.restaurant),
      ),
      title: const Text('Escáner'),
      actions: [
        if (selectedIndex == 0) ...[
          if (hasUndoItem && onUndo != null)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: onUndo,
              tooltip: 'Deshacer',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: onImport,
            tooltip: 'Importar desde Excel',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: onExport,
            tooltip: 'Exportar a Excel',
          ),
        ],
      ],
    );
  }
}