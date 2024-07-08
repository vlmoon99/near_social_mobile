import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/modules/home/apis/models/notification.dart';
import 'package:near_social_mobile/modules/home/vms/notifications/notifications_controller.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
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
  List<Map<String, int>> postsAddedToLoad = [];

  Future<void> loadPostForNotificationTempList(
      Notification notification) async {
    final typeOfNotification = notification.notificationType.type;
    if (!(typeOfNotification == NotificationTypes.like ||
        typeOfNotification == NotificationTypes.repost ||
        typeOfNotification == NotificationTypes.mention)) {
      return;
    }
    final PostsController postsController = Modular.get<PostsController>();
    final pathParts =
        (notification.notificationType.data["path"] as String).split("/");
    final String accountIdOfPost = pathParts.first;
    final int blockHeightOfPost =
        notification.notificationType.data["blockHeight"];

    if (postsAddedToLoad.any(
      (element) =>
          element.keys.first == accountIdOfPost &&
          element.values.first == blockHeightOfPost,
    )) {
      return;
    }

    postsAddedToLoad.add({accountIdOfPost: blockHeightOfPost});

    if (postsController.state.temporaryPosts.any(
      (element) =>
          element.blockHeight == blockHeightOfPost &&
          element.authorInfo.accountId == accountIdOfPost,
    )) {
      return;
    }

    final UserListController userListController =
        Modular.get<UserListController>();

    try {
      if (userListController.state.loadingState == UserListState.loaded) {
        final fullAccountInfo = userListController.state
            .getUserByAccountId(accountId: accountIdOfPost);
        await postsController.loadAndAddSinglePostIfNotExistToTempList(
          accountInfo: fullAccountInfo.generalAccountInfo,
          blockHeight: blockHeightOfPost,
        );
      } else {
        final accountInfo = await userListController.nearSocialApi
            .getGeneralAccountInfo(accountId: accountIdOfPost);

        await postsController.loadAndAddSinglePostIfNotExistToTempList(
          accountInfo: accountInfo,
          blockHeight: blockHeightOfPost,
        );
      }
    } catch (err) {
      postsAddedToLoad.removeWhere(
        (element) =>
            element.keys.first == accountIdOfPost &&
            element.values.first == blockHeightOfPost,
      );
      rethrow;
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
            await notificationsController.loadNotifications(
              accountId: accountId,
              loadingIndicator: false,
            );
            for (var notification
                in notificationsController.state.notifications) {
              loadPostForNotificationTempList(notification);
            }
          },
          child: ListView.builder(
            itemBuilder: (context, index) {
              if (index == notificationsController.state.notifications.length) {
                return RPadding(
                  padding: const EdgeInsets.all(20),
                  child: moreNotificationsLoading
                      ? const Center(child: SpinnerLoadingIndicator())
                      : CustomButton(
                          onPressed: allNotificationsLoaded
                              ? null
                              : () async {
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
                          child: Text(
                            allNotificationsLoaded
                                ? "No more notifications"
                                : "Load more notifications",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                );
              }
              final notification =
                  notificationsController.state.notifications[index];
              loadPostForNotificationTempList(notification);
              return NotificationTile(notification: notification);
            },
            itemCount: notificationsController.state.notifications.length + 1,
          ),
        );
      },
    );
  }
}

class NotificationTile extends StatefulWidget {
  const NotificationTile({
    super.key,
    required this.notification,
  });

  final Notification notification;

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  bool loadingPost = false;

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
    try {
      setState(() {
        loadingPost = true;
      });
      final userListController = Modular.get<UserListController>();
      final AuthController authController = Modular.get<AuthController>();
      final PostsController postsController = Modular.get<PostsController>();

      if (userListController.state.loadingState == UserListState.loaded) {
        final fullAccountInfo = userListController.state
            .getUserByAccountId(accountId: authController.state.accountId);
        await postsController.loadAndAddSinglePostIfNotExistToTempList(
          accountInfo: fullAccountInfo.generalAccountInfo,
          blockHeight: widget.notification.notificationType.data["blockHeight"],
        );
      } else {
        final accountInfo = await userListController.nearSocialApi
            .getGeneralAccountInfo(accountId: authController.state.accountId);

        await postsController.loadAndAddSinglePostIfNotExistToTempList(
          accountInfo: accountInfo,
          blockHeight: widget.notification.notificationType.data["blockHeight"],
        );
      }
    } catch (err) {
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          loadingPost = false;
        });
      }
    }
  }

  bool postIsLoaded(Posts posts) {
    final accountId = Modular.get<AuthController>().state.accountId;
    return posts.temporaryPosts.any(
      (element) =>
          element.blockHeight ==
              widget.notification.notificationType.data["blockHeight"] &&
          element.authorInfo.accountId == accountId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final PostsController postsController = Modular.get<PostsController>();
    return StreamBuilder(
      stream: postsController.stream,
      builder: (context, snapshot) {
        return ListTile(
          onTap: () async {
            await Modular.get<UserListController>()
                .addGeneralAccountInfoIfNotExists(
                    generalAccountInfo: widget.notification.authorInfo);
            Modular.to.pushNamed(
              ".${Routes.home.userPage}?accountId=${widget.notification.authorInfo.accountId}",
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
              imageUrl: widget.notification.authorInfo.profileImageLink,
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
            TextSpan(text: widget.notification.authorInfo.name, children: [
              TextSpan(
                text: " @${widget.notification.authorInfo.accountId}",
                style: const TextStyle(color: Colors.grey),
              )
            ]),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(builder: (context, constraints) {
                return Row(
                  children: [
                    SizedBox(
                      width: constraints.maxWidth * .8,
                      child: Text.rich(
                        softWrap: true,
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  getFullActionDescription(widget.notification),
                              style: TextStyle(fontSize: 16.sp),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (widget.notification.notificationType.type ==
                            NotificationTypes.like ||
                        widget.notification.notificationType.type ==
                            NotificationTypes.repost ||
                        widget.notification.notificationType.type ==
                            NotificationTypes.comment)
                      if (postIsLoaded(postsController.state))
                        IconButton(
                          onPressed: () async {
                            final AuthController authController =
                                Modular.get<AuthController>();
                            await Modular.to.pushNamed(
                              ".${Routes.home.postPage}?accountId=${authController.state.accountId}&blockHeight=${widget.notification.notificationType.data["blockHeight"]}&postsViewMode=${PostsViewMode.temporary.index}",
                            );
                          },
                          icon: const Icon(Icons.open_in_new),
                          style: IconButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        )
                      else
                        const SpinnerLoadingIndicator(
                          size: 20,
                        ),
                    const Spacer(),
                  ],
                );
              }),
              SizedBox(width: 10.w),
              Text(
                DateFormat('hh:mm a MMM dd, yyyy')
                    .format(widget.notification.date),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12.sp,
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
