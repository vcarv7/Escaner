class AppConstants {
  static const String appVersion = '0.8.7';

  /// Nombre de la app. Debe coincidir con `android:label` del manifest y con
  /// el título del login. Hay un test que verifica que no se desincronicen.
  static const String appName = 'SIGA';

  /// Avisos al operador cuando no hay Personas sincronizadas. Al operador no
  /// le corresponde la palabra "catálogo": solo necesita saber qué hacer.
  /// El escaneo queda bloqueado porque `processScan` interpretaría cualquier
  /// solapín como "Usuario Inactivo" contra una lista vacía.
  static const String sinPersonasMensaje = 'Sin Personas, sincroniza primero';

  /// Un único texto para los dos caminos que rechazan un solapín: la cámara
  /// (ScannerWidget) y el ingreso manual (HomePage). Antes cada uno tenía su
  /// propia redacción, lo que hacía que el mismo rechazo se anunciara de dos
  /// formas distintas.
  static const String solapinInvalidoMensaje = 'Solapín inválido';

  static const int minCodeLength = 5;
  static const int maxCodeLength = 15;
  static const int pageSize = 50;
  static const Duration scanCooldown = Duration(milliseconds: 2800);
}