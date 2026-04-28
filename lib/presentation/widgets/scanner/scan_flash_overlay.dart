import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ScanFlashOverlay extends StatefulWidget {
  final VoidCallback? onComplete;

  const ScanFlashOverlay({
    super.key,
    this.onComplete,
  });

  @override
  State<ScanFlashOverlay> createState() => _ScanFlashOverlayState();
}

class _ScanFlashOverlayState extends State<ScanFlashOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Container(
          color: AppTheme.primary.withValues(alpha: _opacityAnimation.value),
        );
      },
    );
  }
}