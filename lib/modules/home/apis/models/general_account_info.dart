// ignore_for_file: hash_and_equals

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
part 'general_account_info.g.dart';

@JsonSerializable()
class GeneralAccountInfo extends Equatable {
  final String accountId;
  final String name;
  final String description;
  final Map<String, dynamic> linktree;
  final List<String> tags;
  final String profileImageLink;
  final String backgroundImageLink;

  const GeneralAccountInfo({
    required this.accountId,
    required this.name,
    required this.description,
    required this.linktree,
    required this.tags,
    required this.profileImageLink,
    required this.backgroundImageLink,
  });

  factory GeneralAccountInfo.fromJson(Map<String, dynamic> json) =>
      _$GeneralAccountInfoFromJson(json);

  Map<String, dynamic> toJson() => _$GeneralAccountInfoToJson(this);

  @override
  List<Object?> get props => [
        accountId,
        name,
        description,
        linktree,
        tags,
        profileImageLink,
        backgroundImageLink
      ];

  @override
  bool? get stringify => true;
}
