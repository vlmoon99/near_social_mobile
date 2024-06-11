import 'package:flutter/material.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class NearNetworkImage extends StatelessWidget {
  const NearNetworkImage({
    super.key,
    required this.imageUrl,
    this.placeholder,
  });

  final String imageUrl;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      headers: const {"Referer": "https://near.social/"},
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return placeholder ?? const SpinnerLoadingIndicator();
      },
    );
  }
}
