import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/pages/notifications/widgets/notification_tile.dart';
import 'package:near_social_mobile/modules/home/vms/notifications/notifications_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool allNotificationsLoaded = false;
  bool moreNotificationsLoading = false;

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
          },
          child: ListView.builder(
            padding: REdgeInsets.symmetric(horizontal: 15).r,
            itemBuilder: (context, index) {
              if (index == notificationsController.state.notifications.length) {
                return RPadding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: moreNotificationsLoading
                      ? const Center(child: SpinnerLoadingIndicator())
                      : notificationsController.state.notifications.isEmpty
                          ? const Center(
                              child: Text(
                                "No notifications",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            )
                          : notificationsController.state.notifications.length <
                                  20
                              ? const SizedBox.shrink()
                              : CustomButton(
                                  onPressed: allNotificationsLoaded
                                      ? null
                                      : () async {
                                          try {
                                            setState(() {
                                              moreNotificationsLoading = true;
                                            });
                                            final AuthController
                                                authController =
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
              return Padding(
                padding: EdgeInsets.only(top: index == 0 ? 5 : 0).r,
                child: NotificationTile(notification: notification),
              );
            },
            itemCount: notificationsController.state.notifications.length + 1,
          ),
        );
      },
    );
  }
}
