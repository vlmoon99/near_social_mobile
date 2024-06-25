
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterchain/flutterchain_lib/constants/chains/near_blockchain_network_urls.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/modules/home/pages/decryption_page_for_loggined_user.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/models/auth_info.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/services/firebase/firebase_notifications.dart';
import 'package:near_social_mobile/utils/check_for_jailbreak.dart';
import 'package:near_social_mobile/utils/get_network_type.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Modular.to.navigate(".${Routes.home.postsFeed}");
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    checkForJailbreak();
    final networkType = await getNearNetworkType();

    if (networkType == NearNetworkType.mainnet) {
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
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    return StreamBuilder<AuthInfo>(
      stream: authController.stream,
      builder: (context, _) {
        if (authController.state.status == AuthInfoStatus.unauthenticated) {
          return const DecryptionPageForLoginnedUser();
        }
        if (authController.state.status == AuthInfoStatus.authenticated) {
          FirebaseNotificationService.subscribeToNotifications(
              authController.state.accountId);
        }
        return Scaffold(
          appBar: AppBar(
            title: SvgPicture.asset(NearAssets.logoIcon),
            centerTitle: true,
          ),
          body: const RouterOutlet(),
          bottomNavigationBar: BottomAppBar(
            height: 60.w,
            padding: EdgeInsets.zero,
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
                      HapticFeedback.lightImpact();
                      Modular.to.navigate(".${Routes.home.postsFeed}");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.widgets),
                    color: Modular.to.path.endsWith(Routes.home.widgetsListPage)
                        ? Theme.of(context).primaryColor
                        : null,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Modular.to.navigate(".${Routes.home.widgetsListPage}");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.people),
                    color: Modular.to.path.endsWith(Routes.home.peopleListPage)
                        ? Theme.of(context).primaryColor
                        : null,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Modular.to.navigate(".${Routes.home.peopleListPage}");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    color:
                        Modular.to.path.endsWith(Routes.home.notificationsPage)
                            ? Theme.of(context).primaryColor
                            : null,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Modular.to.navigate(".${Routes.home.notificationsPage}");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu),
                    color: Modular.to.path.endsWith(Routes.home.homeMenu)
                        ? Theme.of(context).primaryColor
                        : null,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Modular.to.navigate(".${Routes.home.homeMenu}");
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
