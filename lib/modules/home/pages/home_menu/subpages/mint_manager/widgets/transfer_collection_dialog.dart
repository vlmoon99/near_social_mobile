import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';
import 'package:near_social_mobile/utils/show_confirm_action_dialog.dart';
import 'package:near_social_mobile/utils/show_success_dialog.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/vm/mintbase_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/no_full_access_key.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class TransferCollectionDialog extends StatefulWidget {
  const TransferCollectionDialog(
      {super.key, required this.nftCollectionContract});

  final String nftCollectionContract;

  @override
  State<TransferCollectionDialog> createState() =>
      _TransferCollectionDialogState();
}

class _TransferCollectionDialogState extends State<TransferCollectionDialog> {
  final formKey = GlobalKey<FormState>();

  late final bool fullAccessKeyAvailable;
  late final AuthController authController = Modular.get<AuthController>();
  late final MintbaseController mintbaseController =
      Modular.get<MintbaseController>();
  PrivateKeyInfo? selectedKey;

  final TextEditingController _receiverAddressEditingController =
      TextEditingController();

  bool keepOldMinters = true;

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
    _receiverAddressEditingController.dispose();
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
                        "Transfer Collection",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    const Text(
                      "Select a key to perform the transfer: ",
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
                      child: Container(
                        padding: const EdgeInsets.all(10).r,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10).r,
                        ),
                        child: TextFormField(
                          readOnly: transactionLoading,
                          style: const TextStyle(fontSize: 15),
                          controller: _receiverAddressEditingController,
                          decoration: const InputDecoration.collapsed(
                            hintText: "Receiver address",
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter receiver address';
                            }
                            return null;
                          },
                          onTapOutside: (event) {
                            if (WidgetsBinding
                                    .instance.window.viewInsets.bottom !=
                                0) {
                              return;
                            }
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    GestureDetector(
                      onTap: () {
                        if (transactionLoading) {
                          return;
                        }
                        setState(() {
                          keepOldMinters = !keepOldMinters;
                        });
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: 35.h,
                        child: Material(
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              Checkbox(
                                value: keepOldMinters,
                                visualDensity: VisualDensity.compact,
                                onChanged: (value) {
                                  if (transactionLoading) {
                                    return;
                                  }
                                  setState(() {
                                    keepOldMinters = value!;
                                  });
                                },
                              ),
                              SizedBox(width: 5.h),
                              const Text(
                                "Keep minters",
                                style: TextStyle(
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                                    "Are you sure you want to transfer the collection?",
                                content:
                                    "You will transfer the collection to ${_receiverAddressEditingController.text}")) {
                              return;
                            }

                            setState(() {
                              transactionLoading = true;
                            });

                            late final String txHash;

                            try {
                              final privateKey = await Modular.get<
                                      NearBlockChainService>()
                                  .getPrivateKeyFromSecretKeyFromNearApiJSFormat(
                                selectedKey!.privateKey.split(":").last,
                              );
                              txHash = await mintbaseController
                                  .transferNftCollection(
                                accountId: authController.state.accountId,
                                publicKey: selectedKey!.publicKey,
                                privateKey: privateKey,
                                nftCollectionContract:
                                    widget.nftCollectionContract,
                                newOwnerAccountId:
                                    _receiverAddressEditingController.text,
                                keepOldMintersFlag: keepOldMinters,
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
                                  "You have transferred collection successfully!",
                              txHash: txHash,
                            ).then(
                              (_) {
                                Modular.to.pop();
                              },
                            );
                          },
                          child: const Text("Transfer Collection"),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
