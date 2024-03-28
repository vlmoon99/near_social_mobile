import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterchain/flutterchain_lib/constants/chains/near_blockchain_network_urls.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/models/auth_info.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/services/crypto_storage_service.dart';
import 'package:near_social_mobile/services/local_auth_service.dart';
import 'package:near_social_mobile/utils/check_for_jailbreak.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    checkForJailbreak();
    final networkType = await Modular.get<FlutterSecureStorage>().read(
      key: SecureStorageKeys.networkType,
    );

    if (networkType == "mainnet") {
      await Modular.get<NearBlockChainService>()
          .setBlockchainNetworkEnvironment(
        newUrl: NearBlockChainNetworkUrls.listOfUrls.elementAt(1),
      );
    } else {
      await Modular.get<NearBlockChainService>()
          .setBlockchainNetworkEnvironment(
        newUrl: NearBlockChainNetworkUrls.listOfUrls.first,
      );
    }
    final PostsController postsController = Modular.get<PostsController>();
    if (postsController.state.status == PostLoadingStatus.initial) {
      postsController.loadPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    Modular.to.navigate(".${Routes.home.postsFeed}");
    final AuthController authController = Modular.get<AuthController>();
    return StreamBuilder<AuthInfo>(
      stream: authController.stream,
      builder: (context, _) {
        if (authController.state.status == AuthInfoStatus.unauthenticated) {
          return const DecryptionPageForLoginnedUser();
        }
        return Scaffold(
          appBar: AppBar(
            title: SvgPicture.asset("assets/media/icons/near_social_logo.svg"),
            centerTitle: true,
          ),
          body: const RouterOutlet(),
          bottomNavigationBar: BottomAppBar(
            height: 60.w,
            padding: EdgeInsets.zero,
            elevation: 5,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black,
            color: Colors.white,
            child: NavigationListener(builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.feed),
                    color: Modular.to.path.endsWith(Routes.home.postsFeed)
                        ? Theme.of(context).primaryColor
                        : null,
                    onPressed: () {
                      Modular.to.navigate(".${Routes.home.postsFeed}");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.account_circle),
                    color: Modular.to.path.endsWith(Routes.home.accountPage)
                        ? Theme.of(context).primaryColor
                        : null,
                    onPressed: () {
                      Modular.to.navigate(".${Routes.home.accountPage}");
                    },
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}

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
