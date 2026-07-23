import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/auto_delete_service.dart';
import '../../domain/entities/scan_item.dart';
import '../../domain/entities/evento.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validation_utils.dart';
import '../providers/persona_provider.dart';

class ScanProvider extends ChangeNotifier {
  List<ScanItem> _items = [];
  List<ScanItem> _trashItems = [];
  bool _isLoading = true;
  bool _initialized = false;

  Timer? _autoDeleteTimer;
  final StreamController<AutoDeleteNotification> _notifController =
      StreamController<AutoDeleteNotification>.broadcast();

  List<ScanItem> get items => List.unmodifiable(_items);
  List<ScanItem> get trashItems => List.unmodifiable(_trashItems);
  bool get isLoading => _isLoading;

  Stream<AutoDeleteNotification> get autoDeleteNotifications =>
      _notifController.stream;

  @override
  void dispose() {
    _autoDeleteTimer?.cancel();
    AutoDeleteService.detener();
    _notifController.close();
    super.dispose();
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _items = await StorageService.loadItems();
    _trashItems = await StorageService.loadTrash();
    _isLoading = false;
    AutoDeleteService.iniciar();
    _applyAutoDelete();
    _autoDeleteTimer =
        Timer.periodic(const Duration(hours: 1), (_) => _applyAutoDelete());
    notifyListeners();
  }

  void _applyAutoDelete() {
    final notif = AutoDeleteService.revisar(_items, _trashItems);
    if (notif.itemsMovidosAPapelera > 0 || notif.itemsEliminados > 0) {
      _items = notif.itemsRestantes;
      _trashItems = notif.trashActualizada;
      _saveItems();
      _saveTrash();
      _notifController.add(notif);
      notifyListeners();
    }
  }

  bool addItem(String code, Evento evento, PersonaProvider personaProvider) {
    return addItemFromScanner(code, evento, personaProvider);
  }

  bool addItemFromScanner(String code, Evento evento, PersonaProvider personaProvider) {
    final codeNormalized = code.toUpperCase();
    if (!_isValidCode(codeNormalized)) return false;

    final existingIndex = _items.indexWhere((s) => s.code.toUpperCase() == codeNormalized);
    final persona = personaProvider.findPersona(codeNormalized);

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
      type: ValidationUtils.detectType(codeNormalized),
      isDuplicate: false,
      scannedAt: DateTime.now(),
      evento: evento,
      personaSolapine: persona?.solapin,
      personaNombre: persona?.nombreCompleto,
      status: status,
    ));
    _saveItems();
    notifyListeners();
    return true;
  }

  bool addItemManual(String code, Evento evento, PersonaProvider personaProvider) {
    final codeNormalized = code.toUpperCase();
    if (!_isValidCode(codeNormalized)) return false;

    final existingIndex = _items.indexWhere((s) => s.code.toUpperCase() == codeNormalized);
    final persona = personaProvider.findPersona(codeNormalized);

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
      type: ValidationUtils.detectType(codeNormalized),
      isDuplicate: false,
      scannedAt: DateTime.now(),
      evento: evento,
      personaSolapine: persona?.solapin,
      personaNombre: persona?.nombreCompleto,
      status: status,
    ));
    _saveItems();
    notifyListeners();
    return true;
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
    final existingIdx = _items.indexWhere((i) => i.code.toUpperCase() == item.code.toUpperCase());
    if (existingIdx != -1) {
      _items[existingIdx] = item;
    } else {
      _items.add(item);
    }
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
      _trashItems.removeWhere((i) => i.code.toUpperCase() == item.code.toUpperCase());
      final existingIdx = _items.indexWhere((i) => i.code.toUpperCase() == item.code.toUpperCase());
      if (existingIdx != -1) {
        _items[existingIdx] = item;
      } else {
        _items.add(item);
      }
    }
    _saveItems();
    _saveTrash();
    notifyListeners();
  }

  Future<void> _saveItems() => StorageService.saveItems(_items);
  Future<void> _saveTrash() => StorageService.saveTrash(_trashItems);
}