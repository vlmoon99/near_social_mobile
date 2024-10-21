import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/apis/models/nft.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/widgets/copy_nft_dialog.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/widgets/transfer_nft_dialog.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';

class MintbaseNftDetailsAndActionsPage extends StatelessWidget {
  const MintbaseNftDetailsAndActionsPage(
      {super.key, required this.nft, bool? isOwnerOfCollection})
      : isOwnerOfCollection = isOwnerOfCollection ?? false;

  final Nft nft;
  final bool isOwnerOfCollection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            Container(
              color: Colors.black.withOpacity(.1),
              height: 0.4.sh,
              width: double.infinity,
              child: NearNetworkImage(
                imageUrl: nft.imageUrl,
                boxFit: BoxFit.scaleDown,
              ),
            ),
            SizedBox(height: 5.h),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20).r,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    nft.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    "Token ID: ${nft.tokenId}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (nft.description.isNotEmpty)
                    SelectableText(
                      "Description: ${nft.description}",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  Text.rich(
                    style: Theme.of(context).textTheme.titleMedium,
                    TextSpan(
                      text: "Collection: ",
                      children: [
                        TextSpan(
                          text: nft.contractId,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10.h,
                      runSpacing: 10.h,
                      children: [
                        CustomButton(
                          primary: true,
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            showDialog(
                              context: context,
                              builder: (context) {
                                return TransferNftDialog(
                                  nft: nft,
                                );
                              },
                            );
                          },
                          child: const Text(
                            "Transfer NFT",
                          ),
                        ),
                        if (isOwnerOfCollection)
                        CustomButton(
                          primary: true,
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            showDialog(
                              context: context,
                              builder: (context) {
                                return CopyNftDialog(
                                  nft: nft,
                                );
                              },
                            );
                          },
                          child: const Text(
                            "Copy NFT",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
