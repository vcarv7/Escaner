import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validation_utils.dart';
import 'scanner/scanner_overlay.dart';
import 'overlay/overlay_message.dart';

class ScannerWidget extends StatefulWidget {
  final void Function(String) onSolapineScanned;
  final VoidCallback? onScan;
  final bool enabled;

  const ScannerWidget({
    super.key,
    required this.onSolapineScanned,
    this.onScan,
    this.enabled = true,
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
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    _isProcessing = true;
    setState(() {});

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) {
      _isProcessing = false;
      setState(() {});
      return;
    }

    final validationError = ValidationUtils.validateCode(rawValue);
    if (validationError != null) {
      OverlayMessage.error(context, validationError);
      _isProcessing = false;
      setState(() {});
      return;
    }

    widget.onSolapineScanned(rawValue);
    widget.onScan?.call();

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
              ScannerOverlay(isProcessing: _isProcessing),
              if (_isProcessing)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
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