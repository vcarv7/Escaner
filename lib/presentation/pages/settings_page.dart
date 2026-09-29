import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../providers/persona_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/dialogs/logout_dialog.dart';
import '../widgets/overlay/overlay_message.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Consumer3<SettingsProvider, PersonaProvider, AuthProvider>(
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
      ),
    );
  }

  Widget _buildCard(
    ColorScheme colorScheme,
    Widget child, {
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  Widget _divider(ColorScheme colorScheme) {
    return Divider(color: colorScheme.outline.withValues(alpha: 0.2));
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
        errorColor = AppTheme.warning;
        errorIcon = Icons.access_time;
      } else if (errorMsg.contains('conexión') || errorMsg.contains('sin conexión') || errorMsg.contains('red')) {
        errorColor = colorScheme.error;
        errorIcon = Icons.wifi_off;
      } else if (errorMsg.contains('servidor') || errorMsg.contains('500')) {
        errorColor = colorScheme.error;
        errorIcon = Icons.error_outline;
      } else if (errorMsg.contains('no autorizado') || errorMsg.contains('sesión expirada')) {
        errorColor = AppTheme.warning;
        errorIcon = Icons.lock_outline;
      } else if (errorMsg.contains('acceso denegado')) {
        errorColor = colorScheme.error;
        errorIcon = Icons.block;
      } else {
        errorColor = colorScheme.error;
        errorIcon = Icons.error_outline;
      }
    }

    return _buildCard(
      colorScheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lista de personas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('settings_sync_button'),
              onPressed: personaProvider.isSyncing
                  ? null
                  : () async {
                      final success = await personaProvider.syncPersonas();
                      if (!context.mounted) return;
                      if (success) {
                        OverlayMessage.success(
                          context,
                          'Sincronización completada (${personaProvider.totalCount} personas)',
                        );
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
          const SizedBox(height: 12),
          if (personaProvider.lastSync != null) ...[
            _divider(colorScheme),
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
            _divider(colorScheme),
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
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildThemeCard(SettingsProvider settings, ColorScheme colorScheme) {
    return _buildCard(
      colorScheme,
      Row(
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
            key: const ValueKey('settings_dark_theme_switch'),
            value: settings.isDarkTheme,
            onChanged: (value) => settings.setDarkTheme(value),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  Widget _buildFeedbackCard(SettingsProvider settings, ColorScheme colorScheme) {
    return _buildCard(
      colorScheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRadioOption(
            key: const ValueKey('settings_feedback_none'),
            label: 'Ninguno',
            isSelected: settings.scanFeedback == ScanFeedback.none,
            onTap: () => settings.setScanFeedback(ScanFeedback.none),
            colorScheme: colorScheme,
          ),
          _buildRadioOption(
            key: const ValueKey('settings_feedback_sound'),
            label: 'Sonido',
            isSelected: settings.scanFeedback == ScanFeedback.sound,
            onTap: () => settings.setScanFeedback(ScanFeedback.sound),
            colorScheme: colorScheme,
          ),
          _buildRadioOption(
            key: const ValueKey('settings_feedback_vibration'),
            label: 'Vibración',
            isSelected: settings.scanFeedback == ScanFeedback.vibration,
            onTap: () => settings.setScanFeedback(ScanFeedback.vibration),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    Key? key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      key: key,
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
    return _buildCard(
      colorScheme,
      Column(
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
              key: const ValueKey('settings_logout_button'),
              onPressed: () => LogoutDialog.show(context, onConfirm: () => _handleLogout(context)),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    await context.read<PersonaProvider>().clearSession();
    if (!context.mounted) return;
    OverlayMessage.success(context, 'Sesión cerrada correctamente');
  }

  Widget _buildAboutCard(ColorScheme colorScheme) {
    return _buildCard(
      colorScheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Versión', style: TextStyle(fontSize: 16, color: colorScheme.onSurface)),
              Text(AppConstants.appVersion, style: TextStyle(fontSize: 16, color: colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          _divider(colorScheme),
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
    );
  }
}
