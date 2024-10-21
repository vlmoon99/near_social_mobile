import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/modules/home/apis/models/nft.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/vm/mintbase_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/no_full_access_key.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';
import 'package:near_social_mobile/utils/show_confirm_action_dialog.dart';
import 'package:near_social_mobile/utils/show_success_dialog.dart';

class CopyNftDialog extends StatefulWidget {
  const CopyNftDialog({super.key, required this.nft});

  final Nft nft;

  @override
  State<CopyNftDialog> createState() => _CopyNftDialogState();
}

class _CopyNftDialogState extends State<CopyNftDialog> {
  final formKey = GlobalKey<FormState>();

  late final bool fullAccessKeyAvailable;
  late final AuthController authController = Modular.get<AuthController>();
  late final MintbaseController mintbaseController =
      Modular.get<MintbaseController>();
  PrivateKeyInfo? selectedKey;

  final TextEditingController _amountToCopyEditingController =
      TextEditingController()..text = "1";

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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !transactionLoading,
      child: Dialog(
        insetPadding: REdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: REdgeInsets.all(16),
          child: !fullAccessKeyAvailable
              ? const NoFullAccessKeyBannerBody()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Copy NFT",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text(
                        "You can increase the amount of this NFT. It will be copied with different IDs."),
                    SizedBox(height: 10.h),
                    const Text(
                      "Select a key to perform the action: ",
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
                    const Text(
                      "Enter the amount of copies: ",
                    ),
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
                          keyboardType: TextInputType.number,
                          controller: _amountToCopyEditingController,
                          decoration: const InputDecoration.collapsed(
                            hintText: "Amount of copies",
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter receiver address';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            if (int.parse(value) <= 0) {
                              return "Amount must be greater than 0";
                            }
                            return null;
                          },
                          onTapOutside: (event) =>
                              FocusScope.of(context).unfocus(),
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
                              title: "Are you sure you want to copy this NFT?",
                              content:
                                  "Amount of this NFT will be increased by ${_amountToCopyEditingController.text}",
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
                              txHash = await mintbaseController.copyNft(
                                accountId: authController.state.accountId,
                                publicKey: selectedKey!.publicKey,
                                privateKey: privateKey,
                                nftCollectionContract: widget.nft.contractId,
                                nftTitle: widget.nft.title,
                                count: int.parse(
                                  _amountToCopyEditingController.text,
                                ),
                              );
                            } catch (err) {
                              rethrow;
                            } finally {
                              setState(() {
                                transactionLoading = false;
                              });
                            }

                            showSuccessDialog(
                              title: "You have copied NFT successfully!",
                              txHash: txHash,
                            ).then(
                              (_) {
                                Modular.to.pop();
                              },
                            );
                          },
                          child: const Text("Copy NFT"),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
