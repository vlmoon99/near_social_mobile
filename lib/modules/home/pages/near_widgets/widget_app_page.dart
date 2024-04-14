import 'package:bos_gateway_viewer/bos_gateway_viewer.dart';
import 'package:flutter/material.dart';

class NearWidget extends StatelessWidget {
  const NearWidget({
    super.key,
    required this.nearWidgetSetupCredentials,
  });

  final NearWidgetSetupCredentials nearWidgetSetupCredentials;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BosGatewayWidget(
          widgetSettings: nearWidgetSetupCredentials.widgetSettings,
          nearAuthCreds: nearWidgetSetupCredentials.nearAuthCreds,
        ),
      ),
    );
  }
}

class NearWidgetSetupCredentials {
  final WidgetSettings widgetSettings;
  final NearAuthCreds nearAuthCreds;

  NearWidgetSetupCredentials(
      {required this.widgetSettings, required this.nearAuthCreds});
}
