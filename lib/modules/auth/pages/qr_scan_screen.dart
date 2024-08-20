import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/formatters/qr_formatter.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qrcode_reader_web/qrcode_reader_web.dart';

class QRReaderScreen extends StatefulWidget {
  const QRReaderScreen({super.key});

  @override
  State<QRReaderScreen> createState() => _QRReaderScreenState();
}

class _QRReaderScreenState extends State<QRReaderScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final StreamController<String> _webQRReaderController = StreamController();

  @override
  void initState() {
    super.initState();
    _webQRReaderController.stream.distinct().listen(checkIfQRCodeIsValid);
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream
        .distinct(
      (prev, next) => prev.code == next.code,
    )
        .listen((scanData) {
      if (scanData.code == null) return;
      checkIfQRCodeIsValid(scanData.code!);
    });
  }

  checkIfQRCodeIsValid(String code) async {
    try {
      final authorizationCredentials =
          QRFormatter.convertURLToAuthorizationCredentials(code);
      Modular.to.pushReplacementNamed(
        Routes.auth.getRoute(Routes.auth.encryptData),
        arguments: authorizationCredentials,
      );
    } on AppExceptions catch (err) {
      log(err.messageForDev);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.messageForUser),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
        ),
      );
    } catch (err) {
      log(err.toString());
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    _webQRReaderController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: kIsWeb
            ? QRCodeReaderSquareWidget(
                borderRadius: BorderRadius.circular(10),
                targetColor: Theme.of(context).primaryColor,
                onDetect: (QRCodeCapture capture) async {
                  _webQRReaderController.add(capture.raw);
                },
                size: 300.h,
              )
            : QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                formatsAllowed: const [BarcodeFormat.qrcode],
                overlay: QrScannerOverlayShape(
                  borderColor: Theme.of(context).primaryColor,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 300.h,
                ),
              ),
      ),
    );
  }
}
