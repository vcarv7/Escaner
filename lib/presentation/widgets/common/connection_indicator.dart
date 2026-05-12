import 'package:flutter/material.dart';
import 'math_curve_loader.dart';

class ConnectionIndicator extends StatelessWidget {
  final bool isConnected;
  final bool isLoading;
  final VoidCallback onTap;
  final DateTime? lastCheck;

  const ConnectionIndicator({
    super.key,
    required this.isConnected,
    required this.isLoading,
    required this.onTap,
    this.lastCheck,
  });

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? Colors.green : Colors.red;
    final icon = isLoading
        ? Icons.sync
        : (isConnected ? Icons.cloud_done : Icons.cloud_off);

    return Tooltip(
      message: _getTooltip(),
      child: IconButton(
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: MathCurveLoader.epicycloid(
                  size: 20,
                  color: color,
                  duration: const Duration(milliseconds: 1000),
                  particleCount: 30,
                  trailSpan: 0.35,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(icon, color: color),
        onPressed: isLoading ? null : onTap,
      ),
    );
  }

  String _getTooltip() {
    if (isLoading) return 'Verificando conexión...';
    if (lastCheck == null) return 'Sin conexión verificada';
    final time = '${lastCheck!.hour.toString().padLeft(2, '0')}:${lastCheck!.minute.toString().padLeft(2, '0')}';
    return isConnected ? 'Conectado ($time)' : 'Sin conexión ($time)';
  }
}