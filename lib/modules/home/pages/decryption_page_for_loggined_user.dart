import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/services/crypto_storage_service.dart';
import 'package:near_social_mobile/services/local_auth_service.dart';

class DecryptionPageForLoginnedUser extends StatelessWidget {
  const DecryptionPageForLoginnedUser({super.key});

  Future<void> decryptDataAndLogin() async {
    final secureStorage = Modular.get<FlutterSecureStorage>();
    final cryptoStorageService =
        CryptoStorageService(secureStorage: secureStorage);
    final encodedData = await cryptoStorageService.read(
      storageKey: SecureStorageKeys.authInfo,
    );
    final authController = Modular.get<AuthController>();
    final Map<String, dynamic> decodedData = jsonDecode(encodedData);
    authController.login(
      accountId: decodedData["accountId"],
      secretKey: decodedData["secretKey"],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  final bool authenticated =
                      await LocalAuthService().authenticate(
                    requestAuthMessage: 'Please authenticate to decrypt data',
                  );
                  if (!authenticated) return;
                  await decryptDataAndLogin();
                } on AppExceptions catch (err) {
                  final catcher = Modular.get<Catcher>();
                  catcher.exceptionsHandler.add(err);
                } catch (err) {
                  log(err.toString());
                }
              },
              child: const Text("Decrypt"),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () async {
                try {
                  await authController.logout();
                  Modular.to.navigate(Routes.auth.getModule());
                } on AppExceptions catch (err) {
                  final catcher = Modular.get<Catcher>();
                  catcher.exceptionsHandler.add(err);
                } catch (err) {
                  log(err.toString());
                }
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
