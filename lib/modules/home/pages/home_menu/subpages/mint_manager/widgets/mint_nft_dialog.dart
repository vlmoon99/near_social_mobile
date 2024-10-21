import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutterchain/flutterchain_lib/models/chains/near/mintbase_category_nft.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';
import 'package:near_social_mobile/utils/show_confirm_action_dialog.dart';
import 'package:near_social_mobile/utils/show_success_dialog.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/vm/mintbase_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/no_full_access_key.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class MintNFTDialog extends StatefulWidget {
  const MintNFTDialog({
    super.key,
    required this.nftCollectionContract,
    required this.title,
    required this.description,
    required this.mediaBytes,
    this.splitBetween,
    this.splitOwners,
    this.tagsList,
    required this.category,
    required this.numToMint,
  });

  final String nftCollectionContract;
  final String title;
  final String description;
  final Uint8List mediaBytes;
  final Map<String, int>? splitBetween;
  final Map<String, int>? splitOwners;
  final List<String>? tagsList;
  final CategoryNFT category;
  final int numToMint;

  @override
  State<MintNFTDialog> createState() => _MintNFTDialogState();
}

class _MintNFTDialogState extends State<MintNFTDialog> {
  late final bool fullAccessKeyAvailable;
  late final AuthController authController = Modular.get<AuthController>();
  late final MintbaseController mintbaseController =
      Modular.get<MintbaseController>();
  PrivateKeyInfo? selectedKey;

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
          padding: const EdgeInsets.all(16).r,
          child: !fullAccessKeyAvailable
              ? const NoFullAccessKeyBannerBody()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Mint NFT",
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
                      "Select a key to use: ",
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

                            if (!await askToConfirmAction(
                              title: "Are you sure you want to mint this NFT?",
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
                              txHash = await mintbaseController.mintNft(
                                accountId: authController.state.accountId,
                                publicKey: selectedKey!.publicKey,
                                privateKey: privateKey,
                                nftCollectionContract:
                                    widget.nftCollectionContract,
                                title: widget.title,
                                description: widget.description,
                                media: widget.mediaBytes,
                                splitBetween: widget.splitBetween,
                                splitOwners: widget.splitOwners,
                                tagsList: widget.tagsList,
                                category: widget.category,
                                numToMint: widget.numToMint,
                              );
                            } catch (err) {
                              rethrow;
                            } finally {
                              setState(() {
                                transactionLoading = false;
                              });
                            }

                            showSuccessDialog(
                              title: "You have minted NFT successfully!",
                              txHash: txHash,
                            ).then(
                              (_) {
                                Modular.to.pop();
                              },
                            );
                          },
                          child: const Text(
                            "Perform Action",
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
