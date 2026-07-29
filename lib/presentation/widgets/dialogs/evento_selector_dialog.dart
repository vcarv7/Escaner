import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/evento.dart';
import '../../providers/evento_provider.dart';

class EventoSelectorDialog extends StatefulWidget {
  const EventoSelectorDialog({super.key});

  static Future<Evento?> show(BuildContext context) async {
    return showDialog<Evento>(
      context: context,
      barrierDismissible: true,
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
      titlePadding: const EdgeInsets.only(top: 12, left: 20, right: 16),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Evento', style: TextStyle(fontSize: 18)),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Doble', style: TextStyle(fontSize: 14)),
                Switch(
                  value: _esDoble,
                  onChanged: (value) {
                    setState(() {
                      _esDoble = value;
                      _eventoSeleccionado = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...eventosFiltrados.map((evento) {
              final isSelected = _eventoSeleccionado == evento;
              return SizedBox(
                height: 44,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    size: 22,
                  ),
                  title: Text(
                    evento.displayName,
                    style: const TextStyle(fontSize: 15),
                  ),
                  onTap: () => setState(() => _eventoSeleccionado = evento),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(fontSize: 14)),
        ),
        ElevatedButton(
          onPressed: _eventoSeleccionado != null
              ? () {
                  context.read<EventoProvider>().seleccionarEvento(_eventoSeleccionado!);
                  Navigator.of(context).pop(_eventoSeleccionado);
                }
              : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('OK', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}