import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/user_page_info.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/user_page_tabs/user_nfts.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/user_page_tabs/user_posts.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/user_page_tabs/user_widgets.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/modules/vms/core/filter_controller.dart';
import 'package:near_social_mobile/services/pausable_timer.dart';
import 'package:palette_generator/palette_generator.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key, required this.accountId});

  final String accountId;

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage>
    with SingleTickerProviderStateMixin {
  Color backgroundColor = AppColors.background;
  late final _tabController = TabController(length: 3, vsync: this);
  late final PausableTimer _generalProfileInfoTimer;
  PausableTimer? _nftsUpdatingTimer;
  PausableTimer? _widgetsUpdatingTimer;

  @override
  void initState() {
    super.initState();
    final UserListController userListController =
        Modular.get<UserListController>();
    final user = userListController.state
        .getUserByAccountId(accountId: widget.accountId);

    _generalProfileInfoTimer = PausableTimer.periodic(
      const Duration(seconds: 40),
      () async {
        _generalProfileInfoTimer.pause();
        await Modular.get<UserListController>()
            .reloadUserInfo(accountId: widget.accountId);
        await Modular.get<PostsController>()
            .updatePostsOfAccount(postsOfAccountId: widget.accountId);
        _generalProfileInfoTimer.start();
      },
    );

    //nft auto update

    //nfts never vere loaded
    if (user.timeOfLastNftsUpdate == null) {
      _nftsUpdatingTimer = PausableTimer.periodic(
        const Duration(minutes: 6),
        () async {
          _nftsUpdatingTimer?.pause();
          if (user.nfts != null) {
            await userListController.loadNftsOfAccount(
              accountId: widget.accountId,
            );
          }
          _nftsUpdatingTimer?.start();
        },
      )..start();
    } else {
      //calculate time for remaining time to load nfts
      final difference = DateTime.now().difference(user.timeOfLastNftsUpdate!);
      final delayedTime = difference.inMinutes >= 6
          ? const Duration(seconds: 5)
          : (const Duration(minutes: 6) - difference);
      Future.delayed(
        delayedTime,
        () {
          userListController
              .loadNftsOfAccount(
            accountId: widget.accountId,
          )
              .then(
            (_) {
              _nftsUpdatingTimer = PausableTimer.periodic(
                const Duration(minutes: 6),
                () async {
                  _nftsUpdatingTimer?.pause();
                  if (user.nfts != null) {
                    await userListController.loadNftsOfAccount(
                      accountId: widget.accountId,
                    );
                  }
                  _nftsUpdatingTimer?.start();
                },
              )..start();
            },
          );
        },
      );
    }

    if (user.timeOfLastWidgetsUpdate == null) {
      _widgetsUpdatingTimer = PausableTimer.periodic(
        const Duration(minutes: 5),
        () async {
          _widgetsUpdatingTimer?.pause();
          if (user.widgetList != null) {
            await userListController.loadWidgetsOfAccount(
              accountId: widget.accountId,
            );
          }
          _widgetsUpdatingTimer?.start();
        },
      )..start();
    } else {
      //calculate time for remaining time to load widgets
      final difference =
          DateTime.now().difference(user.timeOfLastWidgetsUpdate!);
      final delayedTime = difference.inMinutes >= 5
          ? const Duration(seconds: 10)
          : (const Duration(minutes: 5) - difference);
      Future.delayed(
        delayedTime,
        () {
          userListController
              .loadWidgetsOfAccount(
            accountId: widget.accountId,
          )
              .then(
            (_) {
              _widgetsUpdatingTimer = PausableTimer.periodic(
                const Duration(minutes: 5),
                () async {
                  _widgetsUpdatingTimer?.pause();
                  if (user.widgetList != null) {
                    await userListController.loadWidgetsOfAccount(
                      accountId: widget.accountId,
                    );
                  }
                  _widgetsUpdatingTimer?.start();
                },
              )..start();
            },
          );
        },
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final UserListController userListController =
        Modular.get<UserListController>();
    final currentUser = userListController.state
        .getUserByAccountId(accountId: widget.accountId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (currentUser.generalAccountInfo.backgroundImageLink != "" &&
            !kIsWeb) {
          PaletteGenerator.fromImageProvider(
            CachedNetworkImageProvider(
              currentUser.generalAccountInfo.backgroundImageLink,
              maxHeight: 640,
              maxWidth: 640,
              headers: const {"Referer": "https://near.social/"},
              errorListener: (err) {
                log(err.toString());
              },
            ),
            timeout: Duration.zero,
          ).then(
            (palette) {
              final dominantColor = palette.dominantColor?.color;
              if (dominantColor != null) {
                setState(() {
                  backgroundColor = dominantColor;
                });
              }
            },
          );
        }
      } catch (err) {}
    });
    final PostsController postsController = Modular.get<PostsController>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!userListController.state.users
          .firstWhere(
              (user) => user.generalAccountInfo.accountId == widget.accountId)
          .allMetadataLoaded) {
        await userListController.loadAdditionalMetadata(
            accountId: widget.accountId);
        if (postsController.state.postsOfAccounts[widget.accountId] == null) {
          await postsController.loadPosts(
            postsViewMode: PostsViewMode.account,
            postsOfAccountId: widget.accountId,
          );
        }
        _generalProfileInfoTimer.start();
      }
    });
  }

  @override
  void dispose() {
    _generalProfileInfoTimer.cancel();
    _nftsUpdatingTimer?.cancel();
    _widgetsUpdatingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FilterController filterController = Modular.get<FilterController>();
    return StreamBuilder(
      stream: filterController.stream,
      builder: (context, snapshot) {
        final filtersUtil = FiltersUtil(filters: filterController.state);
        final userIsBlocked = filtersUtil.userIsBlocked(widget.accountId);
        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Container(
              color: Colors.white,
              child: !userIsBlocked
                  ? NestedScrollView(
                      headerSliverBuilder:
                          (BuildContext context, bool innerBoxIsScrolled) {
                        return [
                          SliverList(
                            delegate: SliverChildListDelegate(
                              [
                                UserPageMainInfo(
                                  accountIdOfUser: widget.accountId,
                                  userIsBlocked: userIsBlocked,
                                ),
                                SizedBox(height: 10.h),
                                if (!userIsBlocked)
                                  TabBar(
                                    enableFeedback: true,
                                    dividerColor: Colors.black.withOpacity(.1),
                                    controller: _tabController,
                                    tabs: const [
                                      Tab(text: 'Posts'),
                                      Tab(text: 'NFTs'),
                                      Tab(text: 'Widgets'),
                                    ],
                                  ),
                                SizedBox(height: 10.h),
                              ],
                            ),
                          ),
                        ];
                      },
                      body: TabBarView(
                        controller: _tabController,
                        children: [
                          UserPostsView(
                            accountIdOfUser: widget.accountId,
                          ),
                          NftsView(
                            accountIdOfUser: widget.accountId,
                          ),
                          WidgetsView(
                            accountIdOfUser: widget.accountId,
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                        UserPageMainInfo(
                          accountIdOfUser: widget.accountId,
                          userIsBlocked: userIsBlocked,
                        ),
                        SizedBox(height: 30.h),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: NEARColors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 80,
                            color: NEARColors.slate,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        const Center(
                          child: Text(
                            "User is blocked",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: NEARColors.red,
                            ),
                          ),
                        ),
                        SizedBox(height: 30.h),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
