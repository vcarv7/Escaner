import 'package:flutter/material.dart';

class AddManualDialog extends StatelessWidget {
  final void Function(String) onAdd;

  const AddManualDialog({super.key, required this.onAdd});

  static Future<void> show(BuildContext context, void Function(String) onAdd) {
    return showDialog(
      context: context,
      builder: (context) => AddManualDialog(onAdd: onAdd),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    final viewInsets = MediaQuery.of(context).viewInsets;

    return AlertDialog(
      title: const Text('Agregar código manualmente', style: TextStyle(fontSize: 20)),
      content: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom > 0 ? 8 : 0),
          child: Semantics(
            label: 'Ingresa el número de solapín',
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'Ingresa el número de solapín',
                hintStyle: TextStyle(fontSize: 16),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
              onSubmitted: (_) => _submit(context, controller.text),
            ),
          ),
        ),
      ),
      actions: [
        Semantics(
          label: 'Cancelar ingreso manual',
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
        ),
        Semantics(
          label: 'Agregar código manualmente',
          child: TextButton(
            onPressed: () => _submit(context, controller.text),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Agregar', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  void _submit(BuildContext context, String text) {
    Navigator.of(context).pop();
    if (text.trim().isNotEmpty) {
      onAdd(text.trim());
    }
  }
}