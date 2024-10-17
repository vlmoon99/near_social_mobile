import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:near_social_mobile/modules/home/apis/models/follower.dart';
import 'package:near_social_mobile/modules/home/apis/models/general_account_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/near_widget_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/nft.dart';

part 'user_list_state.g.dart';

enum UserListState { initial, loading, loaded }

@JsonSerializable()
class UsersList extends Equatable {
  final UserListState loadingState;
  final Map<String, FullUserInfo> users;

  const UsersList(
      {this.loadingState = UserListState.initial, this.users = const {}});

  UsersList copyWith(
      {UserListState? loadingState, Map<String, FullUserInfo>? users}) {
    return UsersList(
      loadingState: loadingState ?? this.loadingState,
      users: users ?? this.users,
    );
  }

  FullUserInfo getUserByAccountId({required String accountId}) {
    return users[accountId]!;
  }

  Map<String, dynamic> toJson() => _$UsersListToJson(this);

  factory UsersList.fromJson(Map<String, dynamic> json) =>
      _$UsersListFromJson(json);

  @override
  List<Object?> get props => [loadingState, users];

  @override
  bool? get stringify => true;
}

class FullUserInfo extends Equatable {
  final GeneralAccountInfo generalAccountInfo;
  final List<Nft>? nfts;
  final List<NearWidgetInfo>? widgetList;
  final List<Follower>? followers;
  final List<Follower>? followings;
  final List<String>? userTags;

  const FullUserInfo({
    required this.generalAccountInfo,
    this.nfts,
    this.widgetList,
    this.followers,
    this.followings,
    this.userTags,
  });

  FullUserInfo copyWith(
      {GeneralAccountInfo? generalAccountInfo,
      List<Nft>? nfts,
      List<NearWidgetInfo>? widgetList,
      List<Follower>? followers,
      List<Follower>? followings,
      List<String>? userTags}) {
    return FullUserInfo(
      generalAccountInfo: generalAccountInfo ?? this.generalAccountInfo,
      nfts: nfts ?? this.nfts,
      widgetList: widgetList ?? this.widgetList,
      followers: followers ?? this.followers,
      followings: followings ?? this.followings,
      userTags: userTags ?? this.userTags,
    );
  }

  bool get allMetadataLoaded {
    return followers != null && followings != null && userTags != null;
  }

  Map<String, dynamic> toJson() {
    return {'generalAccountInfo': generalAccountInfo.toJson()};
  }

  factory FullUserInfo.fromJson(Map<String, dynamic> json) {
    return FullUserInfo(
      generalAccountInfo:
          GeneralAccountInfo.fromJson(json['generalAccountInfo']),
    );
  }

  @override
  List<Object?> get props =>
      [generalAccountInfo, nfts, widgetList, followers, followings, userTags];

  @override
  bool? get stringify => true;
}
