
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/pages/key_manager/widgets/access_key_info_card.dart';
import 'package:near_social_mobile/modules/home/pages/key_manager/widgets/key_adding_dialog_body.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/models/auth_info.dart';

class KeyManagerPage extends StatelessWidget {
  const KeyManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Access Keys"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<AuthInfo>(
          stream: authController.stream,
          builder: (context, snapshot) {
            return ListView.builder(
              padding: REdgeInsets.symmetric(horizontal: 20),
              itemBuilder: (context, index) {
                final key = authController.state.additionalStoredKeys.entries
                    .elementAt(index);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10).r,
                  child: AccessKeyInfoCard(
                    keyName: key.key,
                    privateKeyInfo: key.value,
                    removeAble:
                        key.value.privateKey != authController.state.secretKey,
                  ),
                );
              },
              itemCount: authController.state.additionalStoredKeys.length,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return const Dialog(
                child: KeyAddingDialogBody(),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

