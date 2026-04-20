import 'package:flutter/material.dart';
import '../../domain/entities/solapine_item.dart';
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
  final List<SolapineItem> _solapines = [];

  bool _isValidSolapine(String value) {
    final length = value.length;
    return length >= 5 && length <= 15;
  }

  void _onSolapineScanned(String solapine) {
    if (!_isValidSolapine(solapine)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El código debe tener entre 5 y 15 caracteres'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final existingIndex = _solapines.indexWhere((s) => s.code == solapine);

    if (existingIndex == -1) {
      setState(() {
        _solapines.add(SolapineItem(
          code: solapine,
          isDuplicate: false,
          scannedAt: DateTime.now(),
        ));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solapín $solapine escaneado'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      setState(() {
        _solapines[existingIndex] = SolapineItem(
          code: solapine,
          isDuplicate: true,
          scannedAt: _solapines[existingIndex].scannedAt,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solapín duplicado'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _addSolapineManually(String solapine) {
    if (!_isValidSolapine(solapine)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El código debe tener entre 5 y 15 caracteres'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final existingIndex = _solapines.indexWhere((s) => s.code == solapine);

    if (existingIndex == -1) {
      setState(() {
        _solapines.add(SolapineItem(
          code: solapine,
          isDuplicate: false,
          scannedAt: DateTime.now(),
        ));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solapín $solapine agregado con éxito'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      setState(() {
        _solapines[existingIndex] = SolapineItem(
          code: solapine,
          isDuplicate: true,
          scannedAt: _solapines[existingIndex].scannedAt,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solapín duplicado'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showAddManualDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar solapín manualmente'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ingresa el código del solapín',
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
              _addSolapineManually(controller.text.trim());
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

  void _clearAllSolapines() {
    setState(() {
      _solapines.clear();
    });
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
      ),
      body: _selectedIndex == 0
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ScannerWidget(onSolapineScanned: _onSolapineScanned),
                ),
                Expanded(
                  child: SolapinesList(
                    solapines: _solapines,
                    onClearAll: _clearAllSolapines,
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