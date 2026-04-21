import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/validation_utils.dart';
import '../../data/services/excel_service.dart';
import '../../domain/entities/scan_item.dart';
import '../providers/scan_provider.dart';
import '../widgets/scanner_widget.dart';
import '../widgets/solapines_list.dart';
import '../widgets/snack_bar_helper.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_nav_bar.dart';
import '../widgets/add_manual_dialog.dart';
import '../widgets/app_drawer.dart';

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
      SnackBarHelper.showError(context, ValidationUtils.validateCode(code) ?? 'Código inválido');
      return;
    }
    final isNew = !provider.items.any((s) => s.code == code);
    provider.addItem(code);
    if (isNew) {
      final type = ValidationUtils.detectType(code);
      final typeLabel = type == ScanType.solapine ? 'Solapín' : 'Tarjeta';
      SnackBarHelper.showSuccess(context, '$typeLabel $code escaneado');
    } else {
      SnackBarHelper.showError(context, 'Código duplicado', long: true);
    }
  }

  void _addItemManually(String code) {
    final provider = context.read<ScanProvider>();
    if (!ValidationUtils.isValidCode(code)) {
      SnackBarHelper.showError(context, ValidationUtils.validateCode(code) ?? 'Código inválido');
      return;
    }
    final isNew = !provider.items.any((s) => s.code == code);
    provider.addItem(code);
    if (isNew) {
      final type = ValidationUtils.detectType(code);
      final typeLabel = type == ScanType.solapine ? 'Solapín' : 'Tarjeta';
      SnackBarHelper.showSuccess(context, '$typeLabel $code agregado');
    } else {
      SnackBarHelper.showError(context, 'Código duplicado', long: true);
    }
  }

  void _showAddManualDialog() => AddManualDialog.show(context, _addItemManually);

  Future<void> _importFromExcel() async {
    final codes = await ExcelService.importFromExcel();
    if (!mounted) return;
    if (codes.isEmpty) {
      SnackBarHelper.showWarning(context, 'No se encontraron códigos en el archivo');
      return;
    }
    context.read<ScanProvider>().importCodes(codes);
    SnackBarHelper.showSuccess(context, '${codes.length} códigos importados');
  }

  Future<void> _exportToExcel() async {
    final provider = context.read<ScanProvider>();
    if (provider.items.isEmpty) {
      if (mounted) SnackBarHelper.showWarning(context, 'No hay códigos para exportar');
      return;
    }
    final filePath = await ExcelService.exportToExcel(provider.items);
    if (filePath != null) {
      await Share.shareXFiles([XFile(filePath)], text: 'Códigos escaneados');
      if (mounted) SnackBarHelper.showSuccess(context, 'Excel preparado para compartir');
    } else {
      if (mounted) SnackBarHelper.showError(context, 'Error al generar Excel');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          key: _scaffoldKey,
          appBar: HomeAppBar(onMenuPressed: () => _scaffoldKey.currentState?.openDrawer()),
          drawer: AppDrawer(onImport: _importFromExcel, onExport: _exportToExcel),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ScannerWidget(onSolapineScanned: _onItemScanned),
              ),
              Expanded(
                child: SolapinesList(provider: provider),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddManualDialog,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: HomeNavBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          ),
        );
      },
    );
  }
}