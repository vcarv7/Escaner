import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
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

class _AppDrawerState extends State<AppDrawer> {
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

    // Guardar en un directorio escribible por la app (no content:// de SAF),
    // y luego compartir con share_plus (Android 11+ no acepta File sobre
    // URIs devueltas por FilePicker.saveFile).
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'solapines_${app_date.DateUtils.getDateFileName()}.xlsx';
    final filePath = '${dir.path}/$fileName';

    final success = await ExcelService.saveExcel(bytes, filePath);

    if (!mounted) return;
    if (success) {
      await Share.shareXFiles([XFile(filePath)], text: 'Solapines exportados');
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
            const DrawerProfileSection(),
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
