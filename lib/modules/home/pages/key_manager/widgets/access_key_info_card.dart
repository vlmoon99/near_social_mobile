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
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0).r,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0).r,
        onTap: () {
          showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(20).r,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          keyName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text.rich(
                          style: const TextStyle(fontSize: 15),
                          TextSpan(children: [
                            const TextSpan(
                              text: "Type: \n",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: privateKeyInfo.privateKeyTypeInfo.type ==
                                      PrivateKeyType.FunctionCall
                                  ? "FunctionCall"
                                  : "FullAccess",
                            )
                          ])),
                      SizedBox(height: 5.h),
                      Text.rich(
                        style: const TextStyle(fontSize: 15),
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: "Private Key: \n",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            WidgetSpan(
                              child: SelectableText(
                                privateKeyInfo.privateKey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (privateKeyInfo.privateKeyTypeInfo.receiverId !=
                          null) ...[
                        SizedBox(height: 5.h),
                        Text.rich(
                            style: const TextStyle(fontSize: 15),
                            TextSpan(children: [
                              const TextSpan(
                                text: "Reciver ID: \n",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text:
                                    "${privateKeyInfo.privateKeyTypeInfo.receiverId}",
                              )
                            ])),
                      ],
                      if (privateKeyInfo.privateKeyTypeInfo.methodNames !=
                              null &&
                          privateKeyInfo
                              .privateKeyTypeInfo.methodNames!.isNotEmpty) ...[
                        SizedBox(height: 5.h),
                        Text.rich(
                            style: const TextStyle(fontSize: 15),
                            TextSpan(children: [
                              const TextSpan(
                                text: "Method names: \n",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text:
                                    "${privateKeyInfo.privateKeyTypeInfo.methodNames}",
                              )
                            ])),
                      ],
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
                                    actionsAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    actions: [
                                      CustomButton(
                                        primary: true,
                                        onPressed: () async {
                                          final authController =
                                              Modular.get<AuthController>();
                                          authController.removeAccessKey(
                                              accessKeyName: keyName);
                                          Modular.to.pop(true);
                                        },
                                        child: const Text("Remove",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: NEARColors.red)),
                                      ),
                                      CustomButton(
                                        onPressed: () {
                                          Modular.to.pop(false);
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
                              ).then(
                                (removed) {
                                  if (removed) {
                                    Modular.to.pop();
                                  }
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
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15).r,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10).r,
                width: 40.h,
                height: 40.h,
                decoration: BoxDecoration(
                  color: NEARColors.black,
                  borderRadius: BorderRadius.circular(10).r,
                ),
                child: Icon(
                  Icons.key,
                  color: privateKeyInfo.privateKeyTypeInfo.type ==
                          PrivateKeyType.FunctionCall
                      ? NEARColors.grey
                      : NEARColors.gold,
                ),
              ),
              SizedBox(width: 10.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      keyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      privateKeyInfo.privateKeyTypeInfo.type ==
                              PrivateKeyType.FunctionCall
                          ? "FunctionCall"
                          : "FullAccess",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
