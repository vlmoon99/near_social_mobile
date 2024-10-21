import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:json_annotation/json_annotation.dart';
part 'user_chat.g.dart'; // This is the generated file, name it accordingly

@JsonSerializable()
class UserChat {
  final String id;
  final List<String> pubKeys;
  final Map<String, List<ChatMessage>> messages;
  final DateTime createAt;
  final DateTime updatedAt;

  UserChat({
    required this.id,
    required this.pubKeys,
    required this.messages,
    required this.createAt,
    required this.updatedAt,
  });

  factory UserChat.fromJson(Map<String, dynamic> json) =>
      _$UserChatFromJson(json);

  Map<String, dynamic> toJson() => _$UserChatToJson(this);
}
