import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutterchain/flutterchain_lib/constants/chains/near_blockchain_network_urls.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/assets/localizations/localizations_strings.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/formatters/models/qr_auth_info.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/services/testnet_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final jailBreakedDevice = await FlutterJailbreakDetection.jailbroken;
      if (jailBreakedDevice) {
        showDialog(
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(
                "This device is jailbroken. The security of the data in this application is not guaranteed."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
          context: Modular.routerDelegate.navigatorKey.currentContext!,
        );
      }
    });
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          LocalizationsStrings.auth.login.title,
        ).tr(),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Modular.to
                    .pushNamed(Routes.auth.getRoute(Routes.auth.qrReader));
              },
              child: const Text("Login with QR code"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  final TestNetService testNetService = TestNetService();
                  final account = await testNetService.createAccount();
                  await Modular.get<NearBlockChainService>()
                      .setBlockchainNetworkEnvironment(
                    newUrl: NearBlockChainNetworkUrls.listOfUrls.first,
                  );
                  Modular.to.pushReplacementNamed(
                    Routes.auth.getRoute(Routes.auth.encryptData),
                    arguments: QRAuthInfo(account.publicKey, account.secretKey),
                  );
                } on AppExceptions catch (err) {
                  final catcher = Modular.get<Catcher>();
                  catcher.exceptionsHandler.add(err);
                } catch (err) {
                  log(err.toString());
                }
              },
              child: const Text("Login with testnet"),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String labelText) {
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: const OutlineInputBorder(),
      labelText: labelText,
      labelStyle: const TextStyle(fontSize: 20),
    );
  }
}
