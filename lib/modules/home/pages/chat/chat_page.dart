import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:rxdart/rxdart.dart';

import 'package:encrypt/encrypt.dart' as encrypt;

import 'dart:typed_data';
import 'package:pointycastle/export.dart' as crypto;

class ChatPage extends StatefulWidget {
  const ChatPage({
    Key? key,
    required this.room,
    required this.currentUser,
    required this.isSecure,
  }) : super(key: key);
  final bool isSecure;
  final types.Room room;
  final types.User currentUser;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final BehaviorSubject<types.Room?> roomSubject =
      BehaviorSubject<types.Room?>();


  Future<Map<String, dynamic>> generateECCKeyPair() async {
    final eccParams = crypto.ECDomainParameters('prime256v1');
    final keyParams = crypto.ECKeyGeneratorParameters(eccParams);
    final random = crypto.SecureRandom("Fortuna")..seed(crypto.KeyParameter(Uint8List(32)));

    final generator = crypto.ECKeyGenerator();
    generator.init(crypto.ParametersWithRandom(keyParams, random));

    final pair = generator.generateKeyPair();
    final privateKey = pair.privateKey as crypto.ECPrivateKey;
    final publicKey = pair.publicKey as crypto.ECPublicKey;

    return {'privateKey': privateKey, 'publicKey': publicKey};
  }

  String deriveSharedSecret(
      crypto.ECPrivateKey privateKey, crypto.ECPublicKey publicKey) {
    final ecdh = crypto.ECDHBasicAgreement();
    ecdh.init(privateKey);
    final sharedSecret = ecdh.calculateAgreement(publicKey).toRadixString(16);
    return sharedSecret;
  }

  String encryptMessageForParticipant(String message, String sharedSecret) {
    final key = encrypt.Key.fromUtf8(sharedSecret.substring(0, 32));
    final iv = encrypt.IV.fromLength(12);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

    final encrypted = encrypter.encrypt(message, iv: iv);
    return encrypted.base64;
  }

  String decryptMessage(String encryptedMessage, String sharedSecret) {
    final key = encrypt.Key.fromUtf8(sharedSecret.substring(0, 32));
    final iv = encrypt.IV.fromLength(12);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

    final decrypted = encrypter.decrypt64(encryptedMessage, iv: iv);
    return decrypted;
  }


  @override
  void initState() {
    super.initState();
    listenToRoom(widget.room.id);
    if (widget.isSecure &&
        widget.room.metadata != null &&
        ((widget.room.metadata!['encryptionKeys'] as List<String>?)?.length ??
                0) <
            2) {
      print("Create Keys pls");
    }
  }




  types.Room transformRoomData(String roomId, Map<String, dynamic> roomData) {
    return types.Room(
      createdAt: (roomData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch,
      id: roomId,
      imageUrl: roomData['imageUrl'] as String?,
      lastMessages: (roomData['lastMessages'] as List<dynamic>?)
          ?.map((message) => types.Message.fromJson(message))
          .toList(),
      metadata: roomData['metadata'] as Map<String, dynamic>?,
      name: roomData['name'] as String?,
      type: roomData['type'] != null
          ? types.RoomType.values.firstWhere(
              (type) => type.toString() == 'RoomType.${roomData['type']}')
          : null,
      updatedAt:
          (roomData['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
      users: (roomData['users'] as List<dynamic>?)
              ?.map((user) => types.User.fromJson(user))
              .toList() ??
          <types.User>[],
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
        roomSubject.add(transformRoomData(roomId, roomData));
      } else {
        roomSubject.add(widget.room);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    roomSubject.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.isSecure ? "Secure Chat" : "Chat"),
        actions: [
          !widget.isSecure
              ? IconButton(
                  onPressed: () async {
                    if (!widget.isSecure) {
                      final accountIds = <String>[];
                      final users = <types.User>[];

                      for (types.User user in widget.room.users) {
                        final userInfo = await Modular.get<NearSocialApi>()
                            .getGeneralAccountInfo(accountId: user.id);
                        accountIds.add(userInfo.accountId);
                      }

                      for (String accountId in accountIds) {
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(accountId)
                            .get();

                        if (userDoc.exists) {
                          final userData = {
                            "id": userDoc.id,
                            "imageUrl": userDoc.data()!['imageUrl'],
                            "firstName": userDoc.data()!['firstName'],
                            "lastName": userDoc.data()!['lastName'],
                            "role": userDoc.data()!['role'],
                            "metadata": userDoc.data()!['metadata'],
                          };

                          final user = types.User.fromJson(userData);
                          users.add(user);
                        }
                      }

                      final room =
                          await Modular.get<NearSocialApi>().createRoom(
                        true,
                        Modular.get<AuthController>().state.accountId,
                        users.first,
                        metadata: {'isSecure': true},
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => ChatPage(
                            room: room,
                            currentUser: widget.currentUser,
                            isSecure: true,
                          ),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    Icons.security,
                    color: widget.isSecure ? Colors.lightBlue : Colors.grey,
                  ),
                )
              : IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.key),
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
                  if (!widget.isSecure) {
                    Modular.get<NearSocialApi>()
                        .sendMessage(data, room.id, widget.currentUser.id);
                  } else if (widget.isSecure &&
                      room.metadata != null &&
                      ((room.metadata!['encryptionKeys'] as List<String>?)
                                  ?.length ??
                              0) >
                          2) {
                    print("Send message");
                  } else if (widget.isSecure &&
                      room.metadata != null &&
                      ((room.metadata!['encryptionKeys'] as List<String>?)
                                  ?.length ??
                              0) <
                          2) {
                    print("Create Keys");
                  } else if (widget.isSecure &&
                      room.metadata != null &&
                      ((room.metadata!['encryptionKeys'] as List<String>?)
                                  ?.length ??
                              0) ==
                          1) {
                    print(
                        "Another account must create keys for secure communication");
                  }
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
