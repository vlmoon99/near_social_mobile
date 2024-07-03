import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/modules/home/apis/models/near_widget_info.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';
import 'package:near_social_mobile/utils/near_widget_opener_interface.dart';

class NearWidgetTile extends StatelessWidget {
  const NearWidgetTile({super.key, required this.nearWidget});

  final NearWidgetInfo nearWidget;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 40.h,
        height: 40.h,
        child: NearNetworkImage(
          imageUrl: nearWidget.imageUrl,
          errorPlaceholder: Image.asset(NearAssets.widgetPlaceholder),
        ),
      ),
      title: Text(nearWidget.name != "" ? nearWidget.name : nearWidget.urlName),
      subtitle:
          nearWidget.description != "" ? Text(nearWidget.description) : null,
      onTap: () {
        HapticFeedback.lightImpact();
        openNearWidget(
          widgetPath: nearWidget.widgetPath,
        );
      },
    );
  }
}
