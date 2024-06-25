import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:photo_view/photo_view.dart';

class ImageFullScreen extends StatelessWidget {
  const ImageFullScreen({super.key, required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            PhotoView(
              imageProvider: CachedNetworkImageProvider(
                imageUrl,
                headers: const {"Referer": "https://near.social/"},
              ),
              filterQuality: FilterQuality.high,
              minScale: PhotoViewComputedScale.contained * 1.0,
              maxScale: PhotoViewComputedScale.contained * 1.0,
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 10),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Modular.to.pop();
                  },
                  color: Colors.white,
                  icon: const Icon(Icons.close_fullscreen_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
