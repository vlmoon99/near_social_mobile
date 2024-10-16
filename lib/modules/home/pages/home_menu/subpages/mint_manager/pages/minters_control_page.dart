import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/vm/mintbase_controller.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/widgets/load_mintes_dialog.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/widgets/remove_add_minter_dialog.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

class MintbaseMintersControlPage extends StatelessWidget {
  const MintbaseMintersControlPage({
    super.key,
    required this.nftCollectionContract,
  });

  final String nftCollectionContract;

  @override
  Widget build(BuildContext context) {
    final MintbaseController mintbaseController =
        Modular.get<MintbaseController>();
    final AuthController authController = Modular.get<AuthController>();
    return StreamBuilder(
      stream: mintbaseController.stream,
      builder: (context, snapshot) {
        final nftCollection = mintbaseController.state.ownCollections
            .firstWhere(
                (collection) => collection.contractId == nftCollectionContract);
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "Minters Control",
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            leadingWidth: 0,
            leading: const SizedBox.shrink(),
          ),
          floatingActionButton: nftCollection.lastUpdate != null
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    showDialog(
                      context: context,
                      builder: (context) => RemoveAddMinterDialog(
                        addAction: true,
                        nftCollectionContract: nftCollectionContract,
                      ),
                    );
                  },
                  label: const Text("Add Minter"),
                  icon: const Icon(Icons.add),
                )
              : null,
          body: Builder(
            builder: (context) {
              if (nftCollection.lastUpdate == null) {
                return SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16).r,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Minters information is not loaded.",
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          "To load minters information, you need to execute transaction which needs gas to be executed. Thats why you need to use FullAccessKey.",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: NEARColors.red),
                        ),
                        SizedBox(height: 5.h),
                        CustomButton(
                          primary: true,
                          onPressed: () async {
                            showDialog(
                              context: context,
                              builder: (context) {
                                HapticFeedback.lightImpact();
                                return LoadMintersOfCollectionDialog(
                                  nftCollectionContract: nftCollectionContract,
                                );
                              },
                            );
                          },
                          child: const Text(
                            "Load minters information",
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return RefreshIndicator(
                  onRefresh: () async {
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return LoadMintersOfCollectionDialog(
                          nftCollectionContract: nftCollectionContract,
                        );
                      },
                    );
                  },
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16).r,
                    children: [
                      SizedBox(height: 20.h),
                      Text(
                        "Your minters",
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "Last update: ${DateFormat("hh:mm").format(nftCollection.lastUpdate!)}",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: NEARColors.grey,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10.h),
                      ...nftCollection.mintersIds!
                          .map(
                            (minter) => SizedBox(
                              // height: 45.h,
                              child: Row(
                                children: [
                                  SizedBox(width: 4.h),
                                  Expanded(
                                    child: Text(minter,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold)),
                                  ),
                                  if (minter !=
                                      authController.state.accountId) ...[
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return RemoveAddMinterDialog(
                                                addAction: false,
                                                nftCollectionContract:
                                                    nftCollectionContract,
                                                minterId: minter,
                                              );
                                            },
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.remove,
                                          color: NEARColors.black,
                                        ),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
