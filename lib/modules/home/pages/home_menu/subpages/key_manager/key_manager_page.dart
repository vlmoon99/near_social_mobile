import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/key_manager/widgets/access_key_info_card.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/key_manager/widgets/key_adding_dialog_body.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/models/auth_info.dart';

class KeyManagerPage extends StatelessWidget {
  const KeyManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Access Keys",
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leadingWidth: kIsWeb ? 50.h : 0,
        leading: kIsWeb
            ? IconButton(
                onPressed: () {
                  Modular.to.pop();
                },
                icon: const Icon(Icons.arrow_back),
              )
            : const SizedBox.shrink(),
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
                  padding: EdgeInsets.only(top: index == 0 ? 5 : 0).r,
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
          HapticFeedback.lightImpact();
          showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                insetPadding: REdgeInsets.symmetric(horizontal: 20),
                child: const KeyAddingDialogBody(),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
