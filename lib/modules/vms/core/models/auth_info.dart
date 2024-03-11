import 'package:flutter/foundation.dart';

enum AuthInfoStatus { unauthenticated, authenticated }

@immutable
class AuthInfo {
  final String accountId;
  final String publicKey;
  final String secretKey;
  final String privateKey;
  final AuthInfoStatus status;

  const AuthInfo({
    this.accountId = "",
    this.publicKey = "",
    this.secretKey = "",
    this.privateKey = "",
    this.status = AuthInfoStatus.unauthenticated,
  });

  AuthInfo copyWith({
    String? accountId,
    String? publicKey,
    String? secretKey,
    String? privateKey,
    AuthInfoStatus? status,
  }) {
    return AuthInfo(
      accountId: accountId ?? this.accountId,
      publicKey: publicKey ?? this.publicKey,
      secretKey: secretKey ?? this.secretKey,
      privateKey: privateKey ?? this.privateKey,
      status: status ?? this.status,
    );
  }
}
