// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserChat _$UserChatFromJson(Map<String, dynamic> json) => UserChat(
      id: json['id'] as String,
      pubKeys:
          (json['pubKeys'] as List<dynamic>).map((e) => e as String).toList(),
      messages: (json['messages'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
      createAt: DateTime.parse(json['createAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserChatToJson(UserChat instance) => <String, dynamic>{
      'id': instance.id,
      'pubKeys': instance.pubKeys,
      'messages': instance.messages,
      'createAt': instance.createAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
