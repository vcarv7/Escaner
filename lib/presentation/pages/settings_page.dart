import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../providers/settings_provider.dart';
import '../providers/persona_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/overlay/overlay_message.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Consumer3<SettingsProvider, PersonaProvider, AuthProvider>(
        builder: (context, settings, personaProvider, auth, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('SINCRONIZACIÓN', colorScheme),
              const SizedBox(height: 8),
              _buildSyncCard(context, personaProvider, colorScheme),
              const SizedBox(height: 24),
              _buildSectionTitle('APARIENCIA', colorScheme),
              const SizedBox(height: 8),
              _buildThemeCard(settings, colorScheme),
              const SizedBox(height: 24),
              _buildSectionTitle('AL ESCANEAR', colorScheme),
              const SizedBox(height: 8),
              _buildFeedbackCard(settings, colorScheme),
              const SizedBox(height: 24),
              _buildSectionTitle('CUENTA', colorScheme),
              const SizedBox(height: 8),
              _buildAccountCard(context, auth, colorScheme),
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

  Widget _buildSyncCard(BuildContext context, PersonaProvider personaProvider, ColorScheme colorScheme) {
    Color? errorColor;
    IconData? errorIcon;
    
    if (personaProvider.error != null) {
      final errorMsg = personaProvider.error!.toLowerCase();
      if (errorMsg.contains('tiempo') || errorMsg.contains('timeout')) {
        errorColor = Colors.orange.shade700;
        errorIcon = Icons.access_time;
      } else if (errorMsg.contains('conexión') || errorMsg.contains('sin conexión') || errorMsg.contains('red')) {
        errorColor = Colors.red.shade700;
        errorIcon = Icons.wifi_off;
      } else if (errorMsg.contains('servidor') || errorMsg.contains('500')) {
        errorColor = Colors.red.shade700;
        errorIcon = Icons.error_outline;
      } else if (errorMsg.contains('no autorizado') || errorMsg.contains('sesión expirada')) {
        errorColor = Colors.orange.shade700;
        errorIcon = Icons.lock_outline;
      } else if (errorMsg.contains('acceso denegado')) {
        errorColor = Colors.red.shade700;
        errorIcon = Icons.block;
      } else {
        errorColor = Colors.red.shade700;
        errorIcon = Icons.error_outline;
      }
    }

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
              'Lista de personas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: personaProvider.isSyncing ? null : () async {
                      final success = await personaProvider.syncPersonas();
                      if (!context.mounted) return;
                      if (success) {
                        OverlayMessage.success(context, 'Sincronización completada (${personaProvider.totalCount} personas)');
                      } else {
                        OverlayMessage.error(context, personaProvider.error ?? 'Error al sincronizar');
                      }
                    },
                    icon: personaProvider.isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                    label: Text(personaProvider.isSyncing ? 'Sincronizando...' : 'Sincronizar ahora'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (personaProvider.lastSync != null) ...[
              Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
              const SizedBox(height: 8),
              Text(
                'Última sincronización: ${_formatDateTime(personaProvider.lastSync!)}',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              Text(
                '${personaProvider.totalCount} personas cargadas',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ] else if (personaProvider.hasPersonas) ...[
              Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
              const SizedBox(height: 8),
              Text(
                '${personaProvider.totalCount} personas en caché local',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
            if (personaProvider.error != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(errorIcon, size: 16, color: errorColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      personaProvider.error!,
                      style: TextStyle(fontSize: 13, color: errorColor),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

  Widget _buildAccountCard(BuildContext context, AuthProvider auth, ColorScheme colorScheme) {
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
            if (auth.username != null) ...[
              Text(
                'Sesión iniciada como',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 4),
              Text(
                auth.username!,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context, auth),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.logout();
      if (context.mounted) {
        OverlayMessage.success(context, 'Sesión cerrada correctamente');
      }
    }
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

  String _getVersion() {
    return AppConstants.appVersion;
  }
}