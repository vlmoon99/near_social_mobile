import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseNotificationService {
  static Future<void> subscribeToNotifications(String accountId) async {
    if (await isNotificationsForUserRegisteredOnBackend(accountId)) {
      return;
    }

    await loginingOnNotificationBackend();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final token = await FirebaseMessaging.instance.getToken();

    final DocumentReference currentUserReference =
        FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      await currentUserReference.update({
        'subscriptions': FieldValue.arrayUnion([accountId]),
      });
    } catch (err) {
      await subscribeToNotifications(accountId);
      return;
    }

    final isThisAccountIdChannelExist = (await FirebaseFirestore.instance
                .collection('subscriptions_channels')
                .doc(accountId)
                .get())
            .data()
            ?.isNotEmpty ??
        false;

    if (isThisAccountIdChannelExist) {
      await FirebaseFirestore.instance
          .collection('subscriptions_channels')
          .doc(accountId)
          .update({uid: token});
    } else {
      await FirebaseFirestore.instance
          .collection('subscriptions_channels')
          .doc(accountId)
          .set({uid: token});
    }
  }

  static Future<bool> isNotificationsForUserRegisteredOnBackend(
      String accountId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return false;
    }
    final token = await FirebaseMessaging.instance.getToken();
    final data = (await FirebaseFirestore.instance
            .collection('subscriptions_channels')
            .doc(accountId)
            .get())
        .data();
    if (data?[uid] == null) {
      return false;
    } else if (data![uid] == token) {
      return true;
    } else {
      return false;
    }
  }

  static Future<void> loginingOnNotificationBackend() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final userRecord = FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid);
      final userExists = (await userRecord.get()).exists;
      if (userExists) {
        return;
      }
      final userData = {
        "uid": userCredential.user!.uid,
        "createdTime": DateTime.now(),
      };
      await userRecord.set(userData);
    } catch (err) {
      await Future.delayed(
        const Duration(seconds: 1),
        () => loginingOnNotificationBackend(),
      );
    }
  }

  static Future<void> turnOnNotifications(String accountId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final token = await FirebaseMessaging.instance.getToken();
    await FirebaseFirestore.instance
        .collection('subscriptions_channels')
        .doc(accountId)
        .update({uid: token});
  }

  static Future<void> turnOffNotifications(String accountId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('subscriptions_channels')
        .doc(accountId)
        .update({uid: ''});
  }
}
