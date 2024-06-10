import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutterchain/flutterchain_lib/constants/chains/near_blockchain_network_urls.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/assets/localizations/localizations_strings.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/vms/core/models/authorization_credentials.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/services/testnet_service.dart';
import 'package:near_social_mobile/shared_widgets/loading_barrier.dart';
import 'package:near_social_mobile/utils/check_for_jailbreak.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    checkForJailbreak();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await Modular.get<NearBlockChainService>()
                        .setBlockchainNetworkEnvironment(
                      newUrl: NearBlockChainNetworkUrls.listOfUrls.elementAt(1),
                    );
                    Modular.to
                        .pushNamed(Routes.auth.getRoute(Routes.auth.qrReader));
                  },
                  child: const Text("Login with QR code"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    try {
                      setState(() {
                        isLoading = true;
                      });
                      final TestNetService testNetService = TestNetService();
                      final account = await testNetService.createAccount();
                      await Modular.get<NearBlockChainService>()
                          .setBlockchainNetworkEnvironment(
                        newUrl: NearBlockChainNetworkUrls.listOfUrls.first,
                      );
                      Modular.to.pushReplacementNamed(
                        Routes.auth.getRoute(Routes.auth.encryptData),
                        arguments: AuthorizationCredentials(
                            account.publicKey, account.secretKey),
                      );
                    } catch (err) {
                      rethrow;
                    } finally {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  },
                  child: const Text("Login with testnet"),
                ),
              ],
            ),
          ),
        ),
        if (isLoading)
          const LoadingBarrier(
            message: "Testnet account creation...",
          ),
      ],
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
