import 'package:equatable/equatable.dart';
import 'package:near_social_mobile/modules/home/apis/models/general_account_info.dart';

class Notification extends Equatable {
  final GeneralAccountInfo authorInfo;
  final int blockHeight;
  final DateTime date;
  final NotificationType notificationType;
  const Notification({
    required this.authorInfo,
    required this.blockHeight,
    required this.date,
    required this.notificationType,
  });

  @override
  List<Object?> get props => [
        authorInfo,
        blockHeight,
        date,
        notificationType,
      ];

  @override
  bool? get stringify => true;
}

enum NotificationTypes {
  star,
  poke,
  like,
  comment,
  follow,
  unfollow,
  mention,
  repost,
  unknown
}

class NotificationType extends Equatable {
  final NotificationTypes type;
  final Map<String, dynamic> data;

  const NotificationType({
    required this.type,
    required this.data,
  });

  @override
  List<Object?> get props => [type, data];
      
  @override
  bool? get stringify => true;
}

NotificationTypes getNotificationType(String type) {
  switch (type) {
    case "star":
      return NotificationTypes.star;
    case "poke":
      return NotificationTypes.poke;
    case "like":
      return NotificationTypes.like;
    case "comment":
      return NotificationTypes.comment;
    case "follow":
      return NotificationTypes.follow;
    case "unfollow":
      return NotificationTypes.unfollow;
    case "mention":
      return NotificationTypes.mention;
    case "repost":
      return NotificationTypes.repost;
    default:
      return NotificationTypes.unknown;
  }
}

Map<String, dynamic> getNotificationData(
    dynamic rawData, NotificationTypes type) {
  switch (type) {
    case NotificationTypes.star:
      return {
        "path": rawData?["path"] ?? "",
      };
    case NotificationTypes.poke:
      return {};
    case NotificationTypes.like:
      return {
        "path": rawData?["path"] ?? "",
        "blockHeight": rawData?["blockHeight"] ?? 0,
      };
    case NotificationTypes.comment:
      return {
        "path": rawData?["path"] ?? "",
        "blockHeight": rawData?["blockHeight"] ?? 0,
      };
    case NotificationTypes.follow:
      return {};
    case NotificationTypes.unfollow:
      return {};
    case NotificationTypes.mention:
      return {
        "path": rawData?["path"] ?? "",
      };
    case NotificationTypes.repost:
      return {
        "path": rawData?["path"] ?? "",
        "blockHeight": rawData?["blockHeight"] ?? 0,
      };
    default:
      return {};
  }
}
