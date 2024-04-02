import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterchain/flutterchain_lib/constants/chains/near_blockchain_network_urls.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/modules/home/pages/decryption_page_for_loggined_user.dart';
import 'package:near_social_mobile/modules/home/pages/near_widgets/widget_list_page.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/models/auth_info.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/utils/check_for_jailbreak.dart';
import 'package:near_social_mobile/utils/get_network_type.dart';

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
            title: SvgPicture.asset(NearAssets.logoIcon),
            centerTitle: true,
          ),
          body: const RouterOutlet(),
          // body: const NearWidgetListPage(),
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
                      Modular.to.navigate(".${Routes.home.postsFeed}");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.widgets),
                    color: Modular.to.path.endsWith(Routes.home.widgetsListPage)
                        ? Theme.of(context).primaryColor
                        : null,
                    onPressed: () {
                      Modular.to.navigate(".${Routes.home.widgetsListPage}");
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
