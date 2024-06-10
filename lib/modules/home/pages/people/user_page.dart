
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/user_page_info.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/user_page_tabs/user_page_tabs.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key, required this.accountId});

  final String accountId;

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final UserListController userListController =
        Modular.get<UserListController>();
    final PostsController postsController = Modular.get<PostsController>();

    if (!userListController.state.users
        .firstWhere(
            (user) => user.generalAccountInfo.accountId == widget.accountId)
        .allMetadataLoaded) {}

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
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
    Modular.get<PostsController>().changePostsChannelToMain(
      widget.accountId,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Modular.get<UserListController>()
                .reloadUserInfo(accountId: widget.accountId)
                .then((_) {
              Modular.get<PostsController>().updatePostsOfAccount(
                postsOfAccountId: widget.accountId,
              );
            });
          },
          child: ListView(
            children: [
              UserPageMainInfo(accountIdOfUser: widget.accountId),
              SizedBox(height: 10.h),
              UserPageTabs(accountIdOfUser: widget.accountId),
            ],
          ),
        ),
      ),
    );
  }
}
