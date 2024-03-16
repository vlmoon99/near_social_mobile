import 'package:json_annotation/json_annotation.dart';

part 'qr_auth_info.g.dart'; // This is the generated file, name it accordingly

@JsonSerializable()
class QRAuthInfo {
  final String accountId;
  final String secretKey;

  QRAuthInfo(this.accountId, this.secretKey);

  factory QRAuthInfo.fromJson(Map<String, dynamic> json) =>
      _$QRAuthInfoFromJson(json);

  Map<String, dynamic> toJson() => _$QRAuthInfoToJson(this);

  @override
  String toString() =>
      'QRAuthInfo(accountId: $accountId, secretKey: $secretKey)';
}
