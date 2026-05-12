import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../providers/settings_provider.dart';
import '../providers/csv_provider.dart';
import '../widgets/overlay/overlay_message.dart';
import '../widgets/common/math_curve_loader.dart';

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
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: settings.csvUrl,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'https://ejemplo.com/personas.csv',
                hintStyle: TextStyle(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (value) => settings.setCsvUrl(value),
            ),
            const SizedBox(height: 14),
            _UpdateButton(settings: settings, csvProvider: csvProvider),
            const SizedBox(height: 10),
            Text(
              '${csvProvider.personas.length} personas cargadas',
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.dark_mode_outlined, size: 28, color: colorScheme.onSurface),
                const SizedBox(width: 18),
                Text(
                  'Tema oscuro',
                  style: TextStyle(fontSize: 18, color: colorScheme.onSurface),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 26,
              color: isSelected ? colorScheme.primary : colorScheme.outline,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Versión', style: TextStyle(fontSize: 16, color: colorScheme.onSurface)),
                Text(_getVersion(), style: TextStyle(fontSize: 16, color: colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Todos los Derechos Reservados UCI',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '© 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
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
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: MathCurveLoader.epicycloid(
                      size: 24,
                      color: Theme.of(ctx).colorScheme.primary,
                      duration: const Duration(milliseconds: 1200),
                      particleCount: 40,
                      trailSpan: 0.4,
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(Icons.download),
            label: Text(csvProvider.isLoading ? 'Descargando...' : 'Actualizar Personas'),
          ),
        );
      },
    );
  }
}