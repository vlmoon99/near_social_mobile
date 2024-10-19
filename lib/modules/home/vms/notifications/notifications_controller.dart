import 'package:equatable/equatable.dart';
import 'package:near_social_mobile/modules/home/apis/models/notification.dart';
import 'package:rxdart/rxdart.dart' hide Notification;

import '../../apis/near_social.dart';

class NotificationsController {
  final NearSocialApi nearSocialApi;

  NotificationsController({required this.nearSocialApi});

  final BehaviorSubject<Notifications> _streamController =
      BehaviorSubject.seeded(const Notifications());

  Stream<Notifications> get stream => _streamController.stream.distinct();
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
      if (state.status != NotificationsLoadingState.loading) {
        return;
      }
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

  Future<List<Notification>> loadMoreNotifications(
      {required String accountId}) async {
    try {
      final notifications = await nearSocialApi.getNotificationsOfAccount(
        accountId: accountId,
        from: state.notifications.isNotEmpty
            ? state.notifications.last.blockHeight
            : 20,
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

  Future<void> clear() async {
    _streamController.add(const Notifications());
  }
}

enum NotificationsLoadingState { initial, loading, loaded }

class Notifications extends Equatable {
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

  @override
  List<Object?> get props => [status, notifications];

  @override
  bool? get stringify => true;
}
