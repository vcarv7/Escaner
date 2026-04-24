import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart' as app_date;

class ScanItemColors {
  static const Color solapine = AppTheme.primary;
  static const Color tarjeta = Colors.blue;

  static const Color duplicate = Color(0xFFB71C1C);
  static const Color duplicateBackground = Color(0x33B71C1C);

  static Color getTypeColor(bool isSolapine) {
    return isSolapine ? solapine : tarjeta;
  }
}

class ScanItemConstants {
  static const String solapineLabel = 'S';
  static const String tarjetaLabel = 'T';

  static const String solapineName = 'Solapín';
  static const String tarjetaName = 'Tarjeta';
  static const String solapinesPlural = 'Solapines';
  static const String tarjetasPlural = 'Tarjetas';

  static const double cardMargin = 8.0;
  static const double avatarRadius = 20.0;

  static String formatDate(DateTime date) => app_date.DateUtils.formatDate(date);

  static String getCountText(int solapineCount, int tarjetaCount) {
    final solapinText = solapineCount == 1 ? solapineName : solapinesPlural;
    final tarjetaText = tarjetaCount == 1 ? tarjetaName : tarjetasPlural;

    if (solapineCount == 0 && tarjetaCount == 0) return 'Sin códigos';
    if (solapineCount == 0) return '$tarjetaCount $tarjetaText';
    if (tarjetaCount == 0) return '$solapineCount $solapinText';
    return '$solapineCount $solapinText y $tarjetaCount $tarjetaText';
  }
}