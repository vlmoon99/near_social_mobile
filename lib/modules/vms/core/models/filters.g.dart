// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Filters _$FiltersFromJson(Map<String, dynamic> json) => Filters(
      status: $enumDecodeNullable(_$FilterLoadStatusEnumMap, json['status']) ??
          FilterLoadStatus.initial,
      blockedAccounts: (json['blockedAccounts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hidedPosts: (json['hidedPosts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hidedAllPostsAccounts: (json['hidedAllPostsAccounts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$FiltersToJson(Filters instance) => <String, dynamic>{
      'status': _$FilterLoadStatusEnumMap[instance.status]!,
      'blockedAccounts': instance.blockedAccounts,
      'hidedPosts': instance.hidedPosts,
      'hidedAllPostsAccounts': instance.hidedAllPostsAccounts,
    };

const _$FilterLoadStatusEnumMap = {
  FilterLoadStatus.initial: 'initial',
  FilterLoadStatus.loading: 'loading',
  FilterLoadStatus.loaded: 'loaded',
};
