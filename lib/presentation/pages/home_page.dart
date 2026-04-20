import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/scan_item.dart';
import '../../core/utils/validation_utils.dart';
import '../../data/services/excel_service.dart';
import '../../data/services/storage_service.dart';
import '../widgets/scanner_widget.dart';
import '../widgets/solapines_list.dart';
import '../widgets/snack_bar_helper.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_nav_bar.dart';
import '../widgets/add_manual_dialog.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final List<ScanItem> initialItems;

  const HomePage({super.key, this.initialItems = const []});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<ScanItem> _items;
  ScanItem? _lastRemovedItem;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialItems != oldWidget.initialItems) {
      _items = List.from(widget.initialItems);
    }
  }

  Future<void> _saveItems() => StorageService.saveItems(_items);

  void _addOrUpdateItem(String code, {bool isFromScanner = true}) {
    final type = ValidationUtils.detectType(code);

    if (!ValidationUtils.isValidCode(code)) {
      SnackBarHelper.showError(
        context,
        ValidationUtils.validateCode(code) ?? 'Código inválido',
      );
      return;
    }

    final existingIndex = _items.indexWhere((s) => s.code == code);
    final isNew = existingIndex == -1;

    setState(() {
      if (isNew) {
        _items.add(ScanItem(
          code: code,
          type: type,
          isDuplicate: false,
          scannedAt: DateTime.now(),
        ));
      } else {
        _items[existingIndex] = _items[existingIndex].copyWith(isDuplicate: true);
      }
    });

    _saveItems();

    if (isNew) {
      final typeLabel = type == ScanType.solapine ? 'Solapín' : 'Tarjeta';
      final action = isFromScanner ? 'escaneado' : 'agregado';
      SnackBarHelper.showSuccess(context, '$typeLabel $code $action');
    } else {
      SnackBarHelper.showError(context, 'Código duplicado', long: true);
    }
  }

  void _onItemScanned(String code) => _addOrUpdateItem(code, isFromScanner: true);

  void _addItemManually(String code) => _addOrUpdateItem(code, isFromScanner: false);

  void _showAddManualDialog() => AddManualDialog.show(context, _addItemManually);

  void _clearAllItems() {
    if (_items.isNotEmpty) _lastRemovedItem = _items.last;
    setState(() => _items.clear());
    _saveItems();
  }

  void _undoLastRemove() {
    if (_lastRemovedItem != null) {
      setState(() => _items.add(_lastRemovedItem!));
      _saveItems();
      _lastRemovedItem = null;
      SnackBarHelper.showSuccess(context, 'Elemento restaurado');
    }
  }

  Future<void> _importFromExcel() async {
    final codes = await ExcelService.importFromExcel();

    if (codes.isEmpty) {
      if (mounted) SnackBarHelper.showWarning(context, 'No se encontraron códigos en el archivo');
      return;
    }

    for (final code in codes) {
      if (!ValidationUtils.isValidCode(code)) continue;

      final existingIndex = _items.indexWhere((s) => s.code == code);
      final type = ValidationUtils.detectType(code);

      if (existingIndex == -1) {
        _items.add(ScanItem(
          code: code,
          type: type,
          isDuplicate: false,
          scannedAt: DateTime.now(),
        ));
      } else {
        _items[existingIndex] = _items[existingIndex].copyWith(isDuplicate: true);
      }
    }

    setState(() {});
    await _saveItems();
    if (mounted) SnackBarHelper.showSuccess(context, '${codes.length} códigos importados');
  }

  Future<void> _exportToExcel() async {
    if (_items.isEmpty) {
      if (mounted) SnackBarHelper.showWarning(context, 'No hay códigos para exportar');
      return;
    }

    final filePath = await ExcelService.exportToExcel(_items);

    if (filePath != null) {
      await Share.shareXFiles([XFile(filePath)], text: 'Códigos escaneados');
      if (mounted) SnackBarHelper.showSuccess(context, 'Excel preparado para compartir');
    } else {
      if (mounted) SnackBarHelper.showError(context, 'Error al generar Excel');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        selectedIndex: _selectedIndex,
        hasUndoItem: _lastRemovedItem != null,
        onImport: _importFromExcel,
        onExport: _exportToExcel,
        onUndo: _undoLastRemove,
      ),
      body: _selectedIndex == 0 ? _buildScanPage() : const SettingsPage(),
      floatingActionButton: _selectedIndex == 0 ? _buildFab() : null,
      bottomNavigationBar: HomeNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildScanPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ScannerWidget(onSolapineScanned: _onItemScanned),
        ),
        Expanded(
          child: SolapinesList(items: _items, onClearAll: _clearAllItems),
        ),
      ],
    );
  }

  FloatingActionButton _buildFab() {
    return FloatingActionButton(
      onPressed: _showAddManualDialog,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      child: const Icon(Icons.add),
    );
  }
}