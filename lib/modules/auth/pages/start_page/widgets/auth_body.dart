import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/modules/home/vms/notifications/notifications_controller.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/filter_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/services/crypto_storage_service.dart';
import 'package:near_social_mobile/services/local_auth_service.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

class AuthenticatedBody extends StatelessWidget {
  const AuthenticatedBody(
      {super.key, required this.authenticatedStatusChanged});

  final void Function(bool authenticated) authenticatedStatusChanged;

  Future<void> decryptDataAndLogin() async {
    final secureStorage = Modular.get<FlutterSecureStorage>();
    final cryptoStorageService =
        CryptoStorageService(secureStorage: secureStorage);
    final encodedData = await cryptoStorageService.read(
      storageKey: SecureStorageKeys.authInfo,
    );
    final authController = Modular.get<AuthController>();
    final Map<String, dynamic> decodedData = jsonDecode(encodedData);
    await authController.login(
      accountId: decodedData["accountId"],
      secretKey: decodedData["secretKey"],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomButton(
            primary: true,
            onPressed: () async {
              late bool authenticated;
              if (kIsWeb) {
                authenticated = true;
              } else {
                authenticated = await LocalAuthService().authenticate(
                  requestAuthMessage: 'Please authenticate to decrypt data',
                );
              }
              if (!authenticated) return;
              await decryptDataAndLogin();
              Modular.to.navigate(Routes.home.getModule());
            },
            child: const Text(
              "Decrypt",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          CustomButton(
            onPressed: () async {
              Modular.get<AuthController>().logout().then(
                (_) {
                  authenticatedStatusChanged(false);
                },
              ).then(
                (_) {
                  Modular.tryGet<NotificationsController>()?.clear();
                  Modular.tryGet<FilterController>()?.clear();
                  Modular.tryGet<PostsController>()?.clear();
                },
              );
            },
            child: const Text(
              "Logout",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
