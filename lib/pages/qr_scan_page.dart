import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          final barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;

          final raw = barcodes.first.rawValue;
          if (raw == null || raw.trim().isEmpty) return;

          _done = true;
          Navigator.of(context).pop(raw.trim());
        },
      ),
    );
  }
}