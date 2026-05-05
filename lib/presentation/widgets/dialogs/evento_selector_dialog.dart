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
      title: const Text('Seleccionar Evento', style: TextStyle(fontSize: 22)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Selecciona el evento para poder escanear:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Evento Doble', style: TextStyle(fontSize: 18)),
            subtitle: const Text('Dos escaneos por persona', style: TextStyle(fontSize: 14)),
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
                    title: Text(evento.displayName, style: const TextStyle(fontSize: 18)),
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      size: 28,
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
          child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
        ),
        ElevatedButton(
          onPressed: _eventoSeleccionado != null
              ? () {
                  context.read<EventoProvider>().seleccionarEvento(_eventoSeleccionado!);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Confirmar', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}