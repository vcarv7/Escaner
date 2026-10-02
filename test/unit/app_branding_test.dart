import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:escaner_1/core/constants/app_constants.dart';
import 'package:escaner_1/presentation/pages/login_page.dart';
import 'package:escaner_1/presentation/providers/auth_provider.dart';
import 'package:escaner_1/presentation/widgets/scanner/scanner_widget.dart';

/// Stub mínimo: LoginPage solo lee `isLoading` al construir. `Mock` no sirve
/// porque `noSuchMethod` devuelve null y `isLoading` es bool no-nullable.
class FakeAuthProvider implements AuthProvider {
  @override
  bool get isLoading => false;

  @override
  bool get isAuthenticated => false;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void dispose() {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

    testWidgets('el título del login usa appName', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: FakeAuthProvider(),
          child: const MaterialApp(home: LoginPage()),
        ),
      );
      await tester.pump();

      expect(find.text(AppConstants.appName), findsOneWidget);
    });
  });

  group('versión de la app', () {
    test('appVersion coincide con la versión de pubspec.yaml', () {
      final pubspec = File('pubspec.yaml');
      expect(pubspec.existsSync(), isTrue, reason: 'falta pubspec.yaml');

      final match = RegExp(
        r'^version:\s*(\S+)',
        multiLine: true,
      ).firstMatch(pubspec.readAsStringSync());
      expect(match, isNotNull, reason: 'pubspec.yaml no declara version:');

      // pubspec usa `0.8.5+1`: nombre antes del `+`, build después. El nombre
      // es lo que Android reporta como versionName y lo que se muestra al
      // operador, así que es lo que debe estar en la constante.
      final nombre = match!.group(1)!.split('+').first;
      expect(AppConstants.appVersion, nombre);
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
