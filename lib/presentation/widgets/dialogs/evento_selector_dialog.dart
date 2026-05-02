import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/evento.dart';
import '../../providers/evento_provider.dart';

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
    final eventosFiltrados = Evento.values.where((e) => e.esDoble == _esDoble).toList();

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
              setState(() {
                _esDoble = value;
                _eventoSeleccionado = null;
              });
            },
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: eventosFiltrados.map((evento) {
                  final isSelected = _eventoSeleccionado == evento;
                  return ListTile(
                    title: Text(evento.displayName),
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                    onTap: () => setState(() => _eventoSeleccionado = evento),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
            ),
          ),
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