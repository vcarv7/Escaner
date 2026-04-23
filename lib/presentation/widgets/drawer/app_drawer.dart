import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/services/excel_service.dart';
import '../../providers/scan_provider.dart';
import '../overlay/overlay_message.dart';
import 'drawer_constants.dart';
import 'drawer_menu_item.dart';
import 'drawer_profile_section.dart';
import 'drawer_trash_section.dart';

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
    final provider = context.read<ScanProvider>();
    final codes = await ExcelService.importFromExcel();

    if (codes.isEmpty) {
      if (!mounted) return;
      OverlayMessage.warning(context, 'No se encontraron códigos en el archivo');
      return;
    }

    provider.importCodes(codes);
    if (!mounted) return;
    OverlayMessage.success(context, '${codes.length} códigos importados');
  }

  Future<void> _exportToExcel() async {
    final provider = context.read<ScanProvider>();

    if (provider.items.isEmpty) {
      if (!mounted) return;
      OverlayMessage.warning(context, 'No hay códigos para exportar');
      return;
    }

    final filePath = await ExcelService.exportToExcel(provider.items);

    if (!mounted) return;

    if (filePath != null) {
      await Share.shareXFiles([XFile(filePath)], text: 'Códigos escaneados');
      if (!mounted) return;
      OverlayMessage.success(context, 'Excel preparado para exportar');
    } else {
      OverlayMessage.error(context, 'Error al generar Excel');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const DrawerProfileSection(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: DrawerConstants.spacingSmall),
                children: [
                  const Divider(),
                  DrawerMenuItem(
                    icon: Icons.login,
                    title: 'Iniciar Sesión',
                    subtitle: 'Gestiona tu cuenta',
                    onTap: () {},
                    isPrimary: true,
                  ),
                  const Divider(),
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
}