import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/modules/home/pages/messages/user_chat_page.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';

class UserMessagesPage extends StatefulWidget {
  const UserMessagesPage({super.key});

  @override
  State<UserMessagesPage> createState() => _UserMessagesPageState();
}

class _UserMessagesPageState extends State<UserMessagesPage> {
  final List<String> _usernames =
      List.generate(10, (index) => 'User ${index + 1}');
  List<String> _filteredUsernames = [];

  Future<void> getChatsWithPublicKey(String publicKey) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('pubKeys', arrayContains: publicKey)
          .get();

      for (var doc in querySnapshot.docs) {
        log("Chat ID: ${doc.id}, Data: ${doc.data()}");
      }
    } catch (e) {
      log("Error fetching chats: $e");
    }
  }

  @override
  void initState() {
    super.initState();

    final authController = Modular.get<AuthController>();
    final stateUserAccount = authController.state;
    log(stateUserAccount.toString());
    getChatsWithPublicKey(stateUserAccount.publicKey);

    _filteredUsernames = _usernames;
  }

  void _filterChats(String query) {
    setState(() {
      _filteredUsernames = _usernames
          .where((username) =>
              username.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Messages", style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: _filterChats,
                decoration: const InputDecoration(
                  hintText: 'Search for a user',
                  prefixIcon: Icon(Icons.search, color: Colors.black),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsernames.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserChatPage(),
                          ),
                        );
                      },
                      leading: const CircleAvatar(
                        radius: 25,
                        backgroundImage:
                            NetworkImage('https://via.placeholder.com/150'),
                      ),
                      title: Text(_filteredUsernames[index],
                          style: const TextStyle(fontSize: 16)),
                      subtitle: const Text('Last message preview here',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF2F2F7), // iOS-like background
    );
  }
}
