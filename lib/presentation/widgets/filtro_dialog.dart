import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class FiltroDialog extends StatefulWidget {
  final FiltroData filtroInicial;

  const FiltroDialog({super.key, required this.filtroInicial});

  static Future<FiltroData?> show(BuildContext context, FiltroData filtroInicial) async {
    return showDialog<FiltroData>(
      context: context,
      builder: (context) => FiltroDialog(filtroInicial: filtroInicial),
    );
  }

  @override
  State<FiltroDialog> createState() => _FiltroDialogState();
}

class _FiltroDialogState extends State<FiltroDialog> {
  late DateTime _fechaSeleccionada;
  dynamic _eventoSeleccionado;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = widget.filtroInicial.fecha;
    _eventoSeleccionado = widget.filtroInicial.evento;
  }

  static const List<_EventoItem> _eventos = [
    _EventoItem('Desayuno', false),
    _EventoItem('Desayuno', true),
    _EventoItem('Almuerzo', false),
    _EventoItem('Almuerzo', true),
    _EventoItem('Comida', false),
    _EventoItem('Comida', true),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrar Lista'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Fecha'),
            subtitle: Text(
              '${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _seleccionarFecha,
          ),
          const SizedBox(height: 8),
          DropdownButton<dynamic>(
            value: _eventoSeleccionado,
            hint: const Text('Todos los eventos'),
            isExpanded: true,
            items: [
              const DropdownMenuItem<dynamic>(
                value: null,
                child: Text('Todos los eventos'),
              ),
              ..._eventos.map((evento) {
                return DropdownMenuItem<dynamic>(
                  value: evento,
                  child: Text(evento.displayName),
                );
              }),
            ],
            onChanged: (value) {
              setState(() => _eventoSeleccionado = value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final settings = context.read<SettingsProvider>();
            settings.setFiltro(FiltroData(fecha: DateTime.now(), evento: null));
            Navigator.of(context).pop();
          },
          child: const Text('Limpiar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final settings = context.read<SettingsProvider>();
            settings.setFiltro(FiltroData(fecha: _fechaSeleccionada, evento: _eventoSeleccionado));
            Navigator.of(context).pop(FiltroData(fecha: _fechaSeleccionada, evento: _eventoSeleccionado));
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }
}

class _EventoItem {
  final String nombre;
  final bool esDoble;
  const _EventoItem(this.nombre, this.esDoble);
  String get displayName => esDoble ? '$nombre Doble' : nombre;
}