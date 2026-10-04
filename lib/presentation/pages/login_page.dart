import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/persona_provider.dart';
import '../widgets/overlay/overlay_message.dart';
import '../../data/services/auth_token_storage.dart';
import '../../core/constants/app_constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  /// Token del login en vuelo. Vive en un campo, y no como variable local de
  /// `_handleLogin`, únicamente para que `dispose` pueda cancelarlo si el
  /// operador sale de la pantalla a mitad de la petición.
  CancelToken? _loginCancelToken;

  @override
  void initState() {
    super.initState();
    _prellenarUsuario();
  }

  /// Solo el usuario: no hay checkbox de sesión porque el almacenamiento seguro
  /// no sobrevive al arranque en frío, y ofrecer "Recordarme" sería prometer algo
  /// que la app no cumple. Guardar el nombre no promete nada y ahorra escribirlo.
  Future<void> _prellenarUsuario() async {
    final username = await AuthTokenStorage().getUsername();
    if (!mounted) return;
    if (username != null && username.isNotEmpty) {
      _usernameController.text = username;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _loginCancelToken?.cancel();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();

    // Un solo login en vuelo. Sin esto, el "done" del teclado dispara un segundo
    // _handleLogin que cancela el primero: el operador veía un toast rojo de
    // "Petición cancelada." junto al verde de "Bienvenido". El botón ya está
    // protegido con isLoading, pero el onFieldSubmitted del campo de contraseña
    // no lo estaba, y esta guarda es la que cubre los dos caminos.
    if (authProvider.isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    final cancelToken = CancelToken();
    _loginCancelToken = cancelToken;

    LoginResult result;
    try {
      result = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
        cancelToken: cancelToken,
      );
    } finally {
      // Solo se libera si el token sigue siendo el nuestro: el de un login
      // posterior tiene que sobrevivir a este finally.
      if (identical(_loginCancelToken, cancelToken)) {
        _loginCancelToken = null;
      }
      cancelToken.cancel();
    }

    if (!mounted) return;

    // Una cancelación no es un error del operador: no se le muestra nada.
    if (result.cancelled) return;

    if (result.success) {
      unawaited(context.read<PersonaProvider>().loadFromCache());
      OverlayMessage.success(
        context,
        'Bienvenido, ${_usernameController.text}',
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      OverlayMessage.error(context, result.error ?? 'Error al iniciar sesión');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(colorScheme),
                    const SizedBox(height: 32),
                    _buildForm(colorScheme),
                    const SizedBox(height: 24),
                    _buildLoginButton(colorScheme, authProvider),
                    const SizedBox(height: 24),
                    _buildFooter(colorScheme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            semanticLabel: 'SIGA',
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Inicia sesión para continuar',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _usernameController,
          focusNode: _usernameFocus,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Usuario',
            hintText: 'Ingresa tu usuario',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El usuario es requerido';
            }
            if (value.trim().length < 3) {
              return 'El usuario debe tener al menos 3 caracteres';
            }
            return null;
          },
          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            hintText: 'Ingresa tu contraseña',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La contraseña es requerida';
            }
            if (value.trim().length < 4) {
              return 'La contraseña debe tener al menos 4 caracteres';
            }
            return null;
          },
          onFieldSubmitted: (_) => _handleLogin(),
        ),
      ],
    );
  }

  Widget _buildLoginButton(ColorScheme colorScheme, AuthProvider authProvider) {
    return FilledButton.icon(
      onPressed: authProvider.isLoading ? null : _handleLogin,
      icon: authProvider.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.login_rounded),
      label: Text(
        authProvider.isLoading ? 'Iniciando sesión...' : 'Iniciar sesión',
      ),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    return Column(
      children: [
        Divider(color: colorScheme.outlineVariant),
        const SizedBox(height: 16),
        Text(
          'Versión ${AppConstants.appVersion}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          'Todos los Derechos Reservados UCI',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© 2026',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}