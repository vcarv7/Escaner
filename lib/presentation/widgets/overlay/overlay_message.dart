import 'package:flutter/material.dart';

class OverlayMessage {
  static const Duration defaultDuration = Duration(seconds: 2);
  static const double elevation = 8.0;
  static const double radius = 12.0;
  static const double paddingH = 24.0;
  static const double paddingV = 12.0;

  static void show(
    BuildContext context,
    String message,
    Color backgroundColor, {
    Duration? duration,
  }) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _OverlayMessageWidget(
        message: message,
        backgroundColor: backgroundColor,
        duration: duration ?? defaultDuration,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  static void success(BuildContext context, String message) {
    show(context, message, Colors.green);
  }

  static void warning(BuildContext context, String message) {
    show(context, message, Colors.orange);
  }

  static void error(BuildContext context, String message) {
    show(context, message, Colors.red);
  }

  static void info(BuildContext context, String message) {
    show(context, message, Colors.blue);
  }
}

class _OverlayMessageWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _OverlayMessageWidget({
    required this.message,
    required this.backgroundColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_OverlayMessageWidget> createState() => _OverlayMessageWidgetState();
}

class _OverlayMessageWidgetState extends State<_OverlayMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              elevation: OverlayMessage.elevation,
              borderRadius: BorderRadius.circular(OverlayMessage.radius),
              color: widget.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: OverlayMessage.paddingH,
                  vertical: OverlayMessage.paddingV,
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}