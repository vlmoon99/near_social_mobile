// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_auth_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QRAuthInfo _$QRAuthInfoFromJson(Map<String, dynamic> json) => QRAuthInfo(
      json['accountId'] as String,
      json['secretKey'] as String,
    );

Map<String, dynamic> _$QRAuthInfoToJson(QRAuthInfo instance) =>
    <String, dynamic>{
      'accountId': instance.accountId,
      'secretKey': instance.secretKey,
    };
