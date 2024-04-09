import 'package:flutter/foundation.dart';

class NearWidgetInfo {
  final String accountId;
  final String urlName;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> tags;
  final int blockHeight;

  NearWidgetInfo({
    required this.accountId,
    required this.urlName,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.tags,
    required this.blockHeight,
  });

  String get widgetPath => "$accountId/widget/$urlName";

  NearWidgetInfo copyWith({
    String? accountId,
    String? urlName,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? tags,
    int? blockHeight,
  }) {
    return NearWidgetInfo(
      accountId: accountId ?? this.accountId,
      urlName: urlName ?? this.urlName,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      blockHeight: blockHeight ?? this.blockHeight,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearWidgetInfo &&
          runtimeType == other.runtimeType &&
          accountId == other.accountId &&
          urlName == other.urlName &&
          name == other.name &&
          description == other.description &&
          imageUrl == other.imageUrl &&
          blockHeight == other.blockHeight &&
          listEquals(tags, other.tags);
}
