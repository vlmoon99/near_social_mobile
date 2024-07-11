import 'package:flutter/material.dart' hide Notification;
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/modules/home/apis/models/notification.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/loading_page_with_after_navigation.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';
import 'package:near_social_mobile/utils/date_to_string.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
  });

  final Notification notification;

  bool get postOpeningNotification {
    return notification.notificationType.type == NotificationTypes.like ||
        notification.notificationType.type == NotificationTypes.repost ||
        notification.notificationType.type == NotificationTypes.comment;
  }

  String getFullActionDescription(Notification notification) {
    switch (notification.notificationType.type) {
      case NotificationTypes.mention:
        return "mentioned you in ${notification.notificationType.data["path"]}";
      case NotificationTypes.star:
        return "starred your ${notification.notificationType.data["path"]}";
      case NotificationTypes.poke:
        return "poked you";
      case NotificationTypes.like:
        return "liked your post ${notification.notificationType.data["blockHeight"]}";
      case NotificationTypes.comment:
        return "commented your post ${notification.notificationType.data["blockHeight"]}";
      case NotificationTypes.follow:
        return "followed you";
      case NotificationTypes.unfollow:
        return "unfollowed you";
      case NotificationTypes.repost:
        return "reposted your post ${notification.notificationType.data["blockHeight"]}";
      case NotificationTypes.unknown:
        return "unknown";
    }
  }

  Future<void> loadPostToTempPostsList() async {
    final UserListController userListController =
        Modular.get<UserListController>();
    final AuthController authController = Modular.get<AuthController>();
    final PostsController postsController = Modular.get<PostsController>();

    await userListController.loadAndAddGeneralAccountInfoIfNotExists(
        accountId: authController.state.accountId);

    final fullAccountInfo = userListController.state
        .getUserByAccountId(accountId: authController.state.accountId);

    await postsController.loadAndAddSinglePostIfNotExistToTempList(
      accountInfo: fullAccountInfo.generalAccountInfo,
      blockHeight: notification.notificationType.data["blockHeight"],
    );
  }

  Future<void> navigateToAuthorPage() async {
    await Modular.get<UserListController>().addGeneralAccountInfoIfNotExists(
      generalAccountInfo: notification.authorInfo,
    );
    Modular.to.pushNamed(
        ".${Routes.home.userPage}?accountId=${notification.authorInfo.accountId}");
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0).r,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0).r,
        onTap: () async {
          HapticFeedback.lightImpact();
          if (!postOpeningNotification) {
            await navigateToAuthorPage();
            return;
          }
          final AuthController authController = Modular.get<AuthController>();
          Navigator.push(
            Modular.routerDelegate.navigatorKey.currentContext!,
            MaterialPageRoute(
              builder: (context) => LoadingPageWithNavigation(
                function: () async {
                  await loadPostToTempPostsList();
                },
                route:
                    ".${Routes.home.postPage}?accountId=${authController.state.accountId}&blockHeight=${notification.notificationType.data["blockHeight"]}&postsViewMode=${PostsViewMode.temporary.index}",
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15).r,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await navigateToAuthorPage();
                    },
                    child: Container(
                      width: 40.h,
                      height: 40.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10).r,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: NearNetworkImage(
                        imageUrl: notification.authorInfo.profileImageLink,
                        errorPlaceholder:
                            Image.asset(NearAssets.widgetPlaceholder),
                        placeholder: Image.asset(NearAssets.widgetPlaceholder),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.h),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () async {
                            await navigateToAuthorPage();
                          },
                          child: Text(
                            notification.authorInfo.name != ""
                                ? notification.authorInfo.name
                                : "@${notification.authorInfo.accountId}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Text(getFullActionDescription(notification)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_filled,
                              size: 12.h,
                              color: NEARColors.gray,
                            ),
                            SizedBox(width: 5.h),
                            Text(
                              formatDateDependingOnCurrentTime(
                                  notification.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
