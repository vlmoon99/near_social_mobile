import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';

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
    return GestureDetector(
      child: Card(
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
              if (removeAble)
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Are you sure to remove key?"),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  try {
                                    final authController =
                                        Modular.get<AuthController>();
                                    await authController.removeAccessKey(
                                        accessKeyName: keyName);
                                  } catch (err) {
                                    final catcher = Modular.get<Catcher>();
                                    final appException = AppExceptions(
                                      messageForUser: "Failed to remove key",
                                      messageForDev: err.toString(),
                                      statusCode: AppErrorCodes.storageError,
                                    );
                                    catcher.exceptionsHandler.add(
                                      appException,
                                    );
                                  }
                                  Modular.to.pop();
                                },
                                child: const Text("Remove"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Modular.to.pop();
                                },
                                child: const Text("Cancel"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text(
                      "Remove key",
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
