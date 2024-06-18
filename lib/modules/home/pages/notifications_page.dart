import 'package:flutter/material.dart' hide Notification;
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/modules/home/apis/models/notification.dart';
import 'package:near_social_mobile/modules/home/vms/notifications/notifications_controller.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool allNotificationsLoaded = false;
  bool moreNotificationsLoading = false;

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
        return "reposter your post ${notification.notificationType.data["blockHeight"]}";
      case NotificationTypes.unknown:
        return "unknown";
    }
  }

  @override
  void didChangeDependencies() {
    final NotificationsController notificationsController =
        Modular.get<NotificationsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (notificationsController.state.status ==
          NotificationsLoadingState.initial) {
        final AuthController authController = Modular.get<AuthController>();
        final accountId = authController.state.accountId;
        notificationsController.loadNotifications(accountId: accountId);
      }
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final NotificationsController notificationsController =
        Modular.get<NotificationsController>();
    return StreamBuilder<Notifications>(
      stream: notificationsController.stream,
      builder: (context, snapshot) {
        if (notificationsController.state.status !=
            NotificationsLoadingState.loaded) {
          return const Center(
            child: SpinnerLoadingIndicator(),
          );
        }
        return RefreshIndicator.adaptive(
          onRefresh: () async {
            final AuthController authController = Modular.get<AuthController>();
            final accountId = authController.state.accountId;
            return notificationsController.loadNotifications(
              accountId: accountId,
              loadingIndicator: false,
            );
          },
          child: ListView.builder(
            itemBuilder: (context, index) {
              if (index == notificationsController.state.notifications.length) {
                return RPadding(
                  padding: const EdgeInsets.all(20),
                  child: moreNotificationsLoading
                      ? const Center(child: SpinnerLoadingIndicator())
                      : ElevatedButton(
                          onPressed: allNotificationsLoaded
                              ? null
                              : () async {
                                  HapticFeedback.lightImpact();
                                  try {
                                    setState(() {
                                      moreNotificationsLoading = true;
                                    });
                                    final AuthController authController =
                                        Modular.get<AuthController>();
                                    final accountId =
                                        authController.state.accountId;
                                    final moreNotifications =
                                        await notificationsController
                                            .loadMoreNotifications(
                                      accountId: accountId,
                                    );
                                    if (moreNotifications.isEmpty) {
                                      setState(() {
                                        allNotificationsLoaded = true;
                                      });
                                    }
                                  } catch (err) {
                                    rethrow;
                                  } finally {
                                    setState(() {
                                      moreNotificationsLoading = false;
                                    });
                                  }
                                },
                          child: allNotificationsLoaded
                              ? const Text("No more notifications")
                              : const Text("Load more notifications"),
                        ),
                );
              }
              final notification =
                  notificationsController.state.notifications[index];
              return ListTile(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await Modular.get<UserListController>()
                      .addGeneralAccountInfoIfNotExists(
                          generalAccountInfo: notification.authorInfo);
                  Modular.to.pushNamed(
                    ".${Routes.home.userPage}?accountId=${notification.authorInfo.accountId}",
                  );
                },
                leading: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: NearNetworkImage(
                    imageUrl: notification.authorInfo.profileImageLink,
                    errorPlaceholder: Image.asset(
                      NearAssets.standartAvatar,
                      fit: BoxFit.cover,
                    ),
                    placeholder: Stack(
                      children: [
                        Image.asset(
                          NearAssets.standartAvatar,
                          fit: BoxFit.cover,
                        ),
                        const Positioned.fill(
                          child: CircularProgressIndicator(
                            strokeWidth: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                title: Text.rich(
                  TextSpan(text: notification.authorInfo.name, children: [
                    TextSpan(
                      text: " @${notification.authorInfo.accountId}",
                      style: const TextStyle(color: Colors.grey),
                    )
                  ]),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getFullActionDescription(notification),
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      DateFormat('hh:mm a MMM dd, yyyy')
                          .format(notification.date),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.sp,
                      ),
                    )
                  ],
                ),
              );
            },
            itemCount: notificationsController.state.notifications.length + 1,
          ),
        );
      },
    );
  }
}
