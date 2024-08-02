import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/pages/notifications/widgets/notification_tile.dart';
import 'package:near_social_mobile/modules/home/vms/notifications/notifications_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/filter_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';
import 'package:rxdart/rxdart.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool allNotificationsLoaded = false;
  bool moreNotificationsLoading = false;
  final _scrollController = ScrollController();

  Future<void> loadMoreNotifications() async {
    final NotificationsController notificationsController =
        Modular.get<NotificationsController>();
    final AuthController authController = Modular.get<AuthController>();
    try {
      if (!mounted) return;

      setState(() {
        moreNotificationsLoading = true;
      });

      final moreNotifications =
          await notificationsController.loadMoreNotifications(
        accountId: authController.state.accountId,
      );
      if (moreNotifications.isEmpty) {
        if (mounted) {
          setState(() {
            allNotificationsLoaded = true;
          });
        }
      }
    } catch (err) {
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          moreNotificationsLoading = false;
        });
      }
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
    final AuthController authController = Modular.get<AuthController>();
    final NotificationsController notificationsController =
        Modular.get<NotificationsController>();
    final FilterController filterController = Modular.get<FilterController>();
    return StreamBuilder(
      stream:
          Rx.merge([notificationsController.stream, filterController.stream]),
      builder: (context, snapshot) {
        if (notificationsController.state.status !=
            NotificationsLoadingState.loaded) {
          return const Center(
            child: SpinnerLoadingIndicator(),
          );
        }
        return RefreshIndicator.adaptive(
          onRefresh: () async {
            await notificationsController.loadNotifications(
              accountId: authController.state.accountId,
              loadingIndicator: false,
            );
          },
          child: Builder(builder: (context) {
            final filterUtil = FiltersUtil(filters: filterController.state);
            final notifications = notificationsController.state.notifications
                .where((notification) => !filterUtil
                    .userIsBlocked(notification.authorInfo.accountId))
                .toList();

            if (notifications.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) {
                  if (notificationsController.state.status ==
                          NotificationsLoadingState.loaded &&
                      !moreNotificationsLoading &&
                      !allNotificationsLoaded) {
                    loadMoreNotifications();
                  }
                },
              );

              return const Center(
                child: Text(
                  "No notifications",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: REdgeInsets.symmetric(horizontal: 15).r,
              itemBuilder: (context, index) {
                if (index == 0) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) {
                      if (_scrollController.position.maxScrollExtent == 0 &&
                          notificationsController.state.status ==
                              NotificationsLoadingState.loaded &&
                          !moreNotificationsLoading &&
                          !allNotificationsLoaded) {
                        loadMoreNotifications();
                      }
                    },
                  );
                }

                if (index == notifications.length) {
                  return RPadding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: moreNotificationsLoading
                        ? const Center(child: SpinnerLoadingIndicator())
                        : (notifications.length < 20 && allNotificationsLoaded)
                            ? const SizedBox.shrink()
                            : CustomButton(
                                onPressed: allNotificationsLoaded
                                    ? null
                                    : () async {
                                        loadMoreNotifications();
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
                final notification = notifications[index];
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 5 : 0).r,
                  child: NotificationTile(notification: notification),
                );
              },
              itemCount: notifications.length + 1,
            );
          }),
        );
      },
    );
  }
}
