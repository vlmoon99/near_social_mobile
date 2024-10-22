import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({Key? key, required this.room}) : super(key: key);
  final types.Room room;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<types.Message>>(
        initialData: const [],
        stream: FirebaseChatCore.instance.messages(room),
        builder: (context, snapshot) {
          
          return const Center(
            child: Text("Text1"),
          );

        },
      ),
    );
  }
}
