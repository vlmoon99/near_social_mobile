import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/modules/home/apis/models/general_account_info.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';

class UserChatPage extends StatefulWidget {
  const UserChatPage({super.key});

  @override
  State<UserChatPage> createState() => _UserChatPageState();
}

class _UserChatPageState extends State<UserChatPage> {
  List<ChatMessage> messages = <ChatMessage>[];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final nearSocialApi = Modular.get<NearSocialApi>();
    final authController = Modular.get<AuthController>();
    final stateUserAccount = authController.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic example'),
      ),
      body: FutureBuilder<GeneralAccountInfo>(
          future: nearSocialApi.getGeneralAccountInfo(
              accountId: stateUserAccount.accountId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            final generalAccountInfo = snapshot.data;
            final chatUser = ChatUser(
              id: stateUserAccount.publicKey,
              firstName: generalAccountInfo!.accountId,
              lastName: generalAccountInfo!.name,
            );

            return DashChat(
              currentUser: chatUser,
              onSend: (ChatMessage m) {
                setState(() {
                  messages.insert(0, m);
                });
              },
              messages: messages,
            );
          }),
    );
  }
}
