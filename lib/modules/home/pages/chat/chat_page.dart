import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:rxdart/rxdart.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.room, required this.currentUser})
      : super(key: key);
  final types.Room room;
  final types.User currentUser;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final BehaviorSubject<types.Room?> roomSubject =
      BehaviorSubject<types.Room?>();

  @override
  void initState() {
    super.initState();
    listenToRoom(widget.room.id);
  }

  // Map<String, dynamic> transformRoomData(Map<String, dynamic> roomData) {
  //   if (roomData['createdAt'] is Timestamp) {
  //     roomData['createdAt'] = (roomData['createdAt'] as Timestamp).seconds;
  //   } else if (roomData['createdAt'] == null) {
  //     roomData['createdAt'] = 0;
  //   }

  //   if (roomData['updatedAt'] is Timestamp) {
  //     roomData['updatedAt'] = (roomData['updatedAt'] as Timestamp).seconds;
  //   } else if (roomData['updatedAt'] == null) {
  //     roomData['updatedAt'] = 0;
  //   }

  //   if (roomData['name'] == null) {
  //     roomData['name'] = 'Unknown Room';
  //   }

  //   if (roomData['userIds'] == null || roomData['userIds'] is! List) {
  //     roomData['userIds'] = [];
  //   }

  //   if (roomData['type'] == null) {
  //     roomData['type'] = 'direct';
  //   }

  //   if (roomData['metadata'] == null) {
  //     roomData['metadata'] = {};
  //   }

  //   if (roomData['imageUrl'] == null) {
  //     roomData['imageUrl'] = '';
  //   }

  //   if (roomData['userRoles'] == null) {
  //     roomData['userRoles'] = [];
  //   }
  //   print(roomData.toString());

  //   return roomData;
  // }

  types.Room transformRoomData(String roomId,Map<String, dynamic> roomData) {
    // Extract data from the roomData map and pass it to the Room constructor
    return types.Room(
      createdAt: (roomData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch, // Cast to the appropriate type
      id: roomId, // Required field
      imageUrl: roomData['imageUrl'] as String?, // Optional field
      lastMessages: (roomData['lastMessages'] as List<dynamic>?)
          ?.map((message) => types.Message.fromJson(message))
          .toList(), // Assuming messages are stored as JSON objects
      metadata: roomData['metadata'] as Map<String, dynamic>?, // Optional field
      name: roomData['name'] as String?, // Optional field
      type: roomData['type'] != null
          ? types.RoomType.values.firstWhere(
              (type) => type.toString() == 'RoomType.${roomData['type']}')
          : null, // Enum conversion from String
      updatedAt: (roomData['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0, // Optional field
      users: (roomData['users'] as List<dynamic>?)
          ?.map((user) => types.User.fromJson(user))
          .toList() ?? <types.User>[], // Assuming users are stored as JSON objects
    );
  }

  void listenToRoom(String roomId) {
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final roomData = snapshot.data()!;
        roomSubject.add(transformRoomData(roomId,roomData));
      } else {
        roomSubject.add(widget.room);
      }
    });
  }

  @override
  void dispose() {
    roomSubject.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Chat"),
        actions: [
          IconButton(
            onPressed: () {
              print("Icons.security");
            },
            icon: const Icon(Icons.security),
          ),
        ],
        leading: IconButton(
          onPressed: () {
            print("Icons.backspace");
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: StreamBuilder(
        stream: roomSubject,
        initialData: widget.room,
        builder: (context, snapshot) {
          final room = snapshot.data!;
          return StreamBuilder<List<types.Message>>(
            initialData: [],
            stream: FirebaseChatCore.instance.messages(room),
            builder: (context, snapshot) {
              return Chat(
                scrollPhysics: const BouncingScrollPhysics(),
                messages: snapshot.data ?? [],
                onSendPressed: (data) async {
                  Modular.get<NearSocialApi>()
                      .sendMessage(data, room.id, widget.currentUser.id);
                },
                user: widget.currentUser,
              );
            },
          );
        },
      ),
    );
  }
}
