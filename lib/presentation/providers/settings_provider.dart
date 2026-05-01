import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

enum ScanFeedback { none, sound, vibration }

class FiltroData {
  final DateTime fecha;
  final dynamic evento;

  FiltroData({required this.fecha, this.evento});

  FiltroData copyWith({DateTime? fecha, dynamic evento}) {
    return FiltroData(
      fecha: fecha ?? this.fecha,
      evento: evento ?? this.evento,
    );
  }

  String? get eventoNombre {
    if (evento == null) return null;
    return evento.displayName as String?;
  }

  bool get esDoble {
    if (evento == null) return false;
    return evento.isDoble as bool;
  }
}

class SettingsProvider extends ChangeNotifier {
  static const _keyDarkTheme = 'is_dark_theme';
  static const _keyScanFeedback = 'scan_feedback';
  static const _keyCsvUrl = 'csv_url';

  bool _isDarkTheme = false;
  ScanFeedback _scanFeedback = ScanFeedback.none;
  String _csvUrl = '';
  FiltroData _filtro = FiltroData(fecha: DateTime.now(), evento: null);
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool get isDarkTheme => _isDarkTheme;
  ScanFeedback get scanFeedback => _scanFeedback;
  String get csvUrl => _csvUrl;
  FiltroData get filtro => _filtro;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkTheme = prefs.getBool(_keyDarkTheme) ?? false;
    final feedbackIndex = prefs.getInt(_keyScanFeedback) ?? 0;
    _scanFeedback = ScanFeedback.values[feedbackIndex.clamp(0, 2)];
    _csvUrl = prefs.getString(_keyCsvUrl) ?? '';
    notifyListeners();
  }

  Future<void> setDarkTheme(bool value) async {
    _isDarkTheme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkTheme, value);
    notifyListeners();
  }

  Future<void> setScanFeedback(ScanFeedback value) async {
    _scanFeedback = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyScanFeedback, value.index);
    notifyListeners();
  }

  Future<void> setCsvUrl(String url) async {
    _csvUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCsvUrl, url);
    notifyListeners();
  }

  void setFiltro(FiltroData filtro) {
    _filtro = filtro;
    notifyListeners();
  }

  Future<void> triggerScanFeedback() async {
    switch (_scanFeedback) {
      case ScanFeedback.sound:
        await _audioPlayer.play(AssetSource('sounds/scan_sound.mp3'));
        break;
      case ScanFeedback.vibration:
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator) {
          await Vibration.vibrate(duration: 100);
        }
        break;
      case ScanFeedback.none:
        break;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}