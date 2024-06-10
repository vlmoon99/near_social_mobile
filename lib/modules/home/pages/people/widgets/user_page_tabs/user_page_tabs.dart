import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/user_page_tabs/tabs/user_nfts.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/user_page_tabs/tabs/user_posts.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/user_page_tabs/tabs/user_widgets.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';

enum UserPageTab { posts, nfts, widgets }

class UserPageTabs extends StatefulWidget {
  const UserPageTabs({super.key, required this.accountIdOfUser});

  final String accountIdOfUser;

  @override
  State<UserPageTabs> createState() => _UserPageTabsState();
}

class _UserPageTabsState extends State<UserPageTabs> {
  int tabIndex = UserPageTab.posts.index;

  @override
  Widget build(BuildContext context) {
    final UserListController userListController =
        Modular.get<UserListController>();
    return Column(
      children: [
        Row(
          children: [
            tabButton(
              name: "Posts",
              choosed: tabIndex == UserPageTab.posts.index,
              onTap: () {
                HapticFeedback.lightImpact();
                if (tabIndex == UserPageTab.posts.index) return;
                setState(() {
                  tabIndex = UserPageTab.posts.index;
                });
              },
            ),
            tabButton(
              name: "NFTs",
              choosed: tabIndex == UserPageTab.nfts.index,
              onTap: () {
                HapticFeedback.lightImpact();
                if (tabIndex == UserPageTab.nfts.index) return;
                if (userListController.state.users
                        .firstWhere((user) =>
                            user.generalAccountInfo.accountId ==
                            widget.accountIdOfUser)
                        .nfts ==
                    null) {
                  SchedulerBinding.instance
                      .addPostFrameCallback((timeStamp) async {
                    await userListController.loadNftsOfAccount(
                        accountIdOfUser: widget.accountIdOfUser);
                  });
                }
                setState(() {
                  tabIndex = UserPageTab.nfts.index;
                });
              },
            ),
            tabButton(
              name: "Widgets",
              choosed: tabIndex == UserPageTab.widgets.index,
              onTap: () {
                HapticFeedback.lightImpact();
                if (tabIndex == UserPageTab.widgets.index) return;
                if (userListController.state.users
                        .firstWhere((user) =>
                            user.generalAccountInfo.accountId ==
                            widget.accountIdOfUser)
                        .widgetList ==
                    null) {
                  SchedulerBinding.instance
                      .addPostFrameCallback((timeStamp) async {
                    await userListController.loadWidgetsOfAccount(
                        accountIdOfUser: widget.accountIdOfUser);
                  });
                }
                setState(() {
                  tabIndex = UserPageTab.widgets.index;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 10.h),
        IndexedStack(
          index: tabIndex,
          children: [
            UserPostsView(accountIdOfUser: widget.accountIdOfUser),
            NftsView(accountIdOfUser: widget.accountIdOfUser),
            WidgetsView(accountIdOfUser: widget.accountIdOfUser),
          ],
        )
      ],
    );
  }

  Widget tabButton({
    required String name,
    required bool choosed,
    required Function() onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            RPadding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                name,
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 2.w,
              color:
                  choosed ? Theme.of(context).primaryColor : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
