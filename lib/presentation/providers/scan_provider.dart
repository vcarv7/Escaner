import 'package:flutter/foundation.dart';
import '../../data/services/storage_service.dart';
import '../../domain/entities/scan_item.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validation_utils.dart';

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
    notifyListeners();
  }

  List<ScanItem> getItemsPage(int page) {
    final start = (page - 1) * AppConstants.pageSize;
    final end = start + AppConstants.pageSize;
    if (start >= _items.length) return [];
    return _items.sublist(start, end.clamp(0, _items.length));
  }

  void addItem(String code) {
    if (!ValidationUtils.isValidCode(code)) return;
    final type = ValidationUtils.detectType(code);
    final existingIndex = _items.indexWhere((s) => s.code == code);
    if (existingIndex != -1) {
      _items[existingIndex] = _items[existingIndex].copyWith(isDuplicate: true);
    } else {
      _items.add(ScanItem(
        code: code,
        type: type,
        isDuplicate: false,
        scannedAt: DateTime.now(),
      ));
    }
    _hasMoreData = _currentPage * AppConstants.pageSize < _items.length;
    _saveItems();
    notifyListeners();
  }

  void deleteItem(ScanItem item) {
    _items.removeWhere((i) => i.code == item.code);
    _trashItems.add(item);
    _saveItems();
    _saveTrash();
    notifyListeners();
  }

  void restoreItem(ScanItem item) {
    _trashItems.removeWhere((i) => i.code == item.code);
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

  void clearAll() {
    _trashItems.addAll(_items);
    _items.clear();
    _currentPage = 1;
    _hasMoreData = true;
    _saveItems();
    _saveTrash();
    notifyListeners();
  }

  void importCodes(List<String> codes) {
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
    _hasMoreData = _currentPage * AppConstants.pageSize < _items.length;
    _saveItems();
    notifyListeners();
  }

  void resetPagination() {
    _currentPage = 1;
    _hasMoreData = true;
    notifyListeners();
  }

  Future<void> _saveItems() => StorageService.saveItems(_items);
  Future<void> _saveTrash() => StorageService.saveTrash(_trashItems);
}