import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/evento.dart';
import '../providers/evento_provider.dart';

class EventoSelectorDialog extends StatefulWidget {
  const EventoSelectorDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const EventoSelectorDialog(),
    );
  }

  @override
  State<EventoSelectorDialog> createState() => _EventoSelectorDialogState();
}

class _EventoSelectorDialogState extends State<EventoSelectorDialog> {
  Evento? _eventoSeleccionado;
  bool _esDoble = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Evento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Selecciona el evento para poder escanear:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Evento Doble'),
            subtitle: const Text('Dos escaneos por persona'),
            value: _esDoble,
            onChanged: (value) {
              setState(() => _esDoble = value);
            },
          ),
          const SizedBox(height: 8),
          ...Evento.values.where((e) => e.esDoble == _esDoble).map((evento) {
            return RadioListTile<Evento>(
              title: Text(evento.displayName),
              value: evento,
              groupValue: _eventoSeleccionado,
              onChanged: (value) {
                setState(() => _eventoSeleccionado = value);
              },
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _eventoSeleccionado != null
              ? () {
                  context.read<EventoProvider>().seleccionarEvento(_eventoSeleccionado!);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}