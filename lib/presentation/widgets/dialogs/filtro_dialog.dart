import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/evento.dart';
import '../../../domain/entities/puerta.dart';
import '../../providers/settings_provider.dart';

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
  late TipoRangoFecha _tipoRango;
  late DateTime _fechaUnica;
  late RangoPredefinido _predefinido;
  late DateTime? _fechaInicio;
  late DateTime? _fechaFin;
  Evento? _eventoSeleccionado;
  String? _puertaSeleccionada;

  @override
  void initState() {
    super.initState();
    _tipoRango = widget.filtroInicial.tipoRango;
    _fechaUnica = widget.filtroInicial.fecha;
    _predefinido = widget.filtroInicial.predefinido;
    _fechaInicio = widget.filtroInicial.fechaInicio;
    _fechaFin = widget.filtroInicial.fechaFin;
    _eventoSeleccionado = widget.filtroInicial.evento;
    _puertaSeleccionada = widget.filtroInicial.puerta;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrar Lista'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTipoRangoSelector(),
            const SizedBox(height: 16),
            _buildFechaSelector(),
            const SizedBox(height: 16),
            _buildEventoSelector(),
            const SizedBox(height: 16),
            _buildPuertaSelector(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _limpiarFiltro,
          child: const Text('Limpiar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _aplicarFiltro,
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  Widget _buildTipoRangoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de fecha:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Única'),
              selected: _tipoRango == TipoRangoFecha.unico,
              onSelected: (selected) {
                if (selected) setState(() => _tipoRango = TipoRangoFecha.unico);
              },
            ),
            ChoiceChip(
              label: const Text('Predefinido'),
              selected: _tipoRango == TipoRangoFecha.predefinido,
              onSelected: (selected) {
                if (selected) setState(() => _tipoRango = TipoRangoFecha.predefinido);
              },
            ),
            ChoiceChip(
              label: const Text('Rango'),
              selected: _tipoRango == TipoRangoFecha.personalizado,
              onSelected: (selected) {
                if (selected) setState(() => _tipoRango = TipoRangoFecha.personalizado);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFechaSelector() {
    switch (_tipoRango) {
      case TipoRangoFecha.unico:
        return _buildFechaUnica();
      case TipoRangoFecha.predefinido:
        return _buildPredefinido();
      case TipoRangoFecha.personalizado:
        return _buildRangoPersonalizado();
    }
  }

  Widget _buildFechaUnica() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Fecha'),
      subtitle: Text('${_fechaUnica.day}/${_fechaUnica.month}/${_fechaUnica.year}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: _seleccionarFechaUnica,
    );
  }

  Widget _buildPredefinido() {
    return DropdownButton<RangoPredefinido>(
      value: _predefinido,
      isExpanded: true,
      items: const [
        DropdownMenuItem(value: RangoPredefinido.hoy, child: Text('Hoy')),
        DropdownMenuItem(value: RangoPredefinido.ayer, child: Text('Ayer')),
        DropdownMenuItem(value: RangoPredefinido.ultimos7, child: Text('Últimos 7 días')),
        DropdownMenuItem(value: RangoPredefinido.ultimos30, child: Text('Últimos 30 días')),
        DropdownMenuItem(value: RangoPredefinido.estaSemana, child: Text('Esta semana')),
        DropdownMenuItem(value: RangoPredefinido.esteMes, child: Text('Este mes')),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _predefinido = value);
      },
    );
  }

  Widget _buildRangoPersonalizado() {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Inicio', style: TextStyle(fontSize: 12)),
            subtitle: Text(_fechaInicio != null 
                ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}' 
                : 'Seleccionar'),
            trailing: const Icon(Icons.calendar_today, size: 20),
            onTap: () => _seleccionarFecha(true),
          ),
        ),
        const Text(' - '),
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fin', style: TextStyle(fontSize: 12)),
            subtitle: Text(_fechaFin != null 
                ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}' 
                : 'Seleccionar'),
            trailing: const Icon(Icons.calendar_today, size: 20),
            onTap: () => _seleccionarFecha(false),
          ),
        ),
      ],
    );
  }

  Widget _buildEventoSelector() {
    return DropdownButton<Evento?>(
      value: _eventoSeleccionado,
      hint: const Text('Todos los eventos'),
      isExpanded: true,
      items: [
        const DropdownMenuItem<Evento?>(
          value: null,
          child: Text('Todos los eventos'),
        ),
        ...Evento.values.map((evento) {
          return DropdownMenuItem<Evento?>(
            value: evento,
            child: Text(evento.displayName),
          );
        }),
      ],
      onChanged: (value) {
        setState(() => _eventoSeleccionado = value);
      },
    );
  }

  Widget _buildPuertaSelector() {
    final puertas = PuertaService.puertas.map((p) => p.numero).toSet().toList()..sort();
    
    return DropdownButton<String?>(
      value: _puertaSeleccionada,
      hint: const Text('Todas las puertas'),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Todas las puertas'),
        ),
        ...puertas.map((puerta) {
          return DropdownMenuItem<String?>(
            value: puerta,
            child: Text('Puerta $puerta'),
          );
        }),
      ],
      onChanged: (value) {
        setState(() => _puertaSeleccionada = value);
      },
    );
  }

  Future<void> _seleccionarFechaUnica() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaUnica,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      setState(() => _fechaUnica = fecha);
    }
  }

  Future<void> _seleccionarFecha(bool isInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: isInicio ? (_fechaInicio ?? DateTime.now()) : (_fechaFin ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      setState(() {
        if (isInicio) {
          _fechaInicio = fecha;
        } else {
          _fechaFin = fecha;
        }
      });
    }
  }

  void _limpiarFiltro() {
    final settings = context.read<SettingsProvider>();
    settings.setFiltro(FiltroData(fecha: DateTime.now()));
    Navigator.of(context).pop();
  }

  void _aplicarFiltro() {
    // Validar y normalizar rango personalizado.
    DateTime? inicio = _fechaInicio;
    DateTime? fin = _fechaFin;
    if (_tipoRango == TipoRangoFecha.personalizado &&
        inicio != null && fin != null && inicio.isAfter(fin)) {
      final tmp = inicio;
      inicio = fin;
      fin = tmp;
    }
    final filtro = FiltroData(
      fecha: _fechaUnica,
      tipoRango: _tipoRango,
      predefinido: _tipoRango == TipoRangoFecha.predefinido ? _predefinido : RangoPredefinido.hoy,
      fechaInicio: _tipoRango == TipoRangoFecha.personalizado ? inicio : null,
      fechaFin: _tipoRango == TipoRangoFecha.personalizado ? fin : null,
      evento: _eventoSeleccionado,
      puerta: _puertaSeleccionada,
    );
    final settings = context.read<SettingsProvider>();
    settings.setFiltro(filtro);
    Navigator.of(context).pop(filtro);
  }
}