import 'package:flutter/material.dart';

class ScannerOverlay extends StatefulWidget {
  final bool isProcessing;

  const ScannerOverlay({
    super.key,
    required this.isProcessing,
  });

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}