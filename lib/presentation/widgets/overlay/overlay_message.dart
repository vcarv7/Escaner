import 'package:flutter/material.dart';

class OverlayMessage {
  static const Duration defaultDuration = Duration(seconds: 2);
  static const double elevation = 8.0;
  static const double radius = 12.0;
  static const double paddingH = 32.0;
  static const double paddingV = 16.0;

  static void show(
    BuildContext context,
    String message,
    Color backgroundColor, {
    Duration? duration,
    String? technicalDetail,
  }) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _OverlayMessageWidget(
        message: message,
        backgroundColor: backgroundColor,
        duration: duration ?? defaultDuration,
        onDismiss: () => entry.remove(),
        technicalDetail: technicalDetail,
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

  static void error(
    BuildContext context,
    String message, {
    String? technicalDetail,
  }) {
    show(context, message, Colors.red, technicalDetail: technicalDetail);
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
  final String? technicalDetail;

  const _OverlayMessageWidget({
    required this.message,
    required this.backgroundColor,
    required this.duration,
    required this.onDismiss,
    this.technicalDetail,
  });

  @override
  State<_OverlayMessageWidget> createState() => _OverlayMessageWidgetState();
}

class _OverlayMessageWidgetState extends State<_OverlayMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _dismissed = false;

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismiss();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Con detalle técnico el aviso no se autoclosa: hay que darle tiempo a
    // expandirlo y leerlo. Sin detalle mantiene los 2 s de siempre.
    final detalle = widget.technicalDetail;
    if (detalle == null || detalle.isEmpty) {
      Future.delayed(widget.duration, () {
        if (mounted) {
          _controller.reverse().then((_) => _dismiss());
        }
      });
    }
  }

  @override
  void dispose() {
    // Garantiza que el OverlayEntry siempre se quite, incluso si la ruta
    // se cierra antes de que el Future.delayed dispare la animación de salida.
    _dismiss();
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
                child: GestureDetector(
                  onTap: _dismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.technicalDetail != null &&
                          widget.technicalDetail!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.white54),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(top: 8),
                            title: const Text(
                              'Detalle técnico',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.expand_more,
                              color: Colors.white70,
                              size: 18,
                            ),
                            children: [
                              SelectableText(
                                widget.technicalDetail!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tocá la notificación para cerrarla',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
