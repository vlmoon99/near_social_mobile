import 'package:flutter/foundation.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';

enum AuthInfoStatus { unauthenticated, authenticated }

@immutable
class AuthInfo {
  final String accountId;
  final String publicKey;
  final String secretKey;
  final String privateKey;
  final AuthInfoStatus status;
  final Map<String, PrivateKeyInfo> additionalStoredKeys;

  const AuthInfo({
    this.accountId = "",
    this.publicKey = "",
    this.secretKey = "",
    this.privateKey = "",
    this.status = AuthInfoStatus.unauthenticated,
    this.additionalStoredKeys = const {},
  });

  AuthInfo copyWith({
    String? accountId,
    String? publicKey,
    String? secretKey,
    String? privateKey,
    AuthInfoStatus? status,
    Map<String, PrivateKeyInfo>? additionalStoredKeys,
  }) {
    return AuthInfo(
      accountId: accountId ?? this.accountId,
      publicKey: publicKey ?? this.publicKey,
      secretKey: secretKey ?? this.secretKey,
      privateKey: privateKey ?? this.privateKey,
      status: status ?? this.status,
      additionalStoredKeys: additionalStoredKeys ?? this.additionalStoredKeys,
    );
  }

  @override
  bool operator ==(Object other) => 
      identical(this, other) ||
      other is AuthInfo &&
          runtimeType == other.runtimeType &&
          accountId == other.accountId &&
          publicKey == other.publicKey &&
          secretKey == other.secretKey &&
          privateKey == other.privateKey &&
          status == other.status &&
          mapEquals(additionalStoredKeys, other.additionalStoredKeys);
}
