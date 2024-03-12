import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/formatters/qr_formatter.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRReaderScreen extends StatefulWidget {
  const QRReaderScreen({super.key});

  @override
  State<QRReaderScreen> createState() => _QRReaderScreenState();
}

class _QRReaderScreenState extends State<QRReaderScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream
        .distinct(
      (prev, next) => prev.code == next.code,
    )
        .listen((scanData) {
      try {
        if (scanData.code == null) return;
        final qrAuthInfo = QRFormatter.convertURLToQRAuthInfo(scanData.code!);
        controller.stopCamera();
        // Modular.to.pop(qrAuthInfo);
        Modular.to.pushReplacementNamed(
          Routes.auth.getRoute(Routes.auth.encryptData),
          arguments: qrAuthInfo,
        );
      } on AppExceptions catch (err) {
        log(err.messageForDev);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.messageForUser),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      } catch (err) {
        log(err.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          formatsAllowed: const [BarcodeFormat.qrcode],
          overlay: QrScannerOverlayShape(
            borderColor: Theme.of(context).primaryColor,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: 300.w,
          ),
        ),
      ),
    );
  }
}
