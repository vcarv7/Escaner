import 'package:flutter/material.dart';

class AddManualDialog extends StatefulWidget {
  final void Function(String) onAdd;

  const AddManualDialog({super.key, required this.onAdd});

  static Future<void> show(BuildContext context, void Function(String) onAdd) {
    return showDialog(
      context: context,
      builder: (context) => AddManualDialog(onAdd: onAdd),
    );
  }

  @override
  State<AddManualDialog> createState() => _AddManualDialogState();
}

class _AddManualDialogState extends State<AddManualDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    Navigator.of(context).pop();
    if (text.isNotEmpty) {
      widget.onAdd(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return AlertDialog(
      title: const Text('Agregar Solapín manualmente', style: TextStyle(fontSize: 20)),
      content: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom > 0 ? 8 : 0),
          child: Semantics(
            label: 'Ingresa el número de solapín',
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'Ingresa el número de solapín',
                hintStyle: TextStyle(fontSize: 16),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.visiblePassword,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
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
          label: 'Agregar Solapín manualmente',
          child: TextButton(
            onPressed: _submit,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Agregar', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}