// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_list_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsersList _$UsersListFromJson(Map<String, dynamic> json) => UsersList(
      loadingState:
          $enumDecodeNullable(_$UserListStateEnumMap, json['loadingState']) ??
              UserListState.initial,
      cachedUsers: (json['cachedUsers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, FullUserInfo.fromJson(e as Map<String, dynamic>)),
      ),
      activeUsers: (json['activeUsers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, FullUserInfo.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$UsersListToJson(UsersList instance) => <String, dynamic>{
      'loadingState': _$UserListStateEnumMap[instance.loadingState]!,
      'cachedUsers': instance.cachedUsers,
      'activeUsers': instance.activeUsers,
    };

const _$UserListStateEnumMap = {
  UserListState.initial: 'initial',
  UserListState.loading: 'loading',
  UserListState.loaded: 'loaded',
};
