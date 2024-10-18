// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'general_account_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneralAccountInfo _$GeneralAccountInfoFromJson(Map<String, dynamic> json) =>
    GeneralAccountInfo(
      accountId: json['accountId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      linktree: json['linktree'] as Map<String, dynamic>,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      profileImageLink: json['profileImageLink'] as String,
      backgroundImageLink: json['backgroundImageLink'] as String,
    );

Map<String, dynamic> _$GeneralAccountInfoToJson(GeneralAccountInfo instance) =>
    <String, dynamic>{
      'accountId': instance.accountId,
      'name': instance.name,
      'description': instance.description,
      'linktree': instance.linktree,
      'tags': instance.tags,
      'profileImageLink': instance.profileImageLink,
      'backgroundImageLink': instance.backgroundImageLink,
    };
