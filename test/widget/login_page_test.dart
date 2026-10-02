import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:escaner_1/presentation/pages/login_page.dart';
import 'package:escaner_1/presentation/providers/auth_provider.dart';

/// AuthProvider controlable: cuenta los intentos y deja el resultado pendiente
/// hasta que el test lo complete, para poder simular un login en vuelo.
class ControllableAuthProvider implements AuthProvider {
  ControllableAuthProvider(this._result);

  LoginResult _result;
  final Completer<LoginResult> _completer = Completer<LoginResult>();

  int loginCalls = 0;
  bool _isLoading = false;

  @override
  bool get isLoading => _isLoading;

  @override
  Future<LoginResult> login(
    String username,
    String password, {
    CancelToken? cancelToken,
  }) async {
    loginCalls++;
    _isLoading = true;
    return _completer.future;
  }

  void completeWith(LoginResult result) => _result = result;
  void complete() => _completer.complete(_result);

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void dispose() {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ControllableAuthProvider provider;

  Future<void> pumpLogin(WidgetTester tester) async {
    provider = ControllableAuthProvider(const LoginResult.success());
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: provider,
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pump();
  }

  Future<void> fillCredentialsAndSubmit(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).first, 'usuario');
    await tester.enterText(find.byType(TextFormField).last, 'clave123');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

/// Cuenta los toasts de OverlayMessage.
///
/// No se puede leer `OverlayState._entries` (es privado) y `SlideTransition`
/// tampoco sirve porque las transiciones de página de MaterialApp lo usan.
/// Lo distintivo del toast es su `Text`: 18px, bold y blanco. Ningún otro texto
/// de la pantalla de login combina las tres cosas.
int toastCount(WidgetTester tester) => tester
    .widgetList<Text>(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.style?.fontSize == 18 &&
            w.style?.fontWeight == FontWeight.w600 &&
            w.style?.color == Colors.white,
      ),
    )
    .length;

  group('LoginPage: un solo intento en vuelo', () {
    testWidgets(
      'un segundo toque no dispara otro login',
      (tester) async {
        // El operador que impacienta toca dos veces. El botón queda con
        // onPressed activo porque el provider de prueba no notifica, así que
        // esta prueba ejercita justamente la guarda interna de _handleLogin y
        // no el onPressed deshabilitado.
        await pumpLogin(tester);
        await tester.enterText(find.byType(TextFormField).first, 'usuario');
        await tester.enterText(find.byType(TextFormField).last, 'clave123');
        await tester.pump();

        final boton = find.widgetWithText(FilledButton, 'Iniciar sesión');
        await tester.tap(boton);
        await tester.pump();

        expect(provider.loginCalls, 1);
        expect(provider.isLoading, isTrue);

        await tester.tap(boton);
        await tester.pump();

        expect(provider.loginCalls, 1);
      },
    );

    testWidgets('no se inserta ningún toast mientras el login está en vuelo',
        (tester) async {
      await pumpLogin(tester);
      await fillCredentialsAndSubmit(tester);

      expect(toastCount(tester), 0);
    });
  });

  group('LoginPage: resultado del intento', () {
    testWidgets('un fallo muestra exactamente su propio mensaje',
        (tester) async {
      provider = ControllableAuthProvider(
        const LoginResult.failure(
          'No se puede conectar con el servidor. Verifica la red o contacta a soporte.',
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: provider,
          child: const MaterialApp(home: LoginPage()),
        ),
      );
      await tester.pump();
      await fillCredentialsAndSubmit(tester);
      provider.complete();
      await tester.pump();

      expect(toastCount(tester), 1);
      expect(
        find.text(
          'No se puede conectar con el servidor. Verifica la red o contacta a soporte.',
        ),
        findsOneWidget,
      );
      expect(find.text('Usuario o contraseña incorrectos'), findsNothing);

      // Deja expirar el autoclose de 3s: si el timer queda pendiente, el
      // runner falla el test aunque todas las aserciones hayan pasado.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(toastCount(tester), 0);
    });

    testWidgets('una cancelación no muestra ningún toast', (tester) async {
      provider = ControllableAuthProvider(const LoginResult.cancelled());
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: provider,
          child: const MaterialApp(home: LoginPage()),
        ),
      );
      await tester.pump();
      await fillCredentialsAndSubmit(tester);
      provider.complete();
      await tester.pump();

      expect(toastCount(tester), 0);
      expect(find.text('Petición cancelada.'), findsNothing);
    });
  });
}