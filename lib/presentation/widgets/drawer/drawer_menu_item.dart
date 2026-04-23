import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'drawer_constants.dart';
import 'drawer_colors.dart';

class DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  const DrawerMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: DrawerConstants.spacingSmall / 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DrawerConstants.cardRadius),
        side: BorderSide(
          color: isPrimary ? DrawerColors.loginBorder : DrawerColors.itemBorder,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: DrawerConstants.iconContainerSize,
          height: DrawerConstants.iconContainerSize,
          decoration: BoxDecoration(
            color: isPrimary ? DrawerColors.loginBackground : DrawerColors.itemBackground,
            borderRadius: BorderRadius.circular(DrawerConstants.smallRadius),
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isPrimary ? AppTheme.primary : colorScheme.onSurface,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right, color: AppTheme.primary),
      ),
    );
  }
}