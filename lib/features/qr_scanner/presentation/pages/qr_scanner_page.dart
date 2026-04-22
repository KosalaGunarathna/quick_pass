import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../../../tickets/presentation/bloc/ticket_bloc.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  StreamSubscription<Barcode>? _scanSubscription;
  bool _processing = false;

  Future<void> _stopScanner() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await _controller?.pauseCamera();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _controller = null;
    super.dispose();
  }

  void _onQrViewCreated(QRViewController controller) {
    _controller = controller;
    _scanSubscription?.cancel();
    _scanSubscription = controller.scannedDataStream.listen((scanData) {
      if (!mounted) return;
      if (_processing) return;
      final code = scanData.code;
      if (code == null || code.isEmpty) return;

      _processing = true;
      context.read<TicketBloc>().add(TicketValidate(code));
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          await _stopScanner();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('QR Scanner'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          leading: BackButton(
            onPressed: () async {
              await _stopScanner();
              if (context.mounted) context.pop();
            },
          ),
        ),
        body: BlocListener<TicketBloc, TicketState>(
          listener: (context, state) async {
            if (state is TicketValidated) {
              if (state.isValid && state.ticket != null) {
                context.read<TicketBloc>().add(
                  TicketMarkUsed(state.ticket!.id),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ticket validated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid or already used ticket'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
              _processing = false;
            }

            if (state is TicketError) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              _processing = false;
            }
          },
          child: Stack(
            children: [
              QRView(
                key: _qrKey,
                onQRViewCreated: _onQrViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.deepPurple,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 280,
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Point camera at ticket QR code to validate',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
