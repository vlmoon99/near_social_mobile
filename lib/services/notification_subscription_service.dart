import 'dart:async';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/modules/home/vms/notifications/notifications_controller.dart';
import 'package:near_social_mobile/services/firebase/notifications_project/firebase_notifications.dart';
import 'package:near_social_mobile/services/local_notification_service.dart';

class NotificationSubscriptionService extends Disposable {
  StreamSubscription<RemoteMessage>? subscription;

  Future<void> subscribeToNotifications(String accountId) async {
    await FirebaseNotificationService.subscribeToNotifications(accountId);
    subscription = FirebaseMessaging.onMessage.distinct().listen(
      (RemoteMessage message) {
        LocalNotificationService.showNotificationOnForeground(
          LocalNotificationMessage(
            message.notification?.title,
            message.notification?.body,
            {},
          ),
        );
        try {
          Modular.get<NotificationsController>().loadNotifications(
            accountId: accountId,
            loadingIndicator: false,
          );
        } catch (err) {
          log(err.toString());
        }
      },
    );
  }

  Future<void> unsubscribeFromNotifications(String accountId) async {
    FirebaseNotificationService.turnOffNotifications(accountId);
    subscription?.cancel();
  }

  @override
  void dispose() {
    subscription?.cancel();
  }
}
