import 'package:json_annotation/json_annotation.dart';

part 'authorization_credentials.g.dart'; // This is the generated file, name it accordingly

@JsonSerializable()
class AuthorizationCredentials {
  final String accountId;
  final String secretKey;

  AuthorizationCredentials(this.accountId, this.secretKey);

  factory AuthorizationCredentials.fromJson(Map<String, dynamic> json) =>
      _$AuthorizationCredentialsFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorizationCredentialsToJson(this);

  @override
  String toString() =>
      'AuthorizationCredentials(accountId: $accountId, secretKey: $secretKey)';
}
