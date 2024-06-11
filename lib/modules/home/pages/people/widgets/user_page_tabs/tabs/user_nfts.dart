import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  List<Nft>? nfts;

  @override
  void initState() {
    super.initState();
    Modular.get<UserListController>().stream.listen((userList) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) {
          final user = userList.users.firstWhere((user) =>
              user.generalAccountInfo.accountId == widget.accountIdOfUser);
          if (user.nfts == null && nfts != null) {
            Modular.get<UserListController>()
                .loadNftsOfAccount(accountIdOfUser: widget.accountIdOfUser);
          }
          setState(() {
            nfts = user.nfts;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (nfts == null) {
      return const Center(child: SpinnerLoadingIndicator());
    } else if (nfts!.isEmpty) {
      return const Center(child: Text('No NFTs yet'));
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20).r,
        itemBuilder: (context, index) {
          return NftCard(nft: nfts![index]);
        },
        itemCount: nfts!.length,
      );
    }
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
