import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/auto_delete_service.dart';
import '../../domain/entities/scan_record.dart';
import '../../domain/entities/evento.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validation_utils.dart';
import '../providers/persona_provider.dart';

class ScanProvider extends ChangeNotifier {
  List<ScanRecord> _records = [];
  List<ScanRecord> _trashRecords = [];
  bool _isLoading = true;
  bool _initialized = false;

  Timer? _autoDeleteTimer;
  final StreamController<AutoDeleteNotification> _notifController =
      StreamController<AutoDeleteNotification>.broadcast();

  List<ScanRecord> get records => List.unmodifiable(_records);
  List<ScanRecord> get trashRecords => List.unmodifiable(_trashRecords);
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
    _records = await StorageService.loadRecords();
    _trashRecords = await StorageService.loadTrash();
    _isLoading = false;
    AutoDeleteService.iniciar();
    _applyAutoDelete();
    _autoDeleteTimer =
        Timer.periodic(const Duration(hours: 1), (_) => _applyAutoDelete());
    notifyListeners();
  }

  void _applyAutoDelete() {
    final notif = AutoDeleteService.revisarScanRecords(_records, _trashRecords);
    if (notif.itemsMovidosAPapelera > 0 || notif.itemsEliminados > 0) {
      _records = notif.recordsRestantes;
      _trashRecords = notif.trashActualizada;
      _saveRecords();
      _saveTrash();
      _notifController.add(notif);
      notifyListeners();
    }
  }

  bool processScan(String code, Evento evento, String? puerta, PersonaProvider personaProvider) {
    final codeNormalized = code.toUpperCase();
    if (!_isValidCode(codeNormalized)) return false;

    final persona = personaProvider.findPersona(codeNormalized);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // CASO A: Verificar duplicado por código + evento + MISMA FECHA (día)
    final existingIndex = _records.indexWhere(
      (r) => r.code.toUpperCase() == codeNormalized &&
             r.eventos.any((e) => e.evento == evento &&
                 e.timestamp.isAfter(todayStart) && e.timestamp.isBefore(todayEnd))
    );

    if (existingIndex != -1) {
      final existing = _records[existingIndex];
      _records[existingIndex] = existing.copyWith(
        status: ScanStatus.denied,
        eventos: [...existing.eventos, EventoScan(
          evento: evento,
          timestamp: DateTime.now(),
          puerta: puerta,
        )],
      );
      _saveRecords();
      notifyListeners();
      return false;
    }

    // Buscar si el código ya existe (para agregar evento a record existente)
    final sameCodeIndex = _records.indexWhere(
      (r) => r.code.toUpperCase() == codeNormalized
    );

    if (sameCodeIndex != -1) {
      final existing = _records[sameCodeIndex];
      _records[sameCodeIndex] = existing.copyWith(
        eventos: [...existing.eventos, EventoScan(
          evento: evento,
          timestamp: DateTime.now(),
          puerta: puerta,
        )],
      );
      _saveRecords();
      notifyListeners();
      return true;
    }

    // CASO C: Código nuevo - determinar status
    ScanStatus status;
    if (persona != null) {
      status = ScanStatus.reserved;
    } else {
      status = ScanStatus.inactive; // CASO C: solapín inactivo
    }

    _records.add(ScanRecord(
      id: const Uuid().v4(),
      code: codeNormalized,
      type: ValidationUtils.detectType(codeNormalized),
      scannedAt: DateTime.now(),
      personaId: persona?.idPersona,
      personaSolapine: persona?.solapin,
      personaNombre: persona?.nombreCompleto,
      categoriaResidente: persona?.categoriaResidente ?? 1,
      eventos: [EventoScan(evento: evento, timestamp: DateTime.now(), puerta: puerta)],
      status: status,
    ));
    _saveRecords();
    notifyListeners();
    return true;
  }

  bool _isValidCode(String code) {
    if (code.isEmpty) return false;
    final length = code.length;
    return length >= AppConstants.minCodeLength && length <= AppConstants.maxCodeLength;
  }

  void deleteRecord(ScanRecord record) {
    _records.removeWhere((r) => r.id == record.id);
    _trashRecords.add(record);
    _saveRecords();
    _saveTrash();
    notifyListeners();
  }

  void restoreRecord(ScanRecord record) {
    _trashRecords.removeWhere((r) => r.id == record.id);
    final existingIdx = _records.indexWhere((r) => r.id == record.id);
    if (existingIdx != -1) {
      _records[existingIdx] = record;
    } else {
      _records.add(record);
    }
    _saveRecords();
    _saveTrash();
    notifyListeners();
  }

  void clearTrash() {
    _trashRecords.clear();
    StorageService.clearTrash();
    notifyListeners();
  }

  void restoreAll() {
    for (final record in List.from(_trashRecords)) {
      _trashRecords.removeWhere((r) => r.id == record.id);
      final existingIdx = _records.indexWhere((r) => r.id == record.id);
      if (existingIdx != -1) {
        _records[existingIdx] = record;
      } else {
        _records.add(record);
      }
    }
    _saveRecords();
    _saveTrash();
    notifyListeners();
  }

  Future<void> _saveRecords() => StorageService.saveRecords(_records);
  Future<void> _saveTrash() => StorageService.saveTrash(_trashRecords);
}