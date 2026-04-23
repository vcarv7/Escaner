import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validation_utils.dart';
import 'overlay/overlay_message.dart';

class ScannerWidget extends StatefulWidget {
  final void Function(String) onSolapineScanned;
  final VoidCallback? onScan;

  const ScannerWidget({
    super.key,
    required this.onSolapineScanned,
    this.onScan,
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

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    final validationError = ValidationUtils.validateCode(rawValue);
    if (validationError != null) {
      OverlayMessage.error(context, validationError);
      return;
    }

    _isProcessing = true;
    widget.onSolapineScanned(rawValue);
    widget.onScan?.call();

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(AppConstants.scanCooldown, () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.2,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: MobileScanner(
          controller: _controller,
          onDetect: _handleDetect,
        ),
      ),
    );
  }
}