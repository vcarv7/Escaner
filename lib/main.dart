import 'dart:async';
import 'package:flutter/material.dart';
import 'core/constants/api_constants.dart';
import 'core/utils/app_logger.dart';
import 'data/services/tls/tls_trust.dart';
import 'app.dart';

Future<void> main() async {
  // runZonedGuarded envuelve TODO, incluido ensureInitialized: el await de
  // initPlatformTls() crea una zona nueva y Flutter exige que el binding y
  // runApp se inicialicen en la misma.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    initAppLogger();

    // El DNS de la red corporativa no resuelve el host del backend, asi que
    // se conecta contra la IP. El certificado se sigue validando contra el
    // hostname de baseUrl, que es lo que la CA corporativa puede avalar.
    setPlatformAddress(ApiConstants.previewAddress);

    // Antes de runApp: ApiClient es un singleton y captura el contexto TLS en
    // su constructor, asi que la CA tiene que estar cargada ya.
    await initPlatformTls();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exception}\n${details.stack}');
    };

    ErrorWidget.builder = (details) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Ocurrió un error inesperado.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    };

    runApp(const App());
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}
