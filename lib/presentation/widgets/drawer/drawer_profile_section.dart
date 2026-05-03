import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'drawer_constants.dart';
import 'drawer_animated_avatar.dart';

class DrawerProfileSection extends StatelessWidget {
  final String userName;
  final String userEmail;

  const DrawerProfileSection({
    super.key,
    this.userName = DrawerConstants.defaultUserName,
    this.userEmail = DrawerConstants.defaultUserEmail,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        ],
      ),
    );
  }
}