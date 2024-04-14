import 'dart:developer';

import 'package:flutter/material.dart' hide Notification;
import 'package:near_social_mobile/modules/home/apis/models/notification.dart';
import 'package:rxdart/rxdart.dart' hide Notification;

import '../../apis/near_social.dart';

class NotificationsController {
  final NearSocialApi nearSocialApi;

  NotificationsController({required this.nearSocialApi});

  final BehaviorSubject<Notifications> _streamController =
      BehaviorSubject.seeded(const Notifications());

  Stream<Notifications> get stream => _streamController.stream;
  Notifications get state => _streamController.value;

  Future<void> loadNotifications({
    required String accountId,
    bool loadingIndicator = true,
    int? from,
  }) async {
    try {
      if (loadingIndicator) {
        _streamController
            .add(state.copyWith(status: NotificationsLoadingState.loading));
      }
      final notifications = await nearSocialApi.getNotificationsOfAccount(
        accountId: accountId,
        from: from,
      );
      _streamController.add(
        state.copyWith(
          status: NotificationsLoadingState.loaded,
          notifications: notifications,
        ),
      );
    } catch (err) {
      _streamController
          .add(state.copyWith(status: NotificationsLoadingState.initial));
      rethrow;
    }
  }

  Future<List<Notification>> loadMoreNotifications({required String accountId}) async {
    try {
      final notifications = await nearSocialApi.getNotificationsOfAccount(
        accountId: accountId,
        from: state.notifications.last.blockHeight,
      );
      notifications.removeWhere((notification) =>
          notification.blockHeight == state.notifications.last.blockHeight);
      _streamController.add(
        state.copyWith(
          notifications: [...state.notifications, ...notifications],
        ),
      );
      return notifications;
    } catch (err) {
      rethrow;
    }
  }
}

enum NotificationsLoadingState { initial, loading, loaded }

@immutable
class Notifications {
  final NotificationsLoadingState status;
  final List<Notification> notifications;

  const Notifications({
    this.status = NotificationsLoadingState.initial,
    this.notifications = const [],
  });

  Notifications copyWith({
    NotificationsLoadingState? status,
    List<Notification>? notifications,
  }) {
    return Notifications(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
    );
  }
}
