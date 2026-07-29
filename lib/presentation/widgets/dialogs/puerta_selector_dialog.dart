import 'package:flutter/material.dart';
import '../../../domain/entities/puerta.dart';

class PuertaSelectorDialog extends StatefulWidget {
  const PuertaSelectorDialog({super.key});

  static Future<String?> show(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PuertaSelectorDialog(),
    );
  }

  @override
  State<PuertaSelectorDialog> createState() => _PuertaSelectorDialogState();
}

class _PuertaSelectorDialogState extends State<PuertaSelectorDialog> {
  String? _puertaSeleccionada;
  String? _comedorSeleccionado;

  @override
  Widget build(BuildContext context) {
    final comedores = PuertaService.comedores;

    return AlertDialog(
      titlePadding: const EdgeInsets.only(top: 12, left: 20, right: 16),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Puerta', style: TextStyle(fontSize: 18)),
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
            DropdownButtonFormField<String>(
              initialValue: _comedorSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Comedor',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: comedores.map((comedor) {
                return DropdownMenuItem(
                  value: comedor,
                  child: Text(comedor, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _comedorSeleccionado = value;
                  _puertaSeleccionada = null;
                });
              },
            ),
            const SizedBox(height: 12),
            if (_comedorSeleccionado != null)
              SizedBox(
                height: 180,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: PuertaService.getPuertasPorComedor(_comedorSeleccionado!).length,
                  itemBuilder: (context, index) {
                    final puerta = PuertaService.getPuertasPorComedor(_comedorSeleccionado!)[index];
                    final isSelected = _puertaSeleccionada == puerta.numero;
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? Theme.of(context).colorScheme.primary : null,
                        size: 22,
                      ),
                      title: Text(
                        puerta.numero,
                        style: const TextStyle(fontSize: 15),
                      ),
                      onTap: () => setState(() => _puertaSeleccionada = puerta.numero),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(fontSize: 14)),
        ),
        ElevatedButton(
          onPressed: _puertaSeleccionada != null
              ? () => Navigator.of(context).pop(_puertaSeleccionada)
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