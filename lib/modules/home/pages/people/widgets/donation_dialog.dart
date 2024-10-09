import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationDialog extends StatefulWidget {
  const DonationDialog({super.key, required this.receiverId});
  final String receiverId;

  @override
  State<DonationDialog> createState() => _DonationDialogState();
}

class _DonationDialogState extends State<DonationDialog> {
  late final bool fullAccessKeyAvailable;
  late final AuthController authController;
  PrivateKeyInfo? selectedKey;

  final TextEditingController _amountTextEditingController =
      TextEditingController()..text = "0.1";

  bool transactionLoading = false;

  @override
  void initState() {
    super.initState();
    authController = Modular.get<AuthController>();
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
              ? noFullAccessKeyAvailable()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Donating to ${widget.receiverId}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    const Text(
                      "Select a key to donate: ",
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
                          if (newKey == null) return;
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
                    const Text(
                      "Amount to donate: ",
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Container(
                      padding: const EdgeInsets.all(10).r,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10).r,
                      ),
                      child: TextField(
                        style: const TextStyle(fontSize: 15),
                        controller: _amountTextEditingController,
                        decoration: const InputDecoration.collapsed(
                          hintText: "Amount",
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    FutureBuilder<String>(
                      future: Modular.get<NearBlockChainService>()
                          .getWalletBalance(authController.state.accountId),
                      builder: (context, snapshot) {
                        return Text.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 15),
                            children: [
                              const TextSpan(text: "You have "),
                              snapshot.connectionState == ConnectionState.done
                                  ? TextSpan(text: "${snapshot.data}")
                                  : const WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: SpinnerLoadingIndicator(size: 12),
                                    ),
                              const TextSpan(text: " NEAR"),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 5.h),
                    const Text(
                      "Service fee: ${EnterpriseVariables.amountOfServiceFeeForDonation} NEAR",
                      style: TextStyle(
                        fontSize: 15,
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
                            if (double.tryParse(
                                    _amountTextEditingController.text) ==
                                null) {
                              throw AppExceptions(
                                messageForUser:
                                    "Invalid amount. Check your input.",
                                messageForDev:
                                    "Invalid format: ${_amountTextEditingController.text}",
                              );
                            }

                            setState(() {
                              transactionLoading = true;
                            });

                            final amountToSpend = double.parse(
                                  _amountTextEditingController.text,
                                ) +
                                double.parse(EnterpriseVariables
                                    .amountOfServiceFeeForDonation);

                            final continueApprove = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text(
                                    "Are you sure you want to donate?",
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  content: Text(
                                    "You will spend ${amountToSpend.toStringAsFixed(5)} NEAR to donate to ${widget.receiverId}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  actions: [
                                    CustomButton(
                                      primary: true,
                                      onPressed: () {
                                        Modular.to.pop(true);
                                      },
                                      child: const Text("Yes"),
                                    ),
                                    CustomButton(
                                      primary: false,
                                      onPressed: () {
                                        Modular.to.pop(false);
                                      },
                                      child: const Text("No"),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (continueApprove == null || !continueApprove) {
                              print("Action canceled");
                              setState(() {
                                transactionLoading = false;
                              });
                              return;
                            }

                            final nearSocialApiService =
                                Modular.get<NearSocialApi>();
                            final nearBlockChainService =
                                Modular.get<NearBlockChainService>();
                            final account = authController.state;
                            final privateKey = await nearBlockChainService
                                .getPrivateKeyFromSecretKeyFromNearApiJSFormat(
                              selectedKey!.privateKey.split(":").last,
                            );

                            try {
                              final txHash =
                                  await nearSocialApiService.donateToAccount(
                                accountId: account.accountId,
                                publicKey: account.publicKey,
                                privateKey: privateKey,
                                amountToSend: _amountTextEditingController.text,
                                receiverId: widget.receiverId,
                              );
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    insetPadding:
                                        REdgeInsets.symmetric(horizontal: 20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0).r,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              "You have donated successfully!",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 3.h),
                                          Text.rich(
                                            TextSpan(
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                              children: [
                                                const TextSpan(
                                                  text: "Txn Hash: \n",
                                                ),
                                                TextSpan(
                                                  recognizer:
                                                      TapGestureRecognizer()
                                                        ..onTap = () {
                                                          launchUrl(Uri.parse(
                                                              "https://nearblocks.io/txns/$txHash"));
                                                        },
                                                  text:
                                                      "EkniTwmDYAwkNUcBHiSDv9cGxWwobbokHqura9CChsnb",
                                                  style: const TextStyle(
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            } catch (err) {
                              rethrow;
                            } finally {
                              setState(() {
                                transactionLoading = false;
                              });
                            }
                          },
                          child: const Text(
                            "Donate",
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget noFullAccessKeyAvailable() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("No Full Access Key available!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 5.h),
        const Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 16),
            children: [
              TextSpan(text: "To proceed with a donation, please add a "),
              TextSpan(
                text: "Full Access Key",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: " in the "),
              TextSpan(
                text: "Key Manager",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: " section, accessible via the "),
              TextSpan(
                text: "Menu",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: "."),
            ],
          ),
        ),
      ],
    );
  }
}
