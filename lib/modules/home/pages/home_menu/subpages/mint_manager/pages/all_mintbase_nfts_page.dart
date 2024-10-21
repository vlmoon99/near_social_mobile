import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/apis/models/nft.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/vm/mintbase_controller.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/widgets/mintbase_nft_image_preview_card.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';

class AllMintbaseNftsPage extends StatelessWidget {
  const AllMintbaseNftsPage({super.key, this.contractId});

  final String? contractId;

  @override
  Widget build(BuildContext context) {
    final MintbaseController mintbaseController =
        Modular.get<MintbaseController>();
    final AuthController authController = Modular.get<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your NFTs",
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
          final nftList = contractId == null
              ? mintbaseController.state.nftList
              : mintbaseController.state.nftList.where(
                  (nft) {
                    return nft.contractId == contractId;
                  },
                );

          return RefreshIndicator.adaptive(
            onRefresh: () => mintbaseController
                .updateNftList(authController.state.accountId),
            child: nftList.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 1.sh -
                              (Scaffold.of(context).appBarMaxHeight ?? 0),
                          width: 1.sw,
                          child: const Center(
                            child: Text('No NFTs yet'),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        runSpacing: 10,
                        spacing: 10,
                        children: [
                          for (var nft in nftList)
                            GestureDetector(
                              onTap: () {
                                final ({Nft nft, bool isOwner}) args = (
                                  nft: nft,
                                  isOwner: mintbaseController
                                      .state.ownCollections
                                      .any(
                                    (collection) {
                                      return collection.contractId ==
                                          nft.contractId;
                                    },
                                  )
                                );
                                Modular.to.pushNamed(
                                  ".${Routes.home.nftDetailsAndActionsPage}",
                                  arguments: args,
                                );
                              },
                              child: MintbaseNftImagePreviewCard(
                                nft: nft,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
