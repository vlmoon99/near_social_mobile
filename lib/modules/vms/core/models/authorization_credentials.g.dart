// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authorization_credentials.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthorizationCredentials _$AuthorizationCredentialsFromJson(
        Map<String, dynamic> json) =>
    AuthorizationCredentials(
      json['accountId'] as String,
      json['secretKey'] as String,
    );

Map<String, dynamic> _$AuthorizationCredentialsToJson(
        AuthorizationCredentials instance) =>
    <String, dynamic>{
      'accountId': instance.accountId,
      'secretKey': instance.secretKey,
    };
