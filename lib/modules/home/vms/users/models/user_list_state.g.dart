// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_list_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsersList _$UsersListFromJson(Map<String, dynamic> json) => UsersList(
      loadingState:
          $enumDecodeNullable(_$UserListStateEnumMap, json['loadingState']) ??
              UserListState.initial,
      users: (json['users'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, FullUserInfo.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
    );

Map<String, dynamic> _$UsersListToJson(UsersList instance) => <String, dynamic>{
      'loadingState': _$UserListStateEnumMap[instance.loadingState]!,
      'users': instance.users,
    };

const _$UserListStateEnumMap = {
  UserListState.initial: 'initial',
  UserListState.loading: 'loading',
  UserListState.loaded: 'loaded',
};
