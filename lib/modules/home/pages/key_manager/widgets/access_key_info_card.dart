import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

class AccessKeyInfoCard extends StatelessWidget {
  const AccessKeyInfoCard({
    super.key,
    required this.keyName,
    required this.privateKeyInfo,
    this.removeAble = true,
  });

  final String keyName;
  final PrivateKeyInfo privateKeyInfo;
  final bool removeAble;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10).r,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(keyName),
            Text(
                "Type: ${privateKeyInfo.privateKeyTypeInfo.type == PrivateKeyType.FunctionCall ? "FunctionCall" : "FullAccess"}"),
            Text("Public Key: ${privateKeyInfo.privateKeyInNearApiJsFormat}"),
            Text("Secret Key: ${privateKeyInfo.privateKey}"),
            if (privateKeyInfo.privateKeyTypeInfo.receiverId != null)
              Text(
                  "Reciver ID: ${privateKeyInfo.privateKeyTypeInfo.receiverId}"),
            if (privateKeyInfo.privateKeyTypeInfo.methodNames != null)
              Text(
                  "Method names: ${privateKeyInfo.privateKeyTypeInfo.methodNames}"),
            if (removeAble) ...[
              SizedBox(height: 10.h),
              Align(
                alignment: Alignment.center,
                child: CustomButton(
                  primary: true,
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text(
                            "Are you sure you want to remove the key?",
                          ),
                          actionsAlignment: MainAxisAlignment.spaceEvenly,
                          actions: [
                            CustomButton(
                              primary: true,
                              onPressed: () async {
                                final authController =
                                    Modular.get<AuthController>();
                                await authController.removeAccessKey(
                                    accessKeyName: keyName);
                                Modular.to.pop();
                              },
                              child: const Text("Remove",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: NEARColors.red)),
                            ),
                            CustomButton(
                              onPressed: () {
                                Modular.to.pop();
                              },
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text(
                    "Remove key",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
