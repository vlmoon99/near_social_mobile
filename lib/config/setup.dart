import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutterchain/flutterchain_lib/services/core/lib_initialization_service.dart';
import 'package:near_social_mobile/services/firebase/notifications_project/firebase_options.dart';
import 'package:near_social_mobile/services/local_notification_service.dart';

Future<void> initOfApp() async {
  await EasyLocalization.ensureInitialized();
  initFlutterChainLib();

  if (!kIsWeb) {
    // init firebase for notifications
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    LocalNotificationService.init();
  } else {
        await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
