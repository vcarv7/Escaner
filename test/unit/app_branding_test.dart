import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:escaner_1/core/constants/app_constants.dart';
import 'package:escaner_1/presentation/widgets/scanner/scanner_widget.dart';

/// Verifica el nombre de la app y los textos que ve el operador.
///
/// El manifest y el build.gradle no pueden usar constantes Dart, así que el
/// nombre de esos archivos se comprueba leyendo el disco. Así, si alguien
/// renombra la app en un lado y no en el otro, falla el test en vez de llegar
/// una APK con dos nombres distintos.
void main() {
  group('nombre de la app', () {
    test('la constante es solo SIGA', () {
      expect(AppConstants.appName, 'SIGA');
    });

    test('android:label del manifest coincide con appName', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml');
      expect(manifest.existsSync(), isTrue, reason: 'falta AndroidManifest.xml');

      final match = RegExp(r'android:label="([^"]+)"').firstMatch(manifest.readAsStringSync());
      expect(match, isNotNull, reason: 'el manifest no declara android:label');
      expect(match!.group(1), AppConstants.appName);
    });

    test('el nombre del APK se genera como SIGA-<buildType>', () {
      final gradle = File('android/app/build.gradle.kts');
      expect(gradle.existsSync(), isTrue, reason: 'falta build.gradle.kts');

      // r'' evita interpolar ${...} del test al construir el patrón.
      const patron = r'"SIGA-${buildType.name}.apk"';
      expect(gradle.readAsStringSync(), contains(patron));
    });
  });

  group('mensajes al operador sin la palabra catálogo', () {
    test('el aviso de falta de Personas no menciona catálogo', () {
      expect(AppConstants.sinPersonasMensaje, 'Sin Personas, sincroniza primero');
      expect(AppConstants.sinPersonasMensaje.toLowerCase(), isNot(contains('cat')));
    });

    testWidgets('el scanner bloqueado muestra el mensaje sin "catálogo"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ScannerWidget(
                onSolapineScanned: _ignorar,
                enabled: false,
                disabledMessage: AppConstants.sinPersonasMensaje,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(AppConstants.sinPersonasMensaje), findsOneWidget);
      expect(find.textContaining('cat'), findsNothing);
    });
  });
}

void _ignorar(String code) {}
