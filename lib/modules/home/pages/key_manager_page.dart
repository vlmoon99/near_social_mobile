import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
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

class KeyAddingDialogBody extends StatefulWidget {
  const KeyAddingDialogBody({
    super.key,
  });

  @override
  State<KeyAddingDialogBody> createState() => _KeyAddingDialogBodyState();
}

class _KeyAddingDialogBodyState extends State<KeyAddingDialogBody> {
  final _formKey = GlobalKey<FormState>();

  bool addingKeyProcessLoading = false;

  String keyName = "";
  String key = "";

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.always,
      child: RPadding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Add new key",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              padding: const EdgeInsets.all(10).r,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10).r,
              ),
              child: TextFormField(
                initialValue:
                    "MyKeyName ${DateFormat('hh:mm a MMM dd, yyyy').format(DateTime.now())}",
                decoration: const InputDecoration.collapsed(
                  hintText: "Write key name",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter name for key';
                  }
                  return null;
                },
                onSaved: (newValue) {
                  keyName = newValue!;
                },
              ),
            ),
            SizedBox(height: 10.w),
            Container(
              padding: const EdgeInsets.all(10).r,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10).r,
              ),
              child: TextFormField(
                initialValue: "",
                decoration: const InputDecoration.collapsed(
                  hintText: "Write key",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter key';
                  }
                  return null;
                },
                onSaved: (newValue) {
                  key = newValue!;
                },
              ),
            ),
            SizedBox(height: 10.w),
            if (!addingKeyProcessLoading)
              ElevatedButton(
                onPressed: () async {
                  final NearSocialApi nearSocialApi =
                      Modular.get<NearSocialApi>();
                  final AuthController authController =
                      Modular.get<AuthController>();
                  try {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      setState(() {
                        addingKeyProcessLoading = true;
                      });

                      final privateKeyInfo =
                          await nearSocialApi.getAccessKeyInfo(
                        accountId: authController.state.accountId,
                        key: key,
                      );

                      await authController.addAccessKey(
                          accessKeyName: keyName,
                          privateKeyInfo: privateKeyInfo);
                      setState(() {
                        addingKeyProcessLoading = false;
                      });
                      Modular.to.pop();
                    }
                  } catch (err) {
                    final catcher = Modular.get<Catcher>();
                    final appException = AppExceptions(
                      messageForUser: "Failed to add key",
                      messageForDev: err.toString(),
                      statusCode: AppErrorCodes.storageError,
                    );
                    catcher.exceptionsHandler.add(appException);
                    setState(() {
                      addingKeyProcessLoading = false;
                    });
                  }
                },
                child: const Text("Add"),
              )
            else
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
