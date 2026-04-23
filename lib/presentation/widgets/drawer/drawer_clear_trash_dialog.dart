import 'package:flutter/material.dart';
import 'drawer_constants.dart';
import 'drawer_colors.dart';

class DrawerClearTrashDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const DrawerClearTrashDialog({
    super.key,
    required this.onConfirm,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onConfirm}) {
    return showDialog(
      context: context,
      builder: (context) => DrawerClearTrashDialog(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DrawerConstants.cardRadius),
      ),
      title: const Text(
        'Vaciar papelera',
        style: TextStyle(color: DrawerColors.error),
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: const Text(
            '¿Estás seguro de que quieres eliminar permanentemente todos los elementos de la papelera?',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DrawerColors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Vaciar'),
        ),
      ],
    );
  }
}