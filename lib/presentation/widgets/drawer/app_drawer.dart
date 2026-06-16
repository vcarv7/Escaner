import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:escaner_1/core/utils/date_utils.dart' as app_date;
import 'package:escaner_1/data/services/excel_service.dart';
import 'package:escaner_1/data/services/filter_service.dart';
import 'package:escaner_1/presentation/providers/scan_provider.dart';
import 'package:escaner_1/presentation/providers/settings_provider.dart';
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
    final settings = context.read<SettingsProvider>();
    final filtro = settings.filtro;
    final itemsFiltrados = FilterService.aplicarFiltros(scanProvider.items, filtro);

    if (itemsFiltrados.isEmpty) {
      if (!mounted) return;
      OverlayMessage.warning(context, 'No hay Solapines para exportar');
      return;
    }

    _showLoadingDialog(context);

    final bytes = await ExcelService.generateExcelBytes(itemsFiltrados);

    if (!mounted) return;
    Navigator.of(context).pop();

    if (bytes == null) {
      OverlayMessage.error(context, 'Error al generar Excel');
      return;
    }

    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar Solapines',
      fileName: 'solapines_${app_date.DateUtils.getDateFileName()}.xlsx',
    );

    if (outputFile == null) return;

    final success = await ExcelService.saveExcel(bytes, outputFile);

    if (!mounted) return;
    if (success) {
      await Share.shareXFiles([XFile(outputFile)], text: 'Solapines exportados');
    } else {
      OverlayMessage.error(context, 'Error al guardar');
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Generando Excel...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: DrawerConstants.spacingSmall,
                ),
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
            title: 'Exportar',
            subtitle: 'Obtener Solapines en un Excel',
            onTap: _exportToExcel,
          ),
        ),
      ],
    );
  }
}
