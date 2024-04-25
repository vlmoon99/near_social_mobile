import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
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
      body: SafeArea(
        child: SizedBox(
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
                      requestAuthMessage: 'Please authenticate to encrypt data',
                    );
                    if (!authenticated) return;
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
