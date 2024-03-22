import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterchain/flutterchain_lib/constants/chains/near_blockchain_network_urls.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:intl/intl.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/models/auth_info.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/services/crypto_storage_service.dart';
import 'package:near_social_mobile/services/local_auth_service.dart';
import 'package:near_social_mobile/shared_widgets/icon_button_with_counter.dart';
import 'package:near_social_mobile/utils/check_for_jailbreak.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();
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

  void _onScroll() async {
    final postsConroller = Modular.get<PostsController>();
    if (_isBottom &&
        postsConroller.state.status != PostLoadingStatus.loadingMorePosts) {
      postsConroller.loadMorePosts();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

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
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    final PostsController postsController = Modular.get<PostsController>();
    return StreamBuilder<AuthInfo>(
      stream: authController.stream,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: SvgPicture.asset("assets/media/icons/near_social_logo.svg"),
            centerTitle: true,
          ),
          body: StreamBuilder<Posts>(
            stream: postsController.stream,
            builder: (context, _) {
              final postsState = postsController.state;
              if (postsState.status == PostLoadingStatus.loaded ||
                  postsState.status == PostLoadingStatus.loadingMorePosts) {
                print("rebuilded");
                return ListView.builder(
                  controller: _scrollController,
                  padding: REdgeInsets.symmetric(horizontal: 15),
                  itemBuilder: (context, index) {
                    final post = postsState.posts[index];
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Modular.to.pushNamed(
                              ".${Routes.home.postPage}?accountId=${post.authorInfo.accountId}&blockHeight=${post.blockHeight}",
                            );
                          },
                          child: Card(
                            child: Padding(
                              padding: REdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      DateFormat('hh:mm a MMM dd, yyyy')
                                          .format(post.date),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),
                                  if (post.reposterInfo != null) ...[
                                    Text(
                                      "Reposted by ${post.reposterInfo?.name ?? ""} @${post.reposterInfo!.accountId}",
                                      style: TextStyle(
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                  RPadding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Text(
                                        "${post.authorInfo.name ?? ""} @${post.authorInfo.accountId}"),
                                  ),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: 200.h,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 40.w,
                                          height: 40.w,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Image.network(
                                            fit: BoxFit.cover,
                                            post.authorInfo.profileImageLink,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Image.asset(
                                                "assets/media/images/standart_avatar.png",
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: ListView(
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            shrinkWrap: true,
                                            children: [
                                              Text(
                                                post.postBody.text.trim(),
                                              ),
                                              if (post.postBody.mediaLink !=
                                                  null) ...[
                                                Image.network(
                                                  post.postBody.mediaLink!,
                                                  headers: const {
                                                    "Referer":
                                                        "https://near.social/"
                                                  },
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return const CircularProgressIndicator();
                                                  },
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      IconButtonWithCounter(
                                        iconPath:
                                            "assets/media/icons/like_icon.svg",
                                        count: post.likeList.length,
                                        activated: post.likeList.any(
                                          (element) =>
                                              element.accountId ==
                                              authController.state.accountId,
                                        ),
                                        onPressed: () {},
                                      ),
                                      IconButtonWithCounter(
                                        iconPath:
                                            "assets/media/icons/repost_icon.svg",
                                        count: post.repostList.length,
                                        activated: post.repostList.any(
                                          (element) =>
                                              element.accountId ==
                                              authController.state.accountId,
                                        ),
                                        activatedColor: Colors.green,
                                        onPressed: () {},
                                      ),
                                      IconButtonWithCounter(
                                        iconPath:
                                            "assets/media/icons/share_icon.svg",
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (postsState.status ==
                                PostLoadingStatus.loadingMorePosts &&
                            index == postsState.posts.length - 1) ...[
                          const Center(child: CircularProgressIndicator()),
                        ]
                      ],
                    );
                  },
                  itemCount: postsState.posts.length,
                );
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        );
      },
    );
  }

  Widget loginHomeWidget(AuthController authController) {
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

class AccountInfo extends StatelessWidget {
  const AccountInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    final AuthInfo authInfo = authController.state;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).r,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "AccountId: ${authInfo.accountId}",
            ),
            SizedBox(height: 20.h),
            Text(
              "PublicKey: ${authInfo.publicKey}",
            ),
            SizedBox(height: 20.h),
            Text(
              "SecretKey: ${authInfo.secretKey}",
            ),
            SizedBox(height: 20.h),
            Text(
              "PrivateKey: ${authInfo.privateKey}",
            ),
            SizedBox(height: 20.h),
            FutureBuilder(
              future: Modular.get<NearBlockChainService>()
                  .getWalletBalance(authInfo.accountId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Text(
                    "Near Amount: ${snapshot.data}",
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              },
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
