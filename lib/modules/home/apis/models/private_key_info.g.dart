// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'private_key_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivateKeyInfo _$PrivateKeyInfoFromJson(Map<String, dynamic> json) =>
    PrivateKeyInfo(
      publicKey: json['publicKey'] as String,
      privateKey: json['privateKey'] as String,
      base58PubKey: json['base58PubKey'] as String,
      privateKeyTypeInfo: PrivateKeyTypeInfo.fromJson(
          json['privateKeyTypeInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PrivateKeyInfoToJson(PrivateKeyInfo instance) =>
    <String, dynamic>{
      'publicKey': instance.publicKey,
      'privateKey': instance.privateKey,
      'base58PubKey': instance.base58PubKey,
      'privateKeyTypeInfo': instance.privateKeyTypeInfo,
    };

PrivateKeyTypeInfo _$PrivateKeyTypeInfoFromJson(Map<String, dynamic> json) =>
    PrivateKeyTypeInfo(
      type: $enumDecode(_$PrivateKeyTypeEnumMap, json['type']),
      receiverId: json['receiverId'] as String?,
      methodNames: (json['methodNames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PrivateKeyTypeInfoToJson(PrivateKeyTypeInfo instance) =>
    <String, dynamic>{
      'type': _$PrivateKeyTypeEnumMap[instance.type]!,
      'receiverId': instance.receiverId,
      'methodNames': instance.methodNames,
    };

const _$PrivateKeyTypeEnumMap = {
  PrivateKeyType.FullAccess: 'FullAccess',
  PrivateKeyType.FunctionCall: 'FunctionCall',
};
