import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/scan_item.dart';
import '../../data/services/excel_service.dart';
import '../widgets/scanner_widget.dart';
import '../widgets/solapines_list.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<ScanItem> _items = [];

  bool _isValidSolapine(String value) {
    final length = value.length;
    return length >= 5 && length <= 15;
  }

  bool _isValidTarjeta(String value) {
    if (value.length < 5 || value.length > 15) return false;
    return RegExp(r'^[A-Za-z]+$').hasMatch(value);
  }

  ScanType _detectType(String code) {
    if (_isValidTarjeta(code)) {
      return ScanType.tarjeta;
    }
    return ScanType.solapine;
  }

  void _onItemScanned(String code) {
    final type = _detectType(code);
    final isValid = type == ScanType.solapine 
        ? _isValidSolapine(code) 
        : _isValidTarjeta(code);

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El código debe tener entre 5 y 15 caracteres'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final existingIndex = _items.indexWhere((s) => s.code == code);

    if (existingIndex == -1) {
      setState(() {
        _items.add(ScanItem(
          code: code,
          type: type,
          isDuplicate: false,
          scannedAt: DateTime.now(),
        ));
      });
      final typeLabel = type == ScanType.solapine ? 'Solapín' : 'Tarjeta';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$typeLabel $code escaneado'),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 2300),
        ),
      );
    } else {
      setState(() {
        _items[existingIndex] = ScanItem(
          code: code,
          type: type,
          isDuplicate: true,
          scannedAt: _items[existingIndex].scannedAt,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código duplicado'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 3500),
        ),
      );
    }
  }

  void _addItemManually(String code) {
    final type = _detectType(code);
    final isValid = type == ScanType.solapine 
        ? _isValidSolapine(code) 
        : _isValidTarjeta(code);

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El código debe tener entre 5 y 15 caracteres'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final existingIndex = _items.indexWhere((s) => s.code == code);

    if (existingIndex == -1) {
      setState(() {
        _items.add(ScanItem(
          code: code,
          type: type,
          isDuplicate: false,
          scannedAt: DateTime.now(),
        ));
      });
      final typeLabel = type == ScanType.solapine ? 'Solapín' : 'Tarjeta';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$typeLabel $code agregado con éxito'),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 2300),
        ),
      );
    } else {
      setState(() {
        _items[existingIndex] = ScanItem(
          code: code,
          type: type,
          isDuplicate: true,
          scannedAt: _items[existingIndex].scannedAt,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código duplicado'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 3500),
        ),
      );
    }
  }

  void _showAddManualDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar código manualmente'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ingresa el código',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addItemManually(controller.text.trim());
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _clearAllItems() {
    setState(() {
      _items.clear();
    });
  }

  Future<void> _importFromExcel() async {
    final codes = await ExcelService.importFromExcel();

    if (codes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontraron códigos en el archivo'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    int added = 0;
    for (final code in codes) {
      final type = _detectType(code);
      final isValid = type == ScanType.solapine 
          ? _isValidSolapine(code) 
          : _isValidTarjeta(code);
      
      if (!isValid) continue;

      final existingIndex = _items.indexWhere((s) => s.code == code);

      if (existingIndex == -1) {
        _items.add(ScanItem(
          code: code,
          type: type,
          isDuplicate: false,
          scannedAt: DateTime.now(),
        ));
        added++;
      } else {
        _items[existingIndex] = _items[existingIndex].copyWith(
          isDuplicate: true,
        );
        added++;
      }
    }

    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$added códigos importados'),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 2300),
        ),
      );
    }
  }

  Future<void> _exportToExcel() async {
    if (_items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay códigos para exportar'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final filePath = await ExcelService.exportToExcel(_items);

    if (filePath != null) {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Códigos escaneados',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Excel preparado para compartir'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.restaurant),
        ),
        title: const Text('Escáner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _selectedIndex == 0 ? _importFromExcel : null,
            tooltip: 'Importar desde Excel',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _selectedIndex == 0 ? _exportToExcel : null,
            tooltip: 'Exportar a Excel',
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ScannerWidget(onSolapineScanned: _onItemScanned),
                ),
                Expanded(
                  child: SolapinesList(
                    items: _items,
                    onClearAll: _clearAllItems,
                  ),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scans',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}