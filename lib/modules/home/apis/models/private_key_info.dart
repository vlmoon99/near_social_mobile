import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'private_key_info.g.dart';

@JsonSerializable()
class PrivateKeyInfo extends Equatable {
  final String publicKey;
  final String privateKey;
  final String base58PubKey;
  final PrivateKeyTypeInfo privateKeyTypeInfo;

  const PrivateKeyInfo({
    required this.publicKey,
    required this.privateKey,
    required this.base58PubKey,
    required this.privateKeyTypeInfo,
  });

  factory PrivateKeyInfo.fromJson(Map<String, dynamic> json) =>
      _$PrivateKeyInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PrivateKeyInfoToJson(this);

  @override
  List<Object?> get props => [
        publicKey,
        privateKey,
        base58PubKey,
        privateKeyTypeInfo,
      ];

  @override
  bool? get stringify => true;
}

enum PrivateKeyType { FullAccess, FunctionCall }

@JsonSerializable()
class PrivateKeyTypeInfo extends Equatable {
  final PrivateKeyType type;
  final String? receiverId;
  final List<String>? methodNames;

  const PrivateKeyTypeInfo({
    required this.type,
    this.receiverId,
    this.methodNames,
  });

  factory PrivateKeyTypeInfo.fromJson(Map<String, dynamic> json) =>
      _$PrivateKeyTypeInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PrivateKeyTypeInfoToJson(this);

  @override
  List<Object?> get props => [
        type,
        receiverId,
        methodNames,
      ];

  @override
  bool? get stringify => true;
}
