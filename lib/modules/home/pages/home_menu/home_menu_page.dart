import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutterchain/flutterchain_lib/models/chains/near/near_account_info_request.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/modules/home/pages/chat/rooms_page.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/widgets/home_menu_list_tile.dart';
import 'package:near_social_mobile/modules/home/vms/notifications/notifications_controller.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/filter_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/services/notification_subscription_service.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class HomeMenuPage extends StatefulWidget {
  const HomeMenuPage({super.key});

  @override
  State<HomeMenuPage> createState() => _HomeMenuPageState();
}

class _HomeMenuPageState extends State<HomeMenuPage> {
  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    final UserListController userListController =
        Modular.get<UserListController>();
    return Scaffold(
      body: ListView(
        children: [
          FutureBuilder(
            future: userListController.loadAndAddGeneralAccountInfoIfNotExists(
                accountId: authController.state.accountId),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return SizedBox(
                  height: .3.sh,
                  child: const Center(
                    child: SpinnerLoadingIndicator(),
                  ),
                );
              } else {
                final user = userListController.state.getUserByAccountId(
                    accountId: authController.state.accountId);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: .25.sh,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          SizedBox(
                            height: .20.sh,
                            width: double.infinity,
                            child: NearNetworkImage(
                              imageUrl:
                                  user.generalAccountInfo.backgroundImageLink,
                              errorPlaceholder:
                                  Container(color: AppColors.lightSurface),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 20.h,
                            width: .18.sh,
                            height: .18.sh,
                            child: Container(
                              padding: REdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border:
                                    Border.all(color: Colors.black, width: 1),
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: NearNetworkImage(
                                  imageUrl:
                                      user.generalAccountInfo.profileImageLink,
                                  errorPlaceholder: Image.asset(
                                    NearAssets.standartAvatar,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20).r,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.generalAccountInfo.name != ""
                                ? user.generalAccountInfo.name
                                : "No Name",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.person_fill,
                                size: 14,
                              ),
                              SizedBox(width: 5.h),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: user.generalAccountInfo.accountId,
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "AccountId ${user.generalAccountInfo.accountId} copied to clipboard"),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "@${user.generalAccountInfo.accountId}",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5.h),
                          FutureBuilder(
                            future: Modular.get<NearBlockChainService>()
                                .getWalletBalance(NearAccountInfoRequest(
                                    accountId: authController.state.accountId)),
                            builder: (context, snapshot) {
                              return Row(
                                children: [
                                  const Text(
                                    "Balance: ",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 5.h),
                                  if (snapshot.connectionState !=
                                      ConnectionState.done)
                                    AnimatedTextKit(
                                      animatedTexts: [
                                        FadeAnimatedText('Loading...'),
                                      ],
                                      isRepeatingAnimation: true,
                                      repeatForever: true,
                                    )
                                  else
                                    Expanded(
                                      child: Text(
                                        "${snapshot.data} NEAR",
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20).r,
            child: Column(
              children: [
                HomeMenuListTile(
                  title: "Key Manager",
                  tile: SvgPicture.asset(
                    "assets/media/icons/key-icon.svg",
                    color: IconTheme.of(context).color,
                    height: IconTheme.of(context).size,
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Modular.to.pushNamed(
                      ".${Routes.home.keyManagerPage}",
                    );
                  },
                ),
                SizedBox(height: 15.h),
                HomeMenuListTile(
                  tile: SvgPicture.asset(
                    "assets/media/icons/nft-token.svg",
                    color: IconTheme.of(context).color,
                    height: IconTheme.of(context).size,
                  ),
                  title: "Mintbase Manager",
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Modular.to.pushNamed(
                      ".${Routes.home.mintManager}/",
                    );
                  },
                ),
                SizedBox(height: 15.h),
                HomeMenuListTile(
                  tile: const Icon(Icons.settings),
                  title: "Settings",
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Modular.to.pushNamed(
                      ".${Routes.home.settingsPage}",
                    );
                  },
                ),
                SizedBox(height: 15.h),
                HomeMenuListTile(
                  title: "Chats",
                  tile: const Icon(Icons.chat),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => RoomsPage(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 15.h),
                HomeMenuListTile(
                  title: "Logout",
                  tile: const Icon(Icons.logout),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text(
                          "Are you sure you want to logout?",
                          textAlign: TextAlign.center,
                        ),
                        actionsAlignment: MainAxisAlignment.spaceEvenly,
                        actions: [
                          CustomButton(
                            primary: true,
                            onPressed: () {
                              Modular.to.pop(true);
                            },
                            child: const Text(
                              "Yes",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          CustomButton(
                            onPressed: () {
                              Modular.to.pop(false);
                            },
                            child: const Text(
                              "No",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).then(
                      (value) {
                        if (value != null && value) {
                          final authController = Modular.get<AuthController>();
                          if (!kIsWeb) {
                            Modular.get<NotificationSubscriptionService>()
                                .unsubscribeFromNotifications(
                                    authController.state.accountId);
                          }
                          authController.logout();
                          Modular.get<NotificationsController>().clear();
                          Modular.get<FilterController>().clear();
                          Modular.get<PostsController>().clear();
                          Modular.to.navigate("/");
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
