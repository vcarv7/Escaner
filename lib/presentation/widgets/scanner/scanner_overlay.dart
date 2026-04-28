import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ScannerOverlay extends StatefulWidget {
  final bool isProcessing;

  const ScannerOverlay({
    super.key,
    required this.isProcessing,
  });

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _lineAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _lineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isProcessing) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _lineAnimation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final scanAreaWidth = constraints.maxWidth * 0.85;
            final linePosition = _lineAnimation.value * scanAreaWidth;

            return Stack(
              children: [
                Positioned(
                  left: (constraints.maxWidth - scanAreaWidth) / 2 + linePosition,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.primary.withValues(alpha: 0.6),
                          AppTheme.primary,
                          AppTheme.primary.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}