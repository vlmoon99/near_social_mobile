// ignore_for_file: hash_and_equals

import 'package:flutter/foundation.dart';

class GeneralAccountInfo {
  final String accountId;
  final String name;
  final String description;
  final Map<String, dynamic> linktree;
  final List<String> tags;
  final String profileImageLink;
  final String backgroundImageLink;

  GeneralAccountInfo(
      {required this.accountId,
      required this.name,
      required this.description,
      required this.linktree,
      required this.tags,
      required this.profileImageLink,
      required this.backgroundImageLink});

  @override
  operator ==(Object other) =>
      other is GeneralAccountInfo &&
      other.accountId == accountId &&
      other.name == name &&
      other.description == description &&
      mapEquals(other.linktree, linktree) &&
      listEquals(other.tags, tags) &&
      other.profileImageLink == profileImageLink &&
      other.backgroundImageLink == backgroundImageLink;
}
