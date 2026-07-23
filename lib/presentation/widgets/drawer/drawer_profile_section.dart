import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import 'drawer_constants.dart';
import 'drawer_animated_avatar.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/pages/login_page.dart';

class DrawerProfileSection extends StatelessWidget {
  const DrawerProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isAuthenticated = auth.isAuthenticated;
        final userName = auth.username ?? 'Invitado';
        final userEmail = isAuthenticated ? 'Sesión activa' : 'Inicia sesión para sincronizar';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            DrawerConstants.spacingLarge,
            DrawerConstants.spacingLarge + 24,
            DrawerConstants.spacingLarge,
            DrawerConstants.spacingLarge,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppTheme.primary.withValues(alpha: 0.4),
                      AppTheme.secondary.withValues(alpha: 0.2),
                      colorScheme.surface,
                    ]
                  : [
                      AppTheme.primary.withValues(alpha: 0.15),
                      AppTheme.secondary.withValues(alpha: 0.1),
                      Colors.white,
                    ],
            ),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: DrawerAnimatedAvatar(userName: userName),
              ),
              const SizedBox(height: DrawerConstants.spacingMedium + 4),
              Text(
                userName,
                style: TextStyle(
                  fontSize: DrawerConstants.titleFontSize + 2,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: TextStyle(
                  fontSize: DrawerConstants.subtitleFontSize,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: DrawerConstants.spacingMedium),
              if (isAuthenticated)
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sesión cerrada')),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DrawerConstants.smallRadius),
                    ),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Iniciar sesión'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DrawerConstants.smallRadius),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}