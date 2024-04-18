import 'package:bos_gateway_viewer/bos_gateway_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/modules/home/apis/models/near_widget_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';
import 'package:near_social_mobile/modules/home/pages/near_widgets/widget_app_page.dart';
import 'package:near_social_mobile/modules/home/pages/near_widgets/widgets/widgets_props_settings_dialog_body.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';

class NearWidgetTile extends StatelessWidget {
  const NearWidgetTile({super.key, required this.nearWidget});

  final NearWidgetInfo nearWidget;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox.square(
        dimension: 50.w,
        child: NearNetworkImage(
          imageUrl: nearWidget.imageUrl,
          placeholder: Image.asset(NearAssets.widgetPlaceholder),
        ),
      ),
      title: Text(nearWidget.name != "" ? nearWidget.name : nearWidget.urlName),
      subtitle:
          nearWidget.description != "" ? Text(nearWidget.description) : null,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              child: WidgetsPropsSettingsDialogBody(
                  navigateFunction: (widgetprops, privateKeyInfo) async {
                final NearWidgetSetupCredentials nearWidgetSetupCredentials =
                    NearWidgetSetupCredentials(
                  network: NearNetwork.mainnet,
                    // await getNearNetworkType() == NearNetworkType.mainnet
                    //     ? NearNetwork.mainnet
                    //     : NearNetwork.testnet,
                  privateKeyInfo: privateKeyInfo,
                  widgetSettings: WidgetSettings(
                    widgetSrc: nearWidget.widgetPath,
                    widgetProps: widgetprops,
                  ),
                );
                Modular.to.pushNamed(
                  ".${Routes.home.widgetPage}",
                  arguments: nearWidgetSetupCredentials,
                );
              }),
            );
          },
        );
      },
    );
  }
}
