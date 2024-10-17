import 'package:near_social_mobile/modules/home/apis/models/follower.dart';
import 'package:near_social_mobile/modules/home/apis/models/general_account_info.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/home/vms/users/models/user_list_state.dart';
import 'package:rxdart/rxdart.dart';

class UserListController {
  final NearSocialApi nearSocialApi;

  UserListController({
    required this.nearSocialApi,
  });

  final BehaviorSubject<UsersList> _streamController =
      BehaviorSubject.seeded(const UsersList());

  Stream<UsersList> get stream => _streamController.stream.distinct();
  UsersList get state => _streamController.value;

  Future<void> loadUsers() async {
    if (state.loadingState == UserListState.loading) {
      return;
    }
    _streamController.add(state.copyWith(loadingState: UserListState.loading));
    try {
      final generalAccountInfoOfUsers =
          await nearSocialApi.getNearSocialAccountList();
      final Map<String, FullUserInfo> users = {};
      for (var generalAccountInfo in generalAccountInfoOfUsers) {
        users.putIfAbsent(generalAccountInfo.accountId, () {
          return FullUserInfo(generalAccountInfo: generalAccountInfo);
        });
      }

      _streamController.add(
        state.copyWith(
          loadingState: UserListState.loaded,
          users: users,
        ),
      );
    } catch (err) {
      _streamController
          .add(state.copyWith(loadingState: UserListState.initial));
      rethrow;
    }
  }

  Future<void> addGeneralAccountInfoIfNotExists(
      {required GeneralAccountInfo generalAccountInfo}) async {
    _streamController.add(
      state.copyWith(
        users: Map.of(state.users)
          ..[generalAccountInfo.accountId] = FullUserInfo(
            generalAccountInfo: generalAccountInfo,
          ),
      ),
    );
  }

  Future<void> loadAndAddGeneralAccountInfoIfNotExists(
      {required String accountId}) async {
    if (state.users.containsKey(accountId)) {
      return;
    }
    _streamController.add(
      state.copyWith(
        users: Map.of(state.users)
          ..[accountId] = FullUserInfo(
            generalAccountInfo:
                await nearSocialApi.getGeneralAccountInfo(accountId: accountId),
          ),
      ),
    );
  }

  Future<void> loadAdditionalMetadata({required String accountId}) async {
    try {
      final List<Follower> followings =
          await nearSocialApi.getFollowingsOfAccount(accountId: accountId);
      final List<Follower> followers =
          await nearSocialApi.getFollowersOfAccount(accountId: accountId);
      final List<String> userTags =
          await nearSocialApi.getUserTagsOfAccount(accountId: accountId);

      _streamController.add(
        state.copyWith(
          users: Map.of(state.users)
            ..[accountId] = state.users[accountId]!.copyWith(
              followings: followings,
              followers: followers,
              userTags: userTags,
            ),
        ),
      );
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
    try {
      _streamController.add(
        state.copyWith(
          users: Map.of(state.users)
            ..[accountIdToFollow] = state.users[accountIdToFollow]!.copyWith(
              followers:
                  List.of(state.users[accountIdToFollow]?.followers ?? [])
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
          users: Map.of(state.users)
            ..[accountIdToFollow] = state.users[accountIdToFollow]!.copyWith(
              followers: List.of(
                  state.users[accountIdToFollow]?.followers ?? [])
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
    try {
      _streamController.add(
        state.copyWith(
          users: Map.of(state.users)
            ..[accountIdToUnfollow] =
                state.users[accountIdToUnfollow]!.copyWith(
              followers: List.of(
                  state.users[accountIdToUnfollow]?.followers ?? [])
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
          users: Map.of(state.users)
            ..[accountIdToUnfollow] =
                state.users[accountIdToUnfollow]!.copyWith(
              followers:
                  List.of(state.users[accountIdToUnfollow]?.followers ?? [])
                    ..add(Follower(accountId: accountId)),
            ),
        ),
      );
      rethrow;
    }
  }

  Future<void> reloadUserInfo({required String accountId}) async {
    try {
      final generalAccountInfo =
          await nearSocialApi.getGeneralAccountInfo(accountId: accountId);
      final List<Follower> followings =
          await nearSocialApi.getFollowingsOfAccount(accountId: accountId);
      final List<Follower> followers =
          await nearSocialApi.getFollowersOfAccount(accountId: accountId);
      final List<String> userTags =
          await nearSocialApi.getUserTagsOfAccount(accountId: accountId);
      final user = state.users[accountId];
      _streamController.add(
        state.copyWith(
          users: Map.of(state.users)
            ..[accountId] = user!.copyWith(
              generalAccountInfo: generalAccountInfo,
              followings: followings,
              followers: followers,
              userTags: userTags,
            ),
        ),
      );
    } catch (err) {
      rethrow;
    }
  }

  Future<void> loadNftsOfAccount({required String accountId}) async {
    try {
      final nfts =
          await nearSocialApi.getNftsOfAccount(accountIdOfUser: accountId);
      _streamController.add(
        state.copyWith(
          users: Map.of(state.users)
            ..[accountId] = state.users[accountId]!.copyWith(
              nfts: nfts,
            ),
        ),
      );
    } catch (err) {
      rethrow;
    }
  }

  Future<void> loadWidgetsOfAccount({required String accountId}) async {
    try {
      final widgetList = await nearSocialApi.getWidgetsList(
        accountId: accountId,
      );
      _streamController.add(
        state.copyWith(
          users: Map.of(state.users)
            ..[accountId] = state.users[accountId]!.copyWith(
              widgetList: widgetList,
            ),
        ),
      );
    } catch (err) {
      rethrow;
    }
  }
}
