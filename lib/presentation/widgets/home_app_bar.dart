import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/evento_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/csv_provider.dart';
import 'dialogs/filtro_dialog.dart';
import 'dialogs/evento_selector_dialog.dart';
import 'common/connection_indicator.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;
  final bool showActions;
  final bool showConnection;
  final VoidCallback? onCheckConnection;

  const HomeAppBar({
    super.key,
    required this.onMenuPressed,
    this.showActions = true,
    this.showConnection = false,
    this.onCheckConnection,
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
    final eventoActual = eventoProvider.eventoActual;
    final filtro = settings.filtro;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed,
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
        ],
      ),
      centerTitle: true,
      actions: [
        if (showConnection)
          Consumer<CsvProvider>(
            builder: (context, csvProvider, _) {
              return ConnectionIndicator(
                isConnected: csvProvider.isConnected,
                isLoading: csvProvider.isLoading,
                lastCheck: csvProvider.lastConnectionCheck,
                onTap: onCheckConnection ?? () {},
              );
            },
          ),
        if (showActions) ...[
          IconButton(
            icon: const Icon(Icons.event),
            tooltip: 'Cambiar evento',
            onPressed: () => EventoSelectorDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar',
            onPressed: () => _showFiltroDialog(context, filtro),
          ),
        ],
      ],
    );
  }
}