import 'dart:async';
import 'package:flutter/material.dart';
import 'core/utils/app_logger.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  initAppLogger();

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

  runZonedGuarded(
    () => runApp(const App()),
    (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
    },
  );
}
