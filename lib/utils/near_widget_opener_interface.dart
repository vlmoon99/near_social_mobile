import 'package:bos_gateway_viewer/bos_gateway_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/modules/home/pages/near_widgets/widget_app_page.dart';
import 'package:near_social_mobile/modules/home/pages/near_widgets/widgets/widgets_props_settings_dialog_body.dart';
import 'package:near_social_mobile/routes/routes.dart';

Future<dynamic> openNearWidget(
    {required String widgetPath, String? initWidgetProps}) async {
  return showDialog(
    context: Modular.routerDelegate.navigatorKey.currentContext!,
    builder: (context) {
      return Dialog(
        child: WidgetsPropsSettingsDialogBody(
            initWidgetProps: initWidgetProps,
            navigateFunction: (widgetprops, privateKeyInfo) async {
              final NearWidgetSetupCredentials nearWidgetSetupCredentials =
                  NearWidgetSetupCredentials(
                network: NearNetwork.mainnet,
                privateKeyInfo: privateKeyInfo,
                widgetSettings: WidgetSettings(
                  widgetSrc: widgetPath,
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
}
