import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'drawer_constants.dart';

class DrawerAnimatedAvatar extends StatefulWidget {
  final String userName;

  const DrawerAnimatedAvatar({
    super.key,
    required this.userName,
  });

  @override
  State<DrawerAnimatedAvatar> createState() => _DrawerAnimatedAvatarState();
}

class _DrawerAnimatedAvatarState extends State<DrawerAnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DrawerConstants.avatarAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _initial {
    if (widget.userName.isEmpty) return DrawerConstants.defaultUserInitial;
    return widget.userName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: DrawerConstants.avatarSize,
        height: DrawerConstants.avatarSize,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _initial,
            style: const TextStyle(
              fontSize: DrawerConstants.iconSizeLarge,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}