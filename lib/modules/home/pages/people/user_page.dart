import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/user_page_info.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/user_page_tabs/user_nfts.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/user_page_tabs/user_posts.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/user_page_tabs/user_widgets.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key, required this.accountId});

  final String accountId;

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 3, vsync: this);
  late final Timer _generalProfileInfoTimer;
  Timer? _nftsUpdatingTimer;
  Timer? _widgetsUpdatingTimer;

  @override
  void initState() {
    super.initState();
    final UserListController userListController =
        Modular.get<UserListController>();
    final user = userListController.state
        .getUserByAccountId(accountId: widget.accountId);

    _generalProfileInfoTimer =
        Timer.periodic(const Duration(seconds: 40), (timer) async {
      await Modular.get<UserListController>()
          .reloadUserInfo(accountId: widget.accountId)
          .then((_) {
        Modular.get<PostsController>().updatePostsOfAccount(
          postsOfAccountId: widget.accountId,
        );
      });
    });

    //nft auto update

    //nfts never vere loaded
    if (user.timeOfLastNftsUpdate == null) {
      _nftsUpdatingTimer = Timer.periodic(
        const Duration(minutes: 6),
        (timer) {
          if (user.nfts != null) {
            userListController.loadNftsOfAccount(
              accountId: widget.accountId,
            );
          }
        },
      );
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
              _nftsUpdatingTimer = Timer.periodic(
                const Duration(minutes: 6),
                (timer) {
                  if (user.nfts != null) {
                    userListController.loadNftsOfAccount(
                      accountId: widget.accountId,
                    );
                  }
                },
              );
            },
          );
        },
      );
    }

    if (user.timeOfLastWidgetsUpdate == null) {
      _widgetsUpdatingTimer = Timer.periodic(
        const Duration(minutes: 5),
        (timer) {
          if (user.widgetList != null) {
            userListController.loadWidgetsOfAccount(
              accountId: widget.accountId,
            );
          }
        },
      );
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
              _widgetsUpdatingTimer = Timer.periodic(
                const Duration(minutes: 5),
                (timer) {
                  if (user.widgetList != null) {
                    userListController.loadWidgetsOfAccount(
                      accountId: widget.accountId,
                    );
                  }
                },
              );
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
    final PostsController postsController = Modular.get<PostsController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!userListController.state.users
          .firstWhere(
              (user) => user.generalAccountInfo.accountId == widget.accountId)
          .allMetadataLoaded) {
        userListController
            .loadAdditionalMetadata(accountId: widget.accountId)
            .then((_) {
          postsController.changePostsChannelToAccount(
            widget.accountId,
          );
        });
      } else {
        postsController.changePostsChannelToAccount(
          widget.accountId,
        );
      }
    });
  }

  @override
  void dispose() {
    _generalProfileInfoTimer.cancel();
    _nftsUpdatingTimer?.cancel();
    _widgetsUpdatingTimer?.cancel();
    Modular.get<PostsController>().changePostsChannelToMain(
      widget.accountId,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    UserPageMainInfo(
                      accountIdOfUser: widget.accountId,
                    ),
                    SizedBox(height: 10.h),
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
        ),
      ),
    );
  }
}
