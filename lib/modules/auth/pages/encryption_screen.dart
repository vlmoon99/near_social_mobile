import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/formatters/models/qr_auth_info.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/services/crypto_storage_service.dart';
import 'package:near_social_mobile/services/crypto_service.dart';

class EncryptionScreen extends StatefulWidget {
  const EncryptionScreen({super.key, required this.qrAuthInfo});
  final QRAuthInfo qrAuthInfo;

  @override
  State<EncryptionScreen> createState() => _EncryptionScreenState();
}

class _EncryptionScreenState extends State<EncryptionScreen> {
  final TextEditingController _textEditingController = TextEditingController();

  Future<void> encryptDataAndLogin() async {
    final secureStorage = Modular.get<FlutterSecureStorage>();
    final cryptoStorageService =
        CryptoStorageService(secureStorage: secureStorage);
    final cryptographicKey = CryptoUtils.generateCryptographicKey();
    cryptoStorageService.write(
      cryptographicKey: cryptographicKey,
      storageKey: SecureStorageKeys.authInfo,
      data: jsonEncode(widget.qrAuthInfo),
    );
    final authController = Modular.get<AuthController>();
    await authController.login(
      accountId: widget.qrAuthInfo.accountId,
      secretKey: widget.qrAuthInfo.secretKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    log(widget.qrAuthInfo.toString());
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // const Text(
              //   "Encrypt your data with 6 digit key",
              //   style: TextStyle(fontSize: 20),
              // ),
              // SizedBox(height: 20.h),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 20).r,
              //   child: TextField(
              //     controller: _textEditingController,
              //     keyboardType: TextInputType.number,
              //     decoration: const InputDecoration(
              //       border: OutlineInputBorder(),
              //       labelText: "Key",
              //       floatingLabelBehavior: FloatingLabelBehavior.always,
              //       labelStyle: TextStyle(fontSize: 20),
              //     ),
              //   ),
              // ),
              // SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // if (_textEditingController.text.isEmpty ||
                    //     _textEditingController.text.length != 6) {
                    //   return;
                    // }
                    await encryptDataAndLogin();
                    Modular.to.navigate(Routes.home.getModule());
                  } on AppExceptions catch (err) {
                    final catcher = Modular.get<Catcher>();
                    catcher.exceptionsHandler.add(err);
                  } catch (err) {
                    log(err.toString());
                  }
                },
                child: const Text("Encrypt"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
