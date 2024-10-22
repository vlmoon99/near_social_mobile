import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/vm/mintbase_controller.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/widgets/create_collection_dialog.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/widgets/transfer_collection_dialog.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/widgets/home_menu_list_tile.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';

class MintbaseCollectionsPage extends StatelessWidget {
  const MintbaseCollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MintbaseController mintbaseController =
        Modular.get<MintbaseController>();
    final AuthController authController = Modular.get<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your Mintbase Collections",
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
      ),
      body: StreamBuilder(
        stream: mintbaseController.stream,
        builder: (context, snapshot) {
          return RefreshIndicator.adaptive(
            onRefresh: () => mintbaseController
                .updateOwnCollections(authController.state.accountId),
            child: mintbaseController.state.ownCollections.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(
                            height: 1.sh -
                                (Scaffold.of(context).appBarMaxHeight ?? 0),
                            width: 1.sw,
                            child: const Center(
                                child: Text('No Mintbase Collections yet'))),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemBuilder: (context, index) {
                      final nftCollection =
                          mintbaseController.state.ownCollections[index];
                      return ExpansionTile(
                        title: Text(nftCollection.contractId),
                        enableFeedback: true,
                        visualDensity: VisualDensity.comfortable,
                        shape: const LinearBorder(),
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 16, right: 24).r,
                            child: HomeMenuListTile(
                              tile: const Icon(Icons.people),
                              title: "Minters Control",
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Modular.to.pushNamed(
                                  ".${Routes.home.mintersControlPage}",
                                  arguments: nftCollection.contractId,
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 16, right: 24).r,
                            child: HomeMenuListTile(
                              tile: const Icon(Icons.send),
                              title: "Transfer Collection",
                              onTap: () {
                                HapticFeedback.lightImpact();
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      TransferCollectionDialog(
                                    nftCollectionContract:
                                        nftCollection.contractId,
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 16, right: 24).r,
                            child: HomeMenuListTile(
                              tile:
                                  const Icon(Icons.add_photo_alternate_rounded),
                              title: "Mint NFT",
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Modular.to.pushNamed(
                                  ".${Routes.home.mintNftPage}",
                                  arguments: nftCollection.contractId,
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 16, right: 24).r,
                            child: HomeMenuListTile(
                              tile: const Icon(Icons.collections_rounded),
                              title: "NFTs",
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Modular.to.pushNamed(
                                  ".${Routes.home.allMintbaseNftsPage}",
                                  arguments: nftCollection.contractId,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                    itemCount: mintbaseController.state.ownCollections.length,
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          showDialog(
            context: context,
            builder: (context) {
              return const CreateMintbaseCollectionDialog();
            },
          );
        },
        label: const Text("Create Collection"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
