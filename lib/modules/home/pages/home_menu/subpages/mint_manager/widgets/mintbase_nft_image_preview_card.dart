import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/apis/models/nft.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';

class MintbaseNftImagePreviewCard extends StatelessWidget {
  const MintbaseNftImagePreviewCard({super.key, required this.nft});

  final Nft nft;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: REdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 100.h,
              width: 110.h,
              child: NearNetworkImage(
                imageUrl: nft.imageUrl,
                boxFit: BoxFit.fitWidth,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              nft.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(height: 3.h),
            Text(
              "ID: ${nft.tokenId}",
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
