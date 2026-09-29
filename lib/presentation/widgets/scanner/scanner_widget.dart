import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validation_utils.dart';
import '../overlay/overlay_message.dart';
import '../common/math_curve_loader.dart';

class ScannerWidget extends StatefulWidget {
  final void Function(String) onSolapineScanned;
  final bool enabled;
  final String? disabledMessage;

  const ScannerWidget({
    super.key,
    required this.onSolapineScanned,
    this.enabled = true,
    this.disabledMessage,
  });

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget> {
  late MobileScannerController _controller;
  bool _isProcessing = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    if (!widget.enabled) unawaited(_setCameraActive(false));
  }

  @override
  void didUpdateWidget(covariant ScannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled == widget.enabled) return;
    // Apagar la cámara, y no solo ignorar las detecciones, evita que el
    // operador siga creyendo que el escáner está operativo.
    unawaited(_setCameraActive(widget.enabled));
    if (!widget.enabled) {
      _cooldownTimer?.cancel();
      // Sin setState: build() corre justo después de este método.
      _isProcessing = false;
    }
  }

  /// `start()`/`stop()` hablan con el canal de la plataforma y pueden fallar
  /// si la cámara no está disponible (permisos, emulador, pruebas). Eso no debe
  /// tumbar el escáner: la guarda de `enabled` en `_handleDetect` es la que
  /// realmente decide si un código se procesa.
  Future<void> _setCameraActive(bool active) async {
    try {
      if (active) {
        await _controller.start();
      } else {
        await _controller.stop();
      }
    } catch (e) {
      debugPrint('ScannerWidget: no se pudo ${active ? 'arrancar' : 'detener'} la cámara: $e');
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    if (!widget.enabled) return;

    // Verificar barcodes ANTES de activar _isProcessing para evitar
    // que el escáner quede pausado permanentemente si llega una captura vacía.
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _isProcessing = true;
    setState(() {});

    final validationError = ValidationUtils.validateCode(rawValue);
    if (validationError != null) {
      OverlayMessage.error(context, validationError);
      _isProcessing = false;
      setState(() {});
      return;
    }

    widget.onSolapineScanned(rawValue);

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(AppConstants.scanCooldown, () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        
        double scannerHeight;
        if (screenHeight < 600) {
          scannerHeight = 100;
        } else if (screenHeight < 700) {
          scannerHeight = 120;
        } else if (screenHeight < 800) {
          scannerHeight = 140;
        } else {
          scannerHeight = 160;
        }

        return Container(
          height: scannerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _handleDetect,
              ),
              if (!widget.enabled)
                Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Semantics(
                      label: widget.disabledMessage ?? 'Escaneo deshabilitado',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.videocam_off_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.disabledMessage ?? 'Escaneo deshabilitado',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_isProcessing)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MathCurveLoader.epicycloid(
                          size: 80,
                          color: Colors.white,
                          duration: const Duration(milliseconds: 1800),
                          particleCount: 60,
                          trailSpan: 0.4,
                          strokeWidth: 4,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Escáner en pausa...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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