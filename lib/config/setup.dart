import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutterchain/flutterchain_lib/services/core/lib_initialization_service.dart';
import 'package:near_social_mobile/modules/home/vms/notifications/notifications_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/services/firebase/notifications_project/firebase_options.dart';
import 'package:near_social_mobile/services/local_notification_service.dart';

Future<void> initOfApp() async {
  await EasyLocalization.ensureInitialized();
  initFlutterChainLib();

  // init firebase for notifications
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  LocalNotificationService.init();
  FirebaseMessaging.onMessage.distinct().listen(
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
          accountId: Modular.get<AuthController>().state.accountId,
          loadingIndicator: false,
        );
      } catch (err) {
        log(err.toString());
      }
    },
  );
}
