import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validation_utils.dart';
import '../../data/services/auto_delete_service.dart';
import '../../data/services/session_events.dart';
import '../../domain/entities/scan_record.dart';
import '../providers/scan_provider.dart';
import '../providers/evento_provider.dart';
import '../providers/persona_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/puerta_provider.dart';
import '../widgets/scanner/scanner_widget.dart';
import '../widgets/solapines_list.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_nav_bar.dart';
import '../widgets/dialogs/add_manual_dialog.dart';
import '../widgets/dialogs/puerta_selector_dialog.dart';
import '../widgets/drawer/app_drawer.dart';
import '../widgets/overlay/overlay_message.dart';
import '../widgets/common/math_curve_loader.dart';
import 'settings_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<AutoDeleteNotification>? _cleanupSubscription;
  StreamSubscription<void>? _sessionExpiredSubscription;
  AuthProvider? _authProvider;
  bool _sesionExpirada = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanProvider>().init();
      _escucharLimpieza();
      _escucharSesion();
      _authProvider = context.read<AuthProvider>()..addListener(_onAuthChanged);
    });
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    _cleanupSubscription?.cancel();
    _sessionExpiredSubscription?.cancel();
    super.dispose();
  }

  /// Al volver a iniciar sesión desaparece el aviso de sesión expirada: la app
  /// ya puede sincronizar otra vez.
  void _onAuthChanged() {
    if (!mounted) return;
    if (_authProvider?.isAuthenticated == true && _sesionExpirada) {
      setState(() => _sesionExpirada = false);
    }
  }

  void _escucharLimpieza() {
    _cleanupSubscription = context.read<ScanProvider>().autoDeleteNotifications.listen((notif) {
      if (!mounted) return;
      final partes = <String>[];
      if (notif.itemsMovidosAPapelera > 0) {
        partes.add('${notif.itemsMovidosAPapelera} a la papelera');
      }
      if (notif.itemsEliminados > 0) {
        partes.add('${notif.itemsEliminados} eliminados');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Limpieza automática: ${partes.join(', ')}',
            child: Text('🧹 ${partes.join(', ')}'),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  void _escucharSesion() {
    _sessionExpiredSubscription = SessionEvents.instance.onExpired.listen((_) {
      if (!mounted) return;
      // NO se llama a PersonaProvider.clearSession() aquí a propósito.
      //
      // El interceptor ya limpió los tokens, así que el usuario no puede
      // sincronizar. Pero la lista de personas es un dataset del DISPOSITIVO,
      // no de la sesión: borrarla en memoria dejaba al usuario escaneando contra
      // un índice vacío, lo que marca a todos como "Usuario Inactivo" y obliga a
      // volver a iniciar sesión por red para recuperar el escaneo. Con la sesión
      // expirada y sin conectividad, el escaneo quedaba muerto hasta reiniciar.
      setState(() => _sesionExpirada = true);
      OverlayMessage.warning(
        context,
        'Sesión expirada. Puedes seguir escaneando; inicia sesión para sincronizar.',
      );
    });
  }

  /// El escaneo necesita el catálogo local. Con la lista vacía, `processScan`
  /// marca cada solapín como inactivo, así que se corta antes de registrar nada.
  bool _guardarCatalogoDisponible() {
    final personaProvider = context.read<PersonaProvider>();
    if (personaProvider.puedeEscanear) return true;
    OverlayMessage.error(context, AppConstants.sinPersonasMensaje);
    return false;
  }

  void _onItemScanned(String code) => _registrarScan(code);

  /// Compartido por el escáner y la entrada manual: catálogo → evento → puerta →
  /// validación → registro → feedback. Antes esto estaba duplicado en dos
  /// métodos casi idénticos que solo divergían en el origen del código.
  Future<void> _registrarScan(String code) async {
    if (!_guardarCatalogoDisponible()) return;

    final eventoProvider = context.read<EventoProvider>();

    if (!eventoProvider.tieneEventoSeleccionado) {
      eventoProvider.autoSeleccionarEvento();
    }

    if (!eventoProvider.tieneEventoSeleccionado) {
      if (!mounted) return;
      OverlayMessage.error(context, 'Selecciona un evento');
      return;
    }

    final puertaProvider = context.read<PuertaProvider>();
    String? puerta;

    if (puertaProvider.tienePuertaSeleccionada) {
      puerta = puertaProvider.puertaSeleccionada;
    } else {
      puerta = await PuertaSelectorDialog.show(context);
      if (puerta == null) return;
      if (!mounted) return;
      puertaProvider.seleccionarPuerta(puerta);
    }

    final personaProvider = context.read<PersonaProvider>();
    final provider = context.read<ScanProvider>();

    if (!ValidationUtils.isValidCode(code)) {
      if (!mounted) return;
      OverlayMessage.error(context, 'Solapín inválido');
      return;
    }

    final isNew = provider.processScan(
      code,
      eventoProvider.eventoActual!,
      puerta,
      personaProvider,
    );

    _showScanFeedback(code, isNew, provider);
  }

  void _showScanFeedback(String code, bool isNew, ScanProvider provider) {
    if (!mounted) return;

    // processScan siempre deja el registro del código recién escaneado, así que
    // se resuelve por código. Usar `records.last` mostraba el nombre de OTRA
    // persona cuando el solapín ya existía (los registros no se reordenan).
    final item = provider.records.firstWhere(
      (r) => r.code.toUpperCase() == code.toUpperCase(),
    );

    if (isNew) {
      context.read<SettingsProvider>().triggerScanFeedback();
      if (item.status == ScanStatus.reserved) {
        final categoria = item.categoriaResidente == 1 ? 'Interno' : 'Externo';
        OverlayMessage.success(context, '${item.personaNombre} - $categoria');
      } else if (item.status == ScanStatus.inactive) {
        OverlayMessage.warning(context, 'Usuario Inactivo');
      } else {
        OverlayMessage.warning(context, 'No encontrado en lista');
      }
    } else {
      if (item.status == ScanStatus.denied) {
        OverlayMessage.error(context, 'Acceso Denegado');
      } else {
        OverlayMessage.error(context, 'Duplicado');
      }
    }
  }

  void _showAddManualDialog() => AddManualDialog.show(context, _registrarScan);

  /// Banner crítico: sin catálogo el escaneo está bloqueado, porque
  /// `processScan` interpretaría cualquier solapín como "Usuario Inactivo".
  Widget _buildCatalogoBanner(PersonaProvider personaProvider) {
    final status = personaProvider.status;
    if (status == PersonaListStatus.lista || status == PersonaListStatus.cargando) {
      return const SizedBox.shrink();
    }

    final esError = status == PersonaListStatus.error;
    final mensaje = esError
        ? (personaProvider.error ?? 'No se pudieron cargar las Personas')
        : AppConstants.sinPersonasMensaje;
    final semantica = esError
        ? 'Error al cargar las Personas: $mensaje'
        : 'Escaneo bloqueado: no hay Personas sincronizadas';

    return Container(
      key: const ValueKey('banner_catalogo'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      color: esError ? Colors.red.shade100 : Colors.orange.shade100,
      child: Semantics(
        label: semantica,
        child: Row(
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.person_off_outlined,
              color: esError ? Colors.red.shade900 : Colors.orange.shade900,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(
                  color: esError ? Colors.red.shade900 : Colors.orange.shade900,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              key: const ValueKey('banner_catalogo_cta'),
              onPressed: _abrirSincronizacion,
              child: const Text('Sincronizar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Aviso informativo: la sesión expirada ya NO bloquea el escaneo, solo la
  /// sincronización. Sin este texto el operador pensaría que la app está rota.
  Widget _buildSesionExpiradaBanner() {
    return Container(
      key: const ValueKey('banner_sesion_expirada'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      color: Colors.blue.shade50,
      child: Semantics(
        label: 'Sesión expirada. El escaneo sigue funcionando, pero no puedes sincronizar.',
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, color: Colors.blueGrey, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Sesión expirada. Escaneo disponible; sincronización bloqueada.',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              key: const ValueKey('banner_sesion_expirada_cta'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }

  /// El CTA lleva a donde se puede resolver: si no hay sesión, al login; si la
  /// hay, al tab de Ajustes que contiene el botón de sincronizar.
  void _abrirSincronizacion() {
    if (context.read<AuthProvider>().isAuthenticated) {
      setState(() => _selectedIndex = 1);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isLargeScreen = screenWidth > 600;

        return Consumer<ScanProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return Scaffold(
                body: Center(
                  child: MathCurveLoader.epicycloid(
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            }

            final personaProvider = context.watch<PersonaProvider>();
            final isCacheStale = personaProvider.isCacheStale && personaProvider.hasPersonas;

            return Scaffold(
              key: _scaffoldKey,
              appBar: HomeAppBar(
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                showActions: _selectedIndex == 0,
              ),
              drawer: const AppDrawer(),
              body: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: _selectedIndex == 0
                        ? Column(
                            key: const ValueKey(0),
                            children: [
                              _buildCatalogoBanner(personaProvider),
                              if (_sesionExpirada) _buildSesionExpiradaBanner(),
                              if (isCacheStale)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  color: Colors.orange.shade100,
                                  child: Semantics(
                                    label: 'Datos en caché pueden estar desactualizados',
                                    child: Text(
                                      'Datos en caché pueden estar desactualizados',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isLargeScreen ? 32 : screenWidth * 0.03,
                                  vertical: 8,
                                ),
                                child: ScannerWidget(
                                  onSolapineScanned: _onItemScanned,
                                  enabled: personaProvider.puedeEscanear,
                                  disabledMessage: AppConstants.sinPersonasMensaje,
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: isLargeScreen ? 800 : double.infinity,
                                    ),
                                    child: SolapinesList(provider: provider),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SettingsPage(key: ValueKey(1)),
                  ),
                ],
              ),
              floatingActionButton: _selectedIndex == 0
                  ? Semantics(
                      label: 'Agregar Solapín manualmente',
                      child: FloatingActionButton(
                        key: const ValueKey('fab_add'),
                        onPressed: _showAddManualDialog,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        child: const Icon(Icons.add),
                      ),
                    )
                  : null,
              bottomNavigationBar: HomeNavBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              ),
            );
          },
        );
      },
    );
  }
}