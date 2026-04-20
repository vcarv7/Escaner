import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerWidget extends StatefulWidget {
  final void Function(String) onSolapineScanned;

  const ScannerWidget({super.key, required this.onSolapineScanned});

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget> {
  MobileScannerController? _controller;
  bool _isProcessing = false;

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
    _controller?.dispose();
    super.dispose();
  }

  bool _isValidSolapine(String value) {
    final length = value.length;
    return length >= 5 && length <= 15;
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    if (!_isValidSolapine(rawValue)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El código debe tener entre 5 y 15 caracteres'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _isProcessing = true;
    widget.onSolapineScanned(rawValue);

    Future.delayed(const Duration(seconds: 2), () {
      _isProcessing = false;
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