import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class NearNetworkImage extends StatefulWidget {
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
  State<NearNetworkImage> createState() => _NearNetworkImageState();
}

class _NearNetworkImageState extends State<NearNetworkImage>
    with AutomaticKeepAliveClientMixin {
  final httpHeaders = const {"Referer": "https://near.social/"};

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      httpHeaders: httpHeaders,
      fit: widget.boxFit,
      errorWidget: (context, error, stackTrace) {
        if (stackTrace.toString().contains("Invalid image data")) {
          return SvgPictureSupport(
            imageUrl: widget.imageUrl,
            headers: httpHeaders,
            placeholder: widget.errorPlaceholder ??
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image),
                  ],
                ),
          );
        }
        return widget.errorPlaceholder ??
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image),
              ],
            );
      },
      placeholder: (context, url) =>
          widget.placeholder ??
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

  @override
  bool get wantKeepAlive => true;
}

class SvgPictureSupport extends StatelessWidget {
  const SvgPictureSupport({
    super.key,
    required this.imageUrl,
    required this.headers,
    required this.placeholder,
  });

  final String imageUrl;
  final Map<String, String>? headers;
  final Widget placeholder;

  Future<Uint8List> loadAsset() async {
    try {
      final file =
          await DefaultCacheManager().getSingleFile(imageUrl, headers: headers);
      if (file.path.endsWith(".svg")) {
        return file.readAsBytesSync();
      } else {
        return Uint8List.fromList([]);
      }
    } catch (err) {
      return Uint8List.fromList([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: loadAsset(),
      builder: (context, snapshot) {
        return AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 500,
          ),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: snapshot.data != null && snapshot.data!.isNotEmpty
              ? SvgPicture.memory(snapshot.data!)
              : placeholder,
        );
      },
    );
  }
}
