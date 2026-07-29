import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/evento_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/puerta_provider.dart';
import 'dialogs/filtro_dialog.dart';
import 'dialogs/evento_selector_dialog.dart';
import 'dialogs/puerta_selector_dialog.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;
  final bool showActions;

  const HomeAppBar({
    super.key,
    required this.onMenuPressed,
    this.showActions = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  static Future<FiltroData?> _showFiltroDialog(BuildContext context, FiltroData filtro) async {
    return showDialog<FiltroData>(
      context: context,
      builder: (context) => FiltroDialog(filtroInicial: filtro),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventoProvider = context.watch<EventoProvider>();
    final settings = context.watch<SettingsProvider>();
    final puertaProvider = context.watch<PuertaProvider>();
    final eventoActual = eventoProvider.eventoActual;
    final filtro = settings.filtro;
    final puertaActual = puertaProvider.puertaSeleccionada;

    return AppBar(
      leading: Semantics(
        label: 'Abrir menú lateral',
        child: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: onMenuPressed,
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Escáner'),
          if (eventoActual != null)
            Text(
              eventoActual.displayName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          if (puertaActual != null)
            Text(
              'Puerta: $puertaActual',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
        ],
      ),
      centerTitle: true,
      actions: [
        if (showActions) ...[
          Semantics(
            label: 'Cambiar evento',
            child: IconButton(
              icon: const Icon(Icons.restaurant),
              tooltip: 'Cambiar evento',
              onPressed: () => EventoSelectorDialog.show(context),
            ),
          ),
          Semantics(
            label: 'Cambiar puerta',
            child: IconButton(
              icon: const Icon(Icons.door_front_door),
              tooltip: 'Cambiar puerta',
              onPressed: () async {
                final puerta = await PuertaSelectorDialog.show(
                  context,
                  initialPuerta: puertaActual,
                );
                if (puerta != null) {
                  puertaProvider.seleccionarPuerta(puerta);
                }
              },
            ),
          ),
          Semantics(
            label: 'Filtrar escaneos',
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtrar',
              onPressed: () => _showFiltroDialog(context, filtro),
            ),
          ),
        ],
      ],
    );
  }
}