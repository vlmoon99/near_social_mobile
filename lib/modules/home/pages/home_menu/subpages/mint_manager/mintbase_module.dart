import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/modules/home/apis/models/nft.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/mintbase_maganer_page.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/pages/all_mintbase_nfts_page.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/pages/mint_nft_page.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/pages/mintbase_collections_page.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/pages/mintbase_nft_details_and_actions_page.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/pages/minters_control_page.dart';
import 'package:near_social_mobile/routes/routes.dart';

class MintbaseModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child("/", child: (context) => const MintbaseManagerPage());
    r.child(
      Routes.home.allMintbaseNftsPage,
      child: (context) => AllMintbaseNftsPage(
        contractId: r.args.data,
      ),
    );
    r.child(
      Routes.home.nftDetailsAndActionsPage,
      child: (context) {
        final args = r.args.data as ({Nft nft, bool isOwner});
        return MintbaseNftDetailsAndActionsPage(
          nft: args.nft,
          isOwnerOfCollection: args.isOwner,
        );
      },
    );
    r.child(Routes.home.mintbaseCollectionsPage,
        child: (context) => const MintbaseCollectionsPage());
    r.child(
      Routes.home.mintersControlPage,
      child: (context) => MintbaseMintersControlPage(
        nftCollectionContract: r.args.data,
      ),
    );
    r.child(
      Routes.home.mintNftPage,
      child: (context) => MintNftPage(
        nftCollectionContract: r.args.data,
      ),
    );
  }
}
