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

class RemoveAddMinterDialog extends StatefulWidget {
  const RemoveAddMinterDialog(
      {super.key,
      required this.addAction,
      required this.nftCollectionContract,
      this.minterId});

  final bool addAction;
  final String nftCollectionContract;
  final String? minterId;

  @override
  State<RemoveAddMinterDialog> createState() => _RemoveAddMinterDialogState();
}

class _RemoveAddMinterDialogState extends State<RemoveAddMinterDialog> {
  final formKey = GlobalKey<FormState>();
  late final bool fullAccessKeyAvailable;
  late final AuthController authController = Modular.get<AuthController>();
  late final MintbaseController mintbaseController =
      Modular.get<MintbaseController>();
  PrivateKeyInfo? selectedKey;
  late final TextEditingController _minterAddressController =
      TextEditingController()..text = widget.minterId ?? "";

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
    _minterAddressController.dispose();
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
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "${widget.addAction ? "Add" : "Remove"} minter",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    const Text(
                      "Select a key to perform action: ",
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
                    if (widget.addAction) ...[
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
                            controller: _minterAddressController,
                            decoration: const InputDecoration.collapsed(
                              hintText: "Minter address",
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter minter address';
                              }
                              return null;
                            },
                            onTapOutside: (event) =>
                                FocusScope.of(context).unfocus(),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ],
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

                            if (widget.addAction &&
                                !formKey.currentState!.validate()) {
                              return;
                            }

                            if (!await askToConfirmAction(
                              title:
                                  "Are you sure you want to ${widget.addAction ? "add" : "remove"} minter?",
                              content:
                                  "You will ${widget.addAction ? "add ${_minterAddressController.text} minter to collection" : "remove ${widget.minterId}"}",
                            )) {
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
                              if (widget.addAction) {
                                txHash = await mintbaseController
                                    .addMinterToCollection(
                                  accountId: authController.state.accountId,
                                  publicKey: selectedKey!.publicKey,
                                  privateKey: privateKey,
                                  nftCollectionContract:
                                      widget.nftCollectionContract,
                                  minterAccountId:
                                      _minterAddressController.text,
                                );
                              } else {
                                txHash = await mintbaseController
                                    .removeMinterFromCollection(
                                  accountId: authController.state.accountId,
                                  publicKey: selectedKey!.publicKey,
                                  privateKey: privateKey,
                                  nftCollectionContract:
                                      widget.nftCollectionContract,
                                  minterAccountId: widget.minterId!,
                                );
                              }
                            } catch (err) {
                              rethrow;
                            } finally {
                              setState(() {
                                transactionLoading = false;
                              });
                            }
                            showSuccessDialog(
                              title:
                                  "You have ${widget.addAction ? "added" : "removed"} minter successfully!",
                              txHash: txHash,
                            ).then(
                              (_) {
                                Modular.to.pop();
                              },
                            );
                          },
                          child: Text(widget.addAction ? "Add" : "Remove"),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
