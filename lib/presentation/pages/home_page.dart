import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/validation_utils.dart';
import '../../domain/entities/scan_item.dart';
import '../providers/scan_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/scanner_widget.dart';
import '../widgets/solapines_list.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_nav_bar.dart';
import '../widgets/add_manual_dialog.dart';
import '../widgets/drawer/app_drawer.dart';
import '../widgets/overlay/overlay_message.dart';
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
    });
  }

  void _onItemScanned(String code) {
    final provider = context.read<ScanProvider>();
    if (!ValidationUtils.isValidCode(code)) {
      OverlayMessage.error(context, ValidationUtils.validateCode(code) ?? 'Código inválido');
      return;
    }
    final isNew = !provider.items.any((s) => s.code == code);
    provider.addItem(code);
    if (isNew) {
      final type = ValidationUtils.detectType(code);
      final typeLabel = type == ScanType.solapine ? 'Solapín' : 'Tarjeta';
      OverlayMessage.success(context, '$typeLabel $code escaneado');
    } else {
      OverlayMessage.error(context, 'Código duplicado');
    }
  }

  void _addItemManually(String code) {
    final provider = context.read<ScanProvider>();
    if (!ValidationUtils.isValidCode(code)) {
      OverlayMessage.error(context, ValidationUtils.validateCode(code) ?? 'Código inválido');
      return;
    }
    final isNew = !provider.items.any((s) => s.code == code);
    provider.addItem(code);
    if (isNew) {
      final type = ValidationUtils.detectType(code);
      final typeLabel = type == ScanType.solapine ? 'Solapín' : 'Tarjeta';
      OverlayMessage.success(context, '$typeLabel $code agregado');
    } else {
      OverlayMessage.error(context, 'Código duplicado');
    }
  }

  void _showAddManualDialog() => AddManualDialog.show(context, _addItemManually);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          key: _scaffoldKey,
          appBar: HomeAppBar(onMenuPressed: () => _scaffoldKey.currentState?.openDrawer()),
          drawer: const AppDrawer(),
          body: _selectedIndex == 0
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ScannerWidget(
                        onSolapineScanned: _onItemScanned,
                        onScan: () => settings.triggerScanFeedback(),
                      ),
                    ),
                    Expanded(
                      child: SolapinesList(provider: provider),
                    ),
                  ],
                )
              : const SettingsPage(),
          floatingActionButton: _selectedIndex == 0
              ? FloatingActionButton(
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
  }
}