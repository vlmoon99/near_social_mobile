import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class NearNetworkImage extends StatelessWidget {
  const NearNetworkImage({
    super.key,
    required this.imageUrl,
    this.errorPlaceholder,
    this.placeholder,
    this.boxFit = BoxFit.cover,
  });

  final String imageUrl;
  final Widget? errorPlaceholder;
  final Widget? placeholder;
  final BoxFit boxFit;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      httpHeaders: const {"Referer": "https://near.social/"},
      fit: boxFit,
      errorWidget: (context, error, stackTrace) =>
          errorPlaceholder ??
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image),
            ],
          ),
      placeholder: (context, url) =>
          placeholder ??
          SizedBox(
            height: 30.h,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinnerLoadingIndicator(size: 25),
              ],
            ),
          ),
    );
  }
}
