import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class NearNetworkImage extends StatelessWidget {
  const NearNetworkImage({
    super.key,
    required this.imageUrl,
    this.errorPlaceholder,
    this.placeholder,
  });

  final String imageUrl;
  final Widget? errorPlaceholder;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      httpHeaders: const {"Referer": "https://near.social/"},
      fit: BoxFit.cover,
      errorWidget: (context, error, stackTrace) =>
          errorPlaceholder ??
          const Center(
            child: Icon(Icons.error_outline),
          ),
      placeholder: (context, url) =>
          placeholder ??
          const Center(
            child: SpinnerLoadingIndicator(size: 25),
          ),
    );
  }
}
