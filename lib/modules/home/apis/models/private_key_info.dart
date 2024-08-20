import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'private_key_info.g.dart';

@JsonSerializable()
class PrivateKeyInfo {
  final String publicKey;
  final String privateKey;
  final String privateKeyInNearApiJsFormat;
  final PrivateKeyTypeInfo privateKeyTypeInfo;

  PrivateKeyInfo({
    required this.publicKey,
    required this.privateKey,
    required this.privateKeyInNearApiJsFormat,
    required this.privateKeyTypeInfo,
  });

  factory PrivateKeyInfo.fromJson(Map<String, dynamic> json) =>
      _$PrivateKeyInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PrivateKeyInfoToJson(this);

  @override
  String toString() {
    return 'PrivateKeyInfo{publicKey: $publicKey, privateKey: $privateKey, privateKeyInNearApiJsFormat: $privateKeyInNearApiJsFormat, privateKeyTypeInfo: $privateKeyTypeInfo}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivateKeyInfo &&
          runtimeType == other.runtimeType &&
          publicKey == other.publicKey &&
          privateKey == other.privateKey &&
          privateKeyInNearApiJsFormat == other.privateKeyInNearApiJsFormat &&
          privateKeyTypeInfo == other.privateKeyTypeInfo;
}

enum PrivateKeyType { FullAccess, FunctionCall }

@JsonSerializable()
class PrivateKeyTypeInfo {
  final PrivateKeyType type;
  String? receiverId;
  List<String>? methodNames;

  PrivateKeyTypeInfo({
    required this.type,
    this.receiverId,
    this.methodNames,
  });

  factory PrivateKeyTypeInfo.fromJson(Map<String, dynamic> json) =>
      _$PrivateKeyTypeInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PrivateKeyTypeInfoToJson(this);

  @override
  String toString() {
    return 'PrivateKeyTypeInfo{type: $type, receiverId: $receiverId, methodNames: $methodNames}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivateKeyTypeInfo &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          receiverId == other.receiverId &&
          listEquals(methodNames, other.methodNames);
}
