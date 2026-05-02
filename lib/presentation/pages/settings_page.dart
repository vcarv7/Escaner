import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../providers/settings_provider.dart';
import '../providers/csv_provider.dart';
import '../widgets/overlay/overlay_message.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  String _getVersion() {
    return AppConstants.appVersion;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Consumer2<SettingsProvider, CsvProvider>(
        builder: (context, settings, csvProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('DATOS', colorScheme),
              const SizedBox(height: 8),
              _buildCsvUrlCard(context, settings, csvProvider, colorScheme),
              const SizedBox(height: 24),
              _buildSectionTitle('APARIENCIA', colorScheme),
              const SizedBox(height: 8),
              _buildThemeCard(settings, colorScheme),
              const SizedBox(height: 24),
              _buildSectionTitle('AL ESCANEAR', colorScheme),
              const SizedBox(height: 8),
              _buildFeedbackCard(settings, colorScheme),
              const SizedBox(height: 24),
              _buildSectionTitle('ACERCA DE', colorScheme),
              const SizedBox(height: 8),
              _buildAboutCard(colorScheme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildCsvUrlCard(BuildContext context, SettingsProvider settings, CsvProvider csvProvider, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'URL del servidor CSV',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: settings.csvUrl,
              decoration: InputDecoration(
                hintText: 'https://ejemplo.com/personas.csv',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) => settings.setCsvUrl(value),
            ),
            const SizedBox(height: 12),
            _UpdateButton(settings: settings, csvProvider: csvProvider),
            const SizedBox(height: 8),
            Text(
              '${csvProvider.personas.length} personas cargadas',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(SettingsProvider settings, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.dark_mode_outlined, size: 24, color: colorScheme.onSurface),
                const SizedBox(width: 16),
                Text(
                  'Tema oscuro',
                  style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                ),
              ],
            ),
            Switch(
              value: settings.isDarkTheme,
              onChanged: (value) => settings.setDarkTheme(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(SettingsProvider settings, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRadioOption('Ninguno', settings.scanFeedback == ScanFeedback.none, () => settings.setScanFeedback(ScanFeedback.none), colorScheme),
            _buildRadioOption('Sonido', settings.scanFeedback == ScanFeedback.sound, () => settings.setScanFeedback(ScanFeedback.sound), colorScheme),
            _buildRadioOption('Vibración', settings.scanFeedback == ScanFeedback.vibration, () => settings.setScanFeedback(ScanFeedback.vibration), colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label, bool isSelected, VoidCallback onTap, ColorScheme colorScheme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: isSelected ? colorScheme.primary : colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: isSelected ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.info_outline, size: 24, color: colorScheme.onSurface),
            title: Text('Versión', style: TextStyle(fontSize: 16, color: colorScheme.onSurface)),
            trailing: Text(_getVersion(), style: TextStyle(fontSize: 16, color: colorScheme.onSurface)),
          ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
          ListTile(
            leading: Icon(Icons.help_outline, size: 24, color: colorScheme.onSurface),
            title: Text('¿Cómo usar?', style: TextStyle(fontSize: 16, color: colorScheme.onSurface)),
            trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _UpdateButton extends StatelessWidget {
  final SettingsProvider settings;
  final CsvProvider csvProvider;

  const _UpdateButton({required this.settings, required this.csvProvider});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: csvProvider.isLoading ? null : () async {
              if (settings.csvUrl.isEmpty) {
                OverlayMessage.error(ctx, 'Ingresa una URL primero');
                return;
              }
              final success = await csvProvider.actualizarLista(settings.csvUrl);
              if (!ctx.mounted) return;
              if (success) {
                OverlayMessage.success(ctx, 'Lista actualizada (${csvProvider.personas.length} personas)');
              } else {
                OverlayMessage.error(ctx, csvProvider.error ?? 'Error al descargar');
              }
            },
            icon: csvProvider.isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download),
            label: Text(csvProvider.isLoading ? 'Descargando...' : 'Actualizar Personas'),
          ),
        );
      },
    );
  }
}