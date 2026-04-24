import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

enum ScanFeedback { none, sound, vibration }

class SettingsProvider extends ChangeNotifier {
  static const _keyDarkTheme = 'is_dark_theme';
  static const _keyScanFeedback = 'scan_feedback';

  bool _isDarkTheme = false;
  ScanFeedback _scanFeedback = ScanFeedback.none;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool get isDarkTheme => _isDarkTheme;
  ScanFeedback get scanFeedback => _scanFeedback;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkTheme = prefs.getBool(_keyDarkTheme) ?? false;
    final feedbackIndex = prefs.getInt(_keyScanFeedback) ?? 0;
    _scanFeedback = ScanFeedback.values[feedbackIndex.clamp(0, 2)];
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