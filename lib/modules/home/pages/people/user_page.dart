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

class UserPage extends StatefulWidget {
  const UserPage({super.key, required this.accountId});

  final String accountId;

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> with TickerProviderStateMixin {
  late final _tabController = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    final UserListController userListController =
        Modular.get<UserListController>();
    final user = userListController.state
        .getUserByAccountId(accountId: widget.accountId);

    final PostsController postsController = Modular.get<PostsController>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!user.allMetadataLoaded) {
        await userListController.loadAdditionalMetadata(
            accountId: widget.accountId);
        if (postsController.state.postsOfAccounts[widget.accountId] == null) {
          await postsController.loadPosts(
            postsViewMode: PostsViewMode.account,
            postsOfAccountId: widget.accountId,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          backgroundColor: NEARColors.black,
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
                        physics: const NeverScrollableScrollPhysics(),
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
