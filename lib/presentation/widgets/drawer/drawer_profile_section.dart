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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DrawerConstants.spacingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primary.withValues(alpha: 0.1),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          DrawerAnimatedAvatar(userName: userName),
          const SizedBox(height: DrawerConstants.spacingMedium),
          Text(
            userName,
            style: TextStyle(
              fontSize: DrawerConstants.titleFontSize,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
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