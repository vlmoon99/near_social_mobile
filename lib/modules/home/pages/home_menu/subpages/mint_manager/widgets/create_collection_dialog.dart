import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutterchain/flutterchain_lib/models/chains/near/near_account_info_request.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';
import 'package:near_social_mobile/utils/show_confirm_action_dialog.dart';
import 'package:near_social_mobile/utils/show_success_dialog.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/vm/mintbase_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/no_full_access_key.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class CreateMintbaseCollectionDialog extends StatefulWidget {
  const CreateMintbaseCollectionDialog({super.key});

  @override
  State<CreateMintbaseCollectionDialog> createState() =>
      _CreateMintbaseCollectionDialogState();
}

class _CreateMintbaseCollectionDialogState
    extends State<CreateMintbaseCollectionDialog> {
  final formKey = GlobalKey<FormState>();

  late final bool fullAccessKeyAvailable;
  late final AuthController authController = Modular.get<AuthController>();
  late final MintbaseController mintbaseController =
      Modular.get<MintbaseController>();
  PrivateKeyInfo? selectedKey;

  final TextEditingController _symbolEditingController =
      TextEditingController();
  final TextEditingController _nameEditingController = TextEditingController();

  bool transactionLoading = false;

  @override
  void initState() {
    super.initState();
    fullAccessKeyAvailable =
        authController.state.additionalStoredKeys.values.any(
      (storedKey) =>
          storedKey.privateKeyTypeInfo.type == PrivateKeyType.FullAccess,
    );

    if (fullAccessKeyAvailable) {
      selectedKey = authController.state.additionalStoredKeys.values.firstWhere(
        (storedKey) =>
            storedKey.privateKeyTypeInfo.type == PrivateKeyType.FullAccess,
      );
    }
  }

  @override
  void dispose() {
    _symbolEditingController.dispose();
    _nameEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !transactionLoading,
      child: Dialog(
        insetPadding: REdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(16).r,
          child: !fullAccessKeyAvailable
              ? const NoFullAccessKeyBannerBody()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Create Collection",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    const Text(
                      "Select a key to create the collection: ",
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButton<PrivateKeyInfo>(
                        isExpanded: true,
                        value: selectedKey,
                        onChanged: (newKey) {
                          if (newKey == null || transactionLoading) return;
                          setState(() {
                            selectedKey = newKey;
                          });
                        },
                        items: authController.state.additionalStoredKeys.entries
                            .where(
                          (storedKey) {
                            return storedKey.value.privateKeyTypeInfo.type ==
                                PrivateKeyType.FullAccess;
                          },
                        ).map((keyInfo) {
                          return DropdownMenuItem<PrivateKeyInfo>(
                            alignment: Alignment.center,
                            value: keyInfo.value,
                            child: Text(
                              keyInfo.key,
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.always,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10).r,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(10).r,
                            ),
                            child: TextFormField(
                              readOnly: transactionLoading,
                              style: const TextStyle(fontSize: 15),
                              controller: _symbolEditingController,
                              decoration: const InputDecoration.collapsed(
                                hintText: "Symbol",
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter symbol';
                                }
                                if (value.length > 6) {
                                  return 'Symbol must be less than 6 characters';
                                }
                                return null;
                              },
                              onTapOutside: (event) =>
                                  FocusScope.of(context).unfocus(),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Container(
                            padding: const EdgeInsets.all(10).r,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(10).r,
                            ),
                            child: TextFormField(
                              readOnly: transactionLoading,
                              style: const TextStyle(fontSize: 15),
                              controller: _nameEditingController,
                              decoration: const InputDecoration.collapsed(
                                hintText: "Name",
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter name';
                                }
                                return null;
                              },
                              onTapOutside: (event) =>
                                  FocusScope.of(context).unfocus(),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                    if (transactionLoading)
                      const Align(
                        alignment: Alignment.center,
                        child: SpinnerLoadingIndicator(),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          primary: true,
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            if (!await askToConfirmAction(
                              title:
                                  "Are you sure you want to create the collection?",
                              content:
                                  "You will spend 3.7 NEAR to create the collection.",
                            )) {
                              return;
                            }

                            setState(() {
                              transactionLoading = true;
                            });

                            final nearBlockChainService =
                                Modular.get<NearBlockChainService>();

                            final currentBalance = await nearBlockChainService
                                .getWalletBalance(NearAccountInfoRequest(
                                    accountId: authController.state.accountId));
                            if (!(double.parse(currentBalance) > 3.7)) {
                              throw AppExceptions(
                                messageForUser:
                                    "Not enough balance. You have $currentBalance NEAR, but you need 3.7 NEAR.",
                                messageForDev:
                                    "Not enough balance. You have $currentBalance NEAR, but you need 3.7 NEAR.",
                              );
                            }

                            late final String txHash;

                            try {
                              final privateKey = await nearBlockChainService
                                  .getPrivateKeyFromSecretKeyFromNearApiJSFormat(
                                selectedKey!.privateKey.split(":").last,
                              );
                              txHash =
                                  await mintbaseController.createCollection(
                                accountId: authController.state.accountId,
                                publicKey: selectedKey!.publicKey,
                                privateKey: privateKey,
                                collectionName:
                                    _nameEditingController.text.toLowerCase(),
                                collectionSymbol:
                                    _symbolEditingController.text.toLowerCase(),
                              );
                            } catch (err) {
                              rethrow;
                            } finally {
                              setState(() {
                                transactionLoading = false;
                              });
                            }
                            showSuccessDialog(
                              title:
                                  "You have created collection successfully!",
                              txHash: txHash,
                            ).then(
                              (_) {
                                Modular.to.pop();
                              },
                            );
                          },
                          child: const Text("Create Collection"),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
