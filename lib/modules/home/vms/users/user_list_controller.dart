import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:near_social_mobile/modules/home/apis/models/follower.dart';
import 'package:near_social_mobile/modules/home/apis/models/general_account_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/near_widget_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/nft.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:rxdart/rxdart.dart';

class UserListController {
  final NearSocialApi nearSocialApi;

  UserListController({required this.nearSocialApi});

  final BehaviorSubject<UsersList> _streamController =
      BehaviorSubject.seeded(const UsersList());

  Stream<UsersList> get stream => _streamController.stream.distinct();
  UsersList get state => _streamController.value;

  Future<void> loadUsers() async {
    _streamController.add(state.copyWith(loadingState: UserListState.loading));
    try {
      final users = await nearSocialApi.getNearSocialAccountList();
      _streamController.add(
        state.copyWith(
          loadingState: UserListState.loaded,
          users: users
              .map(
                (generalAccountInfo) =>
                    FullUserInfo(generalAccountInfo: generalAccountInfo),
              )
              .toList(),
        ),
      );
    } catch (err) {
      _streamController
          .add(state.copyWith(loadingState: UserListState.initial));
      rethrow;
    }
  }

  Future<void> loadAdditionalMetadata({required String accountId}) async {
    try {
      final indexOfUser = state.users.indexWhere(
        (element) => element.generalAccountInfo.accountId == accountId,
      );

      await nearSocialApi
          .getFollowingsOfAccount(accountId: accountId)
          .then((value) {
        _streamController.add(
          state.copyWith(
            users: List.of(state.users)
              ..[indexOfUser] = state.users[indexOfUser].copyWith(
                followings: value,
              ),
          ),
        );
      });

      await nearSocialApi
          .getFollowersOfAccount(accountId: accountId)
          .then((value) {
        _streamController.add(
          state.copyWith(
            users: List.of(state.users)
              ..[indexOfUser] = state.users[indexOfUser].copyWith(
                followers: value,
              ),
          ),
        );
      });

      await nearSocialApi
          .getUserTagsOfAccount(accountId: accountId)
          .then((value) {
        _streamController.add(
          state.copyWith(
            users: List.of(state.users)
              ..[indexOfUser] = state.users[indexOfUser].copyWith(
                userTags: value,
              ),
          ),
        );
      });
    } catch (err) {
      rethrow;
    }
  }

  Future<void> followAccount({
    required String accountIdToFollow,
    required String accountId,
    required String publicKey,
    required String privateKey,
  }) async {
    final indexOfUser = state.users.indexWhere(
      (element) => element.generalAccountInfo.accountId == accountIdToFollow,
    );
    try {
      _streamController.add(
        state.copyWith(
          users: List.of(state.users)
            ..[indexOfUser] = state.users[indexOfUser].copyWith(
              followers: List.of(state.users[indexOfUser].followers ?? [])
                ..add(Follower(accountId: accountId)),
            ),
        ),
      );
      await nearSocialApi.followAccount(
        accountIdToFollow: accountIdToFollow,
        accountId: accountId,
        publicKey: publicKey,
        privateKey: privateKey,
      );
    } catch (err) {
      _streamController.add(
        state.copyWith(
          users: List.of(state.users)
            ..[indexOfUser] = state.users[indexOfUser].copyWith(
              followers: List.of(state.users[indexOfUser].followers ?? [])
                ..removeWhere((follower) => follower.accountId == accountId),
            ),
        ),
      );
      rethrow;
    }
  }

  Future<void> unfollowAccount({
    required String accountIdToUnfollow,
    required String accountId,
    required String publicKey,
    required String privateKey,
  }) async {
    final indexOfUser = state.users.indexWhere(
      (element) => element.generalAccountInfo.accountId == accountIdToUnfollow,
    );
    try {
      _streamController.add(
        state.copyWith(
          users: List.of(state.users)
            ..[indexOfUser] = state.users[indexOfUser].copyWith(
              followers: List.of(state.users[indexOfUser].followers ?? [])
                ..removeWhere((follower) => follower.accountId == accountId),
            ),
        ),
      );
      await nearSocialApi.unfollowAccount(
        accountIdToUnfollow: accountIdToUnfollow,
        accountId: accountId,
        publicKey: publicKey,
        privateKey: privateKey,
      );
    } catch (err) {
      _streamController.add(
        state.copyWith(
          users: List.of(state.users)
            ..[indexOfUser] = state.users[indexOfUser].copyWith(
              followers: List.of(state.users[indexOfUser].followers ?? [])
                ..add(Follower(accountId: accountId)),
            ),
        ),
      );
      rethrow;
    }
  }

  Future<void> reloadUserInfo({required String accountId}) async {
    final indexOfUser = state.users.indexWhere(
      (element) => element.generalAccountInfo.accountId == accountId,
    );
    try {
      final generalAccountInfo =
          await nearSocialApi.getGeneralAccountInfo(accountId: accountId);
      final user = state.users[indexOfUser];
      _streamController.add(
        state.copyWith(
          users: List.of(state.users)
            ..[indexOfUser] = FullUserInfo(
              generalAccountInfo: generalAccountInfo,
              followers: user.followers,
              followings: user.followings,
              nfts: null,
              userTags: user.userTags,
              widgetList: null,
            ),
        ),
      );
      await loadAdditionalMetadata(accountId: accountId);
    } catch (err) {
      rethrow;
    }
  }

  Future<void> loadNftsOfAccount({required String accountIdOfUser}) async {
    log("loading nfts");
    final indexOfUser = state.users.indexWhere(
      (element) => element.generalAccountInfo.accountId == accountIdOfUser,
    );
    try {
      final nfts = await nearSocialApi.getNftsOfAccount(
          accountIdOfUser: accountIdOfUser);
      _streamController.add(
        state.copyWith(
          users: List.of(state.users)
            ..[indexOfUser] = state.users[indexOfUser].copyWith(
              nfts: nfts,
            ),
        ),
      );
    } catch (err) {
      rethrow;
    }
  }

  Future<void> loadWidgetsOfAccount({required String accountIdOfUser}) async {
    log("loading widgets");
    final indexOfUser = state.users.indexWhere(
      (element) => element.generalAccountInfo.accountId == accountIdOfUser,
    );
    try {
      final widgetList = await nearSocialApi.getWidgetsList(
        accountId: accountIdOfUser,
      );
      _streamController.add(
        state.copyWith(
          users: List.of(state.users)
            ..[indexOfUser] = state.users[indexOfUser].copyWith(
              widgetList: widgetList,
            ),
        ),
      );
    } catch (err) {
      rethrow;
    }
  }
}

enum UserListState { initial, loading, loaded }

class UsersList {
  final UserListState loadingState;
  final List<FullUserInfo> users;

  const UsersList(
      {this.loadingState = UserListState.initial, this.users = const []});

  UsersList copyWith({UserListState? loadingState, List<FullUserInfo>? users}) {
    return UsersList(
      loadingState: loadingState ?? this.loadingState,
      users: users ?? this.users,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsersList &&
          runtimeType == other.runtimeType &&
          loadingState == other.loadingState &&
          listEquals(users, other.users);
}

class FullUserInfo {
  final GeneralAccountInfo generalAccountInfo;
  // final List<Post>? posts;
  final List<Nft>? nfts;
  final List<NearWidgetInfo>? widgetList;
  final List<Follower>? followers;
  final List<Follower>? followings;
  final List<String>? userTags;

  FullUserInfo({
    required this.generalAccountInfo,
    this.nfts,
    this.widgetList,
    this.followers,
    this.followings,
    this.userTags,
  });

  FullUserInfo copyWith({
    GeneralAccountInfo? generalAccountInfo,
    List<Nft>? nfts,
    List<NearWidgetInfo>? widgetList,
    List<Follower>? followers,
    List<Follower>? followings,
    List<String>? userTags,
  }) {
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FullUserInfo &&
          runtimeType == other.runtimeType &&
          generalAccountInfo == other.generalAccountInfo &&
          nfts == other.nfts &&
          listEquals(widgetList, other.widgetList) &&
          listEquals(followers, other.followers) &&
          listEquals(followings, other.followings) &&
          listEquals(userTags, other.userTags);
}