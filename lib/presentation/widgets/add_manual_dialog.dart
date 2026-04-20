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

    return AlertDialog(
      title: const Text('Agregar código manualmente'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Ingresa el código',
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.characters,
        autofocus: true,
        onSubmitted: (_) => _submit(context, controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => _submit(context, controller.text),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: const Text('Agregar'),
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