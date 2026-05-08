import 'package:flutter/foundation.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/auto_delete_service.dart';
import '../../domain/entities/scan_item.dart';
import '../../domain/entities/evento.dart';
import '../../domain/entities/persona.dart';
import '../../core/constants/app_constants.dart';

class ScanProvider extends ChangeNotifier {
  late List<ScanItem> _items;
  late List<ScanItem> _trashItems;
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;

  List<ScanItem> get items => _items;
  List<ScanItem> get trashItems => _trashItems;
  bool get isLoading => _isLoading;
  bool get hasMoreData => _hasMoreData;
  int get currentPage => _currentPage;

  Future<void> init() async {
    _items = await StorageService.loadItems();
    _trashItems = await StorageService.loadTrash();
    _isLoading = false;
    AutoDeleteService.iniciar();
    notifyListeners();
  }

  List<ScanItem> getItemsPage(int page) {
    final start = (page - 1) * AppConstants.pageSize;
    final end = start + AppConstants.pageSize;
    if (start >= _items.length) return [];
    return _items.sublist(start, end.clamp(0, _items.length));
  }

  bool addItem(String code, Evento evento, List<Persona> personas) {
    return addItemFromScanner(code, evento, personas);
  }

  bool addItemFromScanner(String code, Evento evento, List<Persona> personas) {
    final codeNormalized = code.toUpperCase();
    if (!_isValidCode(codeNormalized)) return false;

    final existingIndex = _items.indexWhere((s) => s.code.toUpperCase() == codeNormalized);
    final persona = _findPersonaByCodigoSolapin(codeNormalized, personas);

    if (existingIndex != -1) {
      final existing = _items[existingIndex];
      final newStatus = persona != null
          ? ScanStatus.duplicate
          : ScanStatus.notReservedDuplicate;
      _items[existingIndex] = existing.copyWith(
        isDuplicate: true,
        status: newStatus,
      );
      _saveItems();
      notifyListeners();
      return false;
    }

    ScanStatus status;
    if (persona != null) {
      status = ScanStatus.reserved;
    } else {
      status = ScanStatus.notReserved;
    }

    _items.add(ScanItem(
      code: codeNormalized,
      type: ScanType.solapine,
      isDuplicate: false,
      scannedAt: DateTime.now(),
      evento: evento,
      personaSolapine: persona?.solapin,
      personaNombre: persona?.nombreCompleto,
      status: status,
    ));
    _hasMoreData = _currentPage * AppConstants.pageSize < _items.length;
    _saveItems();
    notifyListeners();
    return true;
  }

  bool addItemManual(String code, Evento evento, List<Persona> personas) {
    final codeNormalized = code.toUpperCase();
    if (!_isValidCode(codeNormalized)) return false;

    final existingIndex = _items.indexWhere((s) => s.code.toUpperCase() == codeNormalized);
    final persona = _findPersonaBySolapin(codeNormalized, personas);

    if (existingIndex != -1) {
      final existing = _items[existingIndex];
      final newStatus = persona != null
          ? ScanStatus.duplicate
          : ScanStatus.notReservedDuplicate;
      _items[existingIndex] = existing.copyWith(
        isDuplicate: true,
        status: newStatus,
      );
      _saveItems();
      notifyListeners();
      return false;
    }

    ScanStatus status;
    if (persona != null) {
      status = ScanStatus.reserved;
    } else {
      status = ScanStatus.notReserved;
    }

    _items.add(ScanItem(
      code: codeNormalized,
      type: ScanType.solapine,
      isDuplicate: false,
      scannedAt: DateTime.now(),
      evento: evento,
      personaSolapine: persona?.solapin,
      personaNombre: persona?.nombreCompleto,
      status: status,
    ));
    _hasMoreData = _currentPage * AppConstants.pageSize < _items.length;
    _saveItems();
    notifyListeners();
    return true;
  }

  Persona? _findPersonaByCodigoSolapin(String code, List<Persona> personas) {
    final codeLower = code.toLowerCase();
    for (final persona in personas) {
      if (persona.codigoSolapin.toLowerCase() == codeLower) {
        return persona;
      }
    }
    return null;
  }

  Persona? _findPersonaBySolapin(String code, List<Persona> personas) {
    final codeLower = code.toLowerCase();
    for (final persona in personas) {
      if (persona.solapin.toLowerCase() == codeLower) {
        return persona;
      }
    }
    return null;
  }

  bool _isValidCode(String code) {
    if (code.isEmpty) return false;
    final length = code.length;
    return length >= AppConstants.minCodeLength && length <= AppConstants.maxCodeLength;
  }

  void deleteItem(ScanItem item) {
    _items.removeWhere((i) => i.code.toUpperCase() == item.code.toUpperCase());
    _trashItems.add(item);
    _saveItems();
    _saveTrash();
    notifyListeners();
  }

  void restoreItem(ScanItem item) {
    _trashItems.removeWhere((i) => i.code.toUpperCase() == item.code.toUpperCase());
    _items.add(item);
    _saveItems();
    _saveTrash();
    notifyListeners();
  }

  void clearTrash() {
    _trashItems.clear();
    StorageService.clearTrash();
    notifyListeners();
  }

  void restoreAll() {
    for (final item in List.from(_trashItems)) {
      restoreItem(item);
    }
  }

  void resetPagination() {
    _currentPage = 1;
    _hasMoreData = true;
    notifyListeners();
  }

  Future<void> _saveItems() => StorageService.saveItems(_items);
  Future<void> _saveTrash() => StorageService.saveTrash(_trashItems);
}