import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutterchain/flutterchain_lib/constants/chains/near_blockchain_network_urls.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      checkForJailbreak();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    "assets/media/images/near_social_backgorund.png",
                    fit: BoxFit.cover,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0).r,
                        width: .6.sw,
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.background,
                            borderRadius: BorderRadius.circular(10).r,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ]),
                        child: Text.rich(
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                          ),
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: "Attention!\n",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                style: TextStyle(fontSize: 14.sp),
                                text:
                                    "This is the technical version of the Near Social mobile application. It is intended for testing purposes and may contain bugs",
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 30.h),
                      ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await Modular.get<NearBlockChainService>()
                              .setBlockchainNetworkEnvironment(
                            newUrl: NearBlockChainNetworkUrls.listOfUrls
                                .elementAt(1),
                          );
                          Modular.to.pushNamed(
                              Routes.auth.getRoute(Routes.auth.qrReader));
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
                            final TestNetService testNetService =
                                TestNetService();
                            final account =
                                await testNetService.createAccount();
                            await Modular.get<NearBlockChainService>()
                                .setBlockchainNetworkEnvironment(
                              newUrl:
                                  NearBlockChainNetworkUrls.listOfUrls.first,
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
              ],
            ),
          ),
        ),
        if (true)
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
