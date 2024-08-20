import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutterchain/flutterchain_lib/models/core/wallet.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:intl/intl.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class KeyAddingDialogBody extends StatefulWidget {
  const KeyAddingDialogBody({
    super.key,
  });

  @override
  State<KeyAddingDialogBody> createState() => _KeyAddingDialogBodyState();
}

class _KeyAddingDialogBodyState extends State<KeyAddingDialogBody>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  bool addingKeyProcessLoading = false;

  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  String keyName = "";
  String key = "";
  String mnemonic = "";
  String derivationPath = "";

  Future<void> addKey() async {
    final NearSocialApi nearSocialApi = Modular.get<NearSocialApi>();
    final AuthController authController = Modular.get<AuthController>();
    try {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
        setState(() {
          addingKeyProcessLoading = true;
        });
        late PrivateKeyInfo privateKeyInfo;
        if (_tabController.index == 0) {
          if (authController.state.additionalStoredKeys.values
              .any((element) => element.privateKey == key)) {
            setState(() {
              addingKeyProcessLoading = false;
            });
            throw AppExceptions(
              messageForUser: "Key already added",
              messageForDev: "Key already added",
            );
          }
          privateKeyInfo = await nearSocialApi.getAccessKeyInfo(
            accountId: authController.state.accountId,
            key: key,
          );
        } else {
          final derivationPathParameters = derivationPath.split('/').toList();

          final derivationModel = DerivationPath(
            purpose: derivationPathParameters[1],
            coinType: derivationPathParameters[2],
            accountNumber: derivationPathParameters[3],
            change: derivationPathParameters[4],
            address: derivationPathParameters[5],
          );

          final NearBlockChainService nearBlockChainService =
              Modular.get<NearBlockChainService>();

          final BlockChainData blockChainData =
              await nearBlockChainService.getBlockChainDataByDerivationPath(
            mnemonic: mnemonic,
            passphrase: "",
            derivationPath: derivationModel,
          );

          final secretKey =
              await nearBlockChainService.exportPrivateKeyToTheNearApiJsFormat(
                  currentBlockchainData: blockChainData);

          if (authController.state.additionalStoredKeys.values
              .any((element) => element.privateKey == secretKey)) {
            setState(() {
              addingKeyProcessLoading = false;
            });
            throw AppExceptions(
              messageForUser: "Key already added",
              messageForDev: "Key already added",
            );
          }

          privateKeyInfo = await nearSocialApi.getAccessKeyInfo(
            accountId: blockChainData.publicKey,
            key: secretKey,
          );
        }

        await authController.addAccessKey(
          accessKeyName: keyName,
          privateKeyInfo: privateKeyInfo,
        );
        Modular.to.pop();
      }
    } catch (err) {
      rethrow;
    } finally {
      setState(() {
        addingKeyProcessLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.always,
      child: RPadding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            "Add new key",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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
          SizedBox(height: 10.h),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 210.h,
              maxWidth: double.infinity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Key'),
                    Tab(
                      child: Text(
                        "Mnemonic Phrase",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  dividerColor: Colors.black.withOpacity(.1),
                ),
                Flexible(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // First tab: Key
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 10.h),
                          Container(
                            padding: const EdgeInsets.all(10).r,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(10).r,
                            ),
                            child: TextFormField(
                              initialValue: "",
                              decoration: const InputDecoration.collapsed(
                                hintText: "Private key",
                              ),
                              validator: (value) {
                                if (_tabController.index == 1) {
                                  return null;
                                }
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
                        ],
                      ),
                      // Second tab: Mnemonic & Path
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 10.h),
                          Container(
                            padding: const EdgeInsets.all(10).r,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(10).r,
                            ),
                            child: TextFormField(
                              initialValue: "",
                              decoration: const InputDecoration.collapsed(
                                hintText: "Mnemonic phrase",
                              ),
                              validator: (value) {
                                if (_tabController.index == 0) {
                                  return null;
                                }
                                if (value == null || value.isEmpty) {
                                  return 'Please enter mnemonic phrase';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                mnemonic = newValue!;
                              },
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
                              initialValue: "m/44'/397'/0'/0/0",
                              decoration: const InputDecoration.collapsed(
                                hintText: "Derivation path",
                              ),
                              validator: (value) {
                                if (_tabController.index == 0) {
                                  return null;
                                }
                                if (value == null || value.isEmpty) {
                                  return 'Please enter derivation path';
                                }
                                derivationPath = value;
                                return null;
                              },
                              onSaved: (newValue) {
                                derivationPath = newValue!;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!addingKeyProcessLoading)
                  CustomButton(
                    primary: true,
                    onPressed: addKey,
                    child: const Text(
                      "Add",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const Center(
                    child: SpinnerLoadingIndicator(),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
