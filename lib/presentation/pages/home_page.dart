import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/validation_utils.dart';
import '../../domain/entities/scan_item.dart';
import '../providers/scan_provider.dart';
import '../providers/evento_provider.dart';
import '../providers/csv_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/scanner/scanner_widget.dart';
import '../widgets/solapines_list.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_nav_bar.dart';
import '../widgets/dialogs/add_manual_dialog.dart';
import '../widgets/drawer/app_drawer.dart';
import '../widgets/overlay/overlay_message.dart';
import '../widgets/common/math_curve_loader.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanProvider>().init();
      context.read<CsvProvider>().init();
    });
  }

  void _onItemScanned(String code) {
    final eventoProvider = context.read<EventoProvider>();
    if (!eventoProvider.tieneEventoSeleccionado) {
      OverlayMessage.error(context, 'Selecciona un evento primero');
      return;
    }
    final csvProvider = context.read<CsvProvider>();
    final provider = context.read<ScanProvider>();
    if (!ValidationUtils.isValidCode(code)) {
      OverlayMessage.error(context, ValidationUtils.validateCode(code) ?? 'Código inválido');
      return;
    }
    final isNew = provider.addItemFromScanner(code, eventoProvider.eventoActual!, csvProvider.personas);
    if (isNew) {
      final item = provider.items.last;
      if (item.status == ScanStatus.reserved) {
        OverlayMessage.success(context, '${item.personaNombre} - Solapín ${item.personaSolapine}');
      } else {
        OverlayMessage.warning(context, 'Código no encontrado en lista');
      }
    } else {
      if (provider.items.any((i) => i.code.toUpperCase() == code.toUpperCase() && i.status == ScanStatus.notReservedDuplicate)) {
        OverlayMessage.error(context, 'No reservado y duplicado');
      } else {
        OverlayMessage.error(context, 'Duplicado');
      }
    }
  }

  void _addItemManually(String code) {
    final eventoProvider = context.read<EventoProvider>();
    if (!eventoProvider.tieneEventoSeleccionado) {
      OverlayMessage.error(context, 'Selecciona un evento primero');
      return;
    }
    final csvProvider = context.read<CsvProvider>();
    final provider = context.read<ScanProvider>();
    if (!ValidationUtils.isValidCode(code)) {
      OverlayMessage.error(context, ValidationUtils.validateCode(code) ?? 'Código inválido');
      return;
    }
    final isNew = provider.addItemManual(code, eventoProvider.eventoActual!, csvProvider.personas);
    if (isNew) {
      final item = provider.items.last;
      if (item.status == ScanStatus.reserved) {
        OverlayMessage.success(context, '${item.personaNombre} - Solapín ${item.personaSolapine}');
      } else {
        OverlayMessage.warning(context, 'Código no encontrado en lista');
      }
    } else {
      if (provider.items.any((i) => i.code.toUpperCase() == code.toUpperCase() && i.status == ScanStatus.notReservedDuplicate)) {
        OverlayMessage.error(context, 'No reservado y duplicado');
      } else {
        OverlayMessage.error(context, 'Duplicado');
      }
    }
  }

  void _showAddManualDialog() => AddManualDialog.show(context, _addItemManually);

  Future<void> _checkConnection(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final csvProvider = context.read<CsvProvider>();

    if (settings.csvUrl.isEmpty) {
      OverlayMessage.error(context, 'Ingresa una URL primero');
      return;
    }

    final isConnected = await csvProvider.checkConnection(settings.csvUrl);
    if (!context.mounted) return;

    if (isConnected) {
      OverlayMessage.success(context, 'Conexión exitosa');
    } else {
      OverlayMessage.error(context, 'Sin conexión');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isLargeScreen = screenWidth > 600;
        
        return Consumer<ScanProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return Scaffold(
                body: Center(
                  child: MathCurveLoader.epicycloid(
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            }

            return Scaffold(
              key: _scaffoldKey,
              appBar: HomeAppBar(
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                showActions: _selectedIndex == 0,
                showConnection: _selectedIndex == 1,
                onCheckConnection: _selectedIndex == 1 ? () => _checkConnection(context) : null,
              ),
              drawer: const AppDrawer(),
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
                child: _selectedIndex == 0
                    ? Column(
                        key: const ValueKey(0),
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isLargeScreen ? 32 : screenWidth * 0.03,
                              vertical: 8,
                            ),
                            child: ScannerWidget(
                              onSolapineScanned: _onItemScanned,
                              onScan: () => settings.triggerScanFeedback(),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isLargeScreen ? 800 : double.infinity,
                                ),
                                child: SolapinesList(provider: provider),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SettingsPage(key: ValueKey(1)),
              ),
              floatingActionButton: _selectedIndex == 0
                  ? FloatingActionButton(
                      key: const ValueKey('fab_add'),
                      onPressed: _showAddManualDialog,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: const Icon(Icons.add),
                    )
                  : null,
              bottomNavigationBar: HomeNavBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              ),
            );
          },
        );
      },
    );
  }
}