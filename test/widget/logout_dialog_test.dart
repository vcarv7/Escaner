import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:escaner_1/presentation/widgets/dialogs/logout_dialog.dart';

void main() {
  group('LogoutDialog', () {
    testWidgets('muestra el título y la pregunta de confirmación', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => LogoutDialog.show(context, onConfirm: () {}),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('logout_dialog')), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsNWidgets(2));
      expect(find.text('¿Estás seguro de que quieres cerrar sesión?'), findsOneWidget);
    });

    testWidgets('Cancelar NO dispara onConfirm', (WidgetTester tester) async {
      var confirmed = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => LogoutDialog.show(context, onConfirm: () => confirmed++),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('logout_dialog_cancel')));
      await tester.pumpAndSettle();

      expect(confirmed, 0);
      expect(find.byKey(const ValueKey('logout_dialog')), findsNothing);
    });

    testWidgets('Confirmar dispara onConfirm una vez y cierra el diálogo', (WidgetTester tester) async {
      var confirmed = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => LogoutDialog.show(context, onConfirm: () => confirmed++),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('logout_dialog_confirm')));
      await tester.pumpAndSettle();

      expect(confirmed, 1);
      expect(find.byKey(const ValueKey('logout_dialog')), findsNothing);
    });

    testWidgets('no desborda con textScale 2.0', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => LogoutDialog.show(context, onConfirm: () {}),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('logout_dialog')), findsOneWidget);
    });
  });
}
