import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../../domain/entities/evento.dart';

enum ScanFeedback { none, sound, vibration }

enum TipoRangoFecha { unico, predefinido, personalizado }

enum RangoPredefinido { hoy, ayer, ultimos7, ultimos30, estaSemana, esteMes }

enum OrdenScaneados { ascendente, descendente }

// Sentinel que permite distinguir "no pasar este argumento" de "pasar null".
class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();

class FiltroData {
  final DateTime fecha;
  final TipoRangoFecha tipoRango;
  final RangoPredefinido predefinido;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final Evento? evento;

  FiltroData({
    required this.fecha,
    this.tipoRango = TipoRangoFecha.unico,
    this.predefinido = RangoPredefinido.hoy,
    this.fechaInicio,
    this.fechaFin,
    this.evento,
  });

  // El patrón sentinel permite poner evento/fechaInicio/fechaFin a null.
  // Usar `filtro.copyWith(evento: null)` ahora SÍ anula el campo.
  FiltroData copyWith({
    DateTime? fecha,
    TipoRangoFecha? tipoRango,
    RangoPredefinido? predefinido,
    Object? fechaInicio = _sentinel,
    Object? fechaFin = _sentinel,
    Object? evento = _sentinel,
  }) {
    return FiltroData(
      fecha: fecha ?? this.fecha,
      tipoRango: tipoRango ?? this.tipoRango,
      predefinido: predefinido ?? this.predefinido,
      fechaInicio: identical(fechaInicio, _sentinel)
          ? this.fechaInicio
          : fechaInicio as DateTime?,
      fechaFin: identical(fechaFin, _sentinel)
          ? this.fechaFin
          : fechaFin as DateTime?,
      evento: identical(evento, _sentinel) ? this.evento : evento as Evento?,
    );
  }

  String? get eventoNombre => evento?.displayName;

  bool get esDoble => evento?.isDoble ?? false;

  TipoRangoFecha get tipoRangoEffective => tipoRango;

  RangoPredefinido get predefinidoEffective => predefinido;

  bool fechaEnRango(DateTime fechaItem) {
    switch (tipoRangoEffective) {
      case TipoRangoFecha.unico:
        return fechaItem.year == fecha.year &&
            fechaItem.month == fecha.month &&
            fechaItem.day == fecha.day;
      case TipoRangoFecha.predefinido:
        return _fechaEnPredefinido(fechaItem);
      case TipoRangoFecha.personalizado:
        if (fechaInicio == null || fechaFin == null) return false;
        return !fechaItem.isBefore(fechaInicio!) && !fechaItem.isAfter(fechaFin!);
    }
  }

  bool _fechaEnPredefinido(DateTime fechaItem) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (predefinidoEffective) {
      case RangoPredefinido.hoy:
        return fechaItem.year == today.year &&
            fechaItem.month == today.month &&
            fechaItem.day == today.day;
      case RangoPredefinido.ayer:
        final yesterday = today.subtract(const Duration(days: 1));
        return fechaItem.year == yesterday.year &&
            fechaItem.month == yesterday.month &&
            fechaItem.day == yesterday.day;
      case RangoPredefinido.ultimos7:
        return !fechaItem.isBefore(today.subtract(const Duration(days: 7)));
      case RangoPredefinido.ultimos30:
        return !fechaItem.isBefore(today.subtract(const Duration(days: 30)));
      case RangoPredefinido.estaSemana:
        final inicioSemana = today.subtract(Duration(days: today.weekday - 1));
        return !fechaItem.isBefore(inicioSemana);
      case RangoPredefinido.esteMes:
        final inicioMes = DateTime(today.year, today.month, 1);
        return !fechaItem.isBefore(inicioMes);
    }
  }

  String get fechaDisplayText {
    switch (tipoRangoEffective) {
      case TipoRangoFecha.unico:
        return '${fecha.day}/${fecha.month}/${fecha.year}';
      case TipoRangoFecha.predefinido:
        return _getPredefinidoText();
      case TipoRangoFecha.personalizado:
        if (fechaInicio == null || fechaFin == null) return '';
        return '${fechaInicio!.day}/${fechaInicio!.month} - ${fechaFin!.day}/${fechaFin!.month}';
    }
  }

  String _getPredefinidoText() {
    switch (predefinidoEffective) {
      case RangoPredefinido.hoy:
        return 'Hoy';
      case RangoPredefinido.ayer:
        return 'Ayer';
      case RangoPredefinido.ultimos7:
        return 'Últimos 7 días';
      case RangoPredefinido.ultimos30:
        return 'Últimos 30 días';
      case RangoPredefinido.estaSemana:
        return 'Esta semana';
      case RangoPredefinido.esteMes:
        return 'Este mes';
    }
  }
}

class SettingsProvider extends ChangeNotifier {
  static const _keyDarkTheme = 'is_dark_theme';
  static const _keyScanFeedback = 'scan_feedback';
  static const _keyOrdenScaneados = 'orden_scaneados';

  bool _isDarkTheme = false;
  ScanFeedback _scanFeedback = ScanFeedback.none;
  FiltroData _filtro = FiltroData(fecha: DateTime.now());
  OrdenScaneados _ordenScaneados = OrdenScaneados.descendente;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool get isDarkTheme => _isDarkTheme;
  ScanFeedback get scanFeedback => _scanFeedback;
  FiltroData get filtro => _filtro;
  OrdenScaneados get ordenScaneados => _ordenScaneados;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkTheme = prefs.getBool(_keyDarkTheme) ?? false;
    final feedbackIndex = prefs.getInt(_keyScanFeedback) ?? 0;
    _scanFeedback = ScanFeedback.values[feedbackIndex.clamp(0, 2)];
    final ordenIndex = prefs.getInt(_keyOrdenScaneados) ?? 1;
    _ordenScaneados = OrdenScaneados.values[ordenIndex.clamp(0, 1)];
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

  void setFiltro(FiltroData filtro) {
    _filtro = filtro;
    notifyListeners();
  }

  Future<void> setOrdenScaneados(OrdenScaneados value) async {
    _ordenScaneados = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyOrdenScaneados, value.index);
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