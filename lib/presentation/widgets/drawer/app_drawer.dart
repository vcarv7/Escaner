import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:escaner_1/data/services/excel_service.dart';
import 'package:escaner_1/presentation/providers/scan_provider.dart';
import 'package:escaner_1/presentation/widgets/overlay/overlay_message.dart';
import 'package:escaner_1/presentation/widgets/drawer/drawer_constants.dart';
import 'package:escaner_1/presentation/widgets/drawer/drawer_menu_item.dart';
import 'package:escaner_1/presentation/widgets/drawer/drawer_profile_section.dart';
import 'package:escaner_1/presentation/widgets/drawer/drawer_trash_section.dart';

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

  Future<void> _exportToExcel() async {
    if (!mounted) return;
    final scanProvider = context.read<ScanProvider>();
    final items = scanProvider.items;

    if (items.isEmpty) {
      if (!mounted) return;
      OverlayMessage.warning(context, 'No hay códigos para exportar');
      return;
    }

    final filePath = await ExcelService.exportToExcel(items);

    if (!mounted) return;
    if (filePath != null) {
      await Share.shareXFiles([XFile(filePath)], text: 'Códigos exportados');
      if (mounted) {
        OverlayMessage.success(context, 'Exportación completada');
      }
    } else {
      OverlayMessage.error(context, 'Error al exportar');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const DrawerProfileSection(
              userName: DrawerConstants.defaultUserName,
              userEmail: 'Invitado',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: DrawerConstants.spacingSmall),
                children: [
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

  Widget _buildDataSection(BuildContext context) {
    return Column(
      children: [
        Semantics(
          label: 'Exportar códigos a Excel',
          child: DrawerMenuItem(
            icon: Icons.file_download_outlined,
            title: 'Exportar Excel',
            subtitle: 'Guardar códigos en archivo',
            onTap: _exportToExcel,
          ),
        ),
      ],
    );
  }
}