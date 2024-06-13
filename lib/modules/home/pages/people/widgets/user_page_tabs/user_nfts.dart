import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/apis/models/nft.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class NftsView extends StatefulWidget {
  const NftsView({super.key, required this.accountIdOfUser});

  final String accountIdOfUser;

  @override
  State<NftsView> createState() => _NftsViewState();
}

class _NftsViewState extends State<NftsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        final UserListController userListController =
            Modular.get<UserListController>();
        final user = userListController.state
            .getUserByAccountId(accountId: widget.accountIdOfUser);
        if (user.nfts == null && !user.nftsUpdating) {
          Modular.get<UserListController>()
              .loadNftsOfAccount(accountId: widget.accountIdOfUser);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserListController userListController =
        Modular.get<UserListController>();
    return StreamBuilder(
      stream: userListController.stream,
      builder: (context, snapshot) {
        final nfts = userListController.state
            .getUserByAccountId(accountId: widget.accountIdOfUser)
            .nfts;
        if (nfts == null) {
          return const Center(child: SpinnerLoadingIndicator());
        } else if (nfts.isEmpty) {
          return const Center(child: Text('No NFTs yet'));
        } else {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20).r,
            itemBuilder: (context, index) {
              return NftCard(nft: nfts[index]);
            },
            itemCount: nfts.length,
          );
        }
      },
    );
  }
}

class NftCard extends StatelessWidget {
  const NftCard({super.key, required this.nft});

  final Nft nft;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: REdgeInsets.all(10.0),
        child: Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200.h,
              ),
              child: NearNetworkImage(
                imageUrl: nft.imageUrl,
                placeholder: const Icon(Icons.broken_image),
              ),
            ),
            if (nft.title != "") Text(nft.title),
            if (nft.description == "") Text(nft.description),
          ],
        ),
      ),
    );
  }
}
