import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:escaner_1/data/services/excel_service.dart';
import 'package:escaner_1/presentation/providers/auth_provider.dart';
import 'package:escaner_1/presentation/widgets/overlay/overlay_message.dart';
import 'package:escaner_1/presentation/widgets/drawer/drawer_constants.dart';
import 'package:escaner_1/presentation/widgets/drawer/drawer_menu_item.dart';
import 'package:escaner_1/presentation/widgets/drawer/drawer_profile_section.dart';
import 'package:escaner_1/presentation/widgets/drawer/drawer_trash_section.dart';
import 'package:escaner_1/presentation/pages/login_page.dart';
import 'package:escaner_1/presentation/pages/admin_panel_page.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DrawerConstants.drawerAnimation,
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _importFromExcel() async {
    final provider = context.read<AuthProvider>();
    if (!provider.isAuthenticated) {
      OverlayMessage.warning(context, 'Debes iniciar sesión para importar');
      return;
    }
    final codes = await ExcelService.importFromExcel();

    if (codes.isEmpty) {
      if (!mounted) return;
      OverlayMessage.warning(context, 'No se encontraron códigos en el archivo');
      return;
    }

    if (!mounted) return;
    OverlayMessage.success(context, '${codes.length} códigos importados');
  }

  Future<void> _exportToExcel() async {
    if (!mounted) return;
    OverlayMessage.warning(context, 'Primero escanea códigos');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.currentUser;
                return DrawerProfileSection(
                  userName: user?.username ?? DrawerConstants.defaultUserName,
                  userEmail: user?.isAdmin == true 
                      ? 'Administrador' 
                      : 'Usuario',
                  isAuthenticated: authProvider.isAuthenticated,
                );
              },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: DrawerConstants.spacingSmall),
                children: [
                  const Divider(),
                  _buildAuthSection(context),
                  const Divider(),
                  _buildDataSection(context),
                  const Divider(),
                  const DrawerTrashSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isAuthenticated) {
          return Column(
            children: [
              DrawerMenuItem(
                icon: Icons.admin_panel_settings,
                title: 'Administración',
                subtitle: 'Gestionar usuarios',
                onTap: () {
                  if (!authProvider.isAdmin) {
                    OverlayMessage.warning(context, 'No tienes permisos de admin');
                    return;
                  }
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                  );
                },
                isPrimary: authProvider.isAdmin,
              ),
              DrawerMenuItem(
                icon: Icons.logout,
                title: 'Cerrar Sesión',
                subtitle: authProvider.currentUser?.username ?? 'Usuario',
                onTap: () async {
                  await authProvider.logout();
                  if (!mounted) return;
                  OverlayMessage.success(context, 'Sesión cerrada');
                },
                isPrimary: true,
              ),
            ],
          );
        }

        return DrawerMenuItem(
          icon: Icons.login,
          title: 'Iniciar Sesión',
          subtitle: 'Acceder a la aplicación',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
          isPrimary: true,
        );
      },
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return Column(
      children: [
        DrawerMenuItem(
          icon: Icons.file_upload_outlined,
          title: 'Importar Excel',
          subtitle: 'Cargar códigos desde archivo',
          onTap: _importFromExcel,
        ),
        DrawerMenuItem(
          icon: Icons.file_download_outlined,
          title: 'Exportar Excel',
          subtitle: 'Guardar códigos en archivo',
          onTap: _exportToExcel,
        ),
      ],
    );
  }
}