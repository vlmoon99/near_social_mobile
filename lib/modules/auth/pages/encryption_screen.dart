import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/assets/localizations/localizations_strings.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/modules/vms/core/models/authorization_credentials.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/services/crypto_storage_service.dart';
import 'package:near_social_mobile/services/crypto_service.dart';
import 'package:near_social_mobile/services/local_auth_service.dart';

class EncryptionScreen extends StatefulWidget {
  const EncryptionScreen({super.key, required this.authorizationCredentials});
  final AuthorizationCredentials authorizationCredentials;

  @override
  State<EncryptionScreen> createState() => _EncryptionScreenState();
}

class _EncryptionScreenState extends State<EncryptionScreen> {
  Future<void> encryptDataAndLogin() async {
    final secureStorage = Modular.get<FlutterSecureStorage>();
    final cryptoStorageService =
        CryptoStorageService(secureStorage: secureStorage);
    final cryptographicKey = CryptoUtils.generateCryptographicKey();
    await cryptoStorageService.saveCryptographicKeyToStorage(
        cryptographicKey: cryptographicKey);
    await cryptoStorageService.write(
      storageKey: SecureStorageKeys.authInfo,
      data: jsonEncode(widget.authorizationCredentials),
    );
    await Modular.get<NearBlockChainService>()
        .getBlockchainNetworkEnvironment()
        .then(
      (networkUrl) async {
        if (networkUrl.contains("mainnet")) {
          await Modular.get<FlutterSecureStorage>()
              .write(key: SecureStorageKeys.networkType, value: "mainnet");
        } else {
          await Modular.get<FlutterSecureStorage>()
              .write(key: SecureStorageKeys.networkType, value: "testnet");
        }
      },
    );
    final authController = Modular.get<AuthController>();
    await authController.login(
      accountId: widget.authorizationCredentials.accountId,
      secretKey: widget.authorizationCredentials.secretKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    log(widget.authorizationCredentials.toString());
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/media/icons/near_social_logo.svg"),
            SizedBox(width: 10.w),
            Text(
              LocalizationsStrings.home.title,
              style: const TextStyle(fontSize: 20),
            ).tr(),
          ],
        ),
        centerTitle: true,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: REdgeInsets.symmetric(horizontal: 24),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Attention!\n",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24.0,
                        ),
                      ),
                      const TextSpan(
                        text:
                            "To protect your authentication data, it will be encrypted and secured with a password. For this to work, device protection must be enabled on your device.",
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final bool authenticated =
                      await LocalAuthService().authenticate(
                    requestAuthMessage: 'Please authenticate to encrypt data',
                  );
                  if (!authenticated) return;
                  await encryptDataAndLogin();
                  Modular.to.navigate(Routes.home.getModule());
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
