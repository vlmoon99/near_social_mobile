import 'package:bos_gateway_viewer/bos_gateway_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

class NearWidget extends StatelessWidget {
  const NearWidget({
    super.key,
    required this.nearWidgetSetupCredentials,
  });

  final NearWidgetSetupCredentials nearWidgetSetupCredentials;

  void _showOverlay(BuildContext context) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Align(
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20.0).r,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0).r,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ]),
            width: .6.sw,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Attention!',
                  style: TextStyle(
                    fontSize: 18.0.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.0.w),
                const Text(
                  'You are using a functional key. Some functions might be unavailable.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.0.w),
                CustomButton(
                  primary: true,
                  onPressed: () {
                    overlayEntry.remove();
                  },
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (nearWidgetSetupCredentials.privateKeyInfo.privateKeyTypeInfo.type ==
          PrivateKeyType.FunctionCall) _showOverlay(context);
    });
    return Scaffold(
      body: SafeArea(
        child: BosGatewayWidget(
          widgetSettings: nearWidgetSetupCredentials.widgetSettings,
          nearAuthCreds: NearAuthCreds(
            network: nearWidgetSetupCredentials.network,
            accountId: nearWidgetSetupCredentials.privateKeyInfo.publicKey,
            privateKey: nearWidgetSetupCredentials.privateKeyInfo.privateKey,
          ),
        ),
      ),
    );
  }
}

class NearWidgetSetupCredentials {
  final WidgetSettings widgetSettings;
  final NearNetwork network;
  final PrivateKeyInfo privateKeyInfo;

  NearWidgetSetupCredentials({
    required this.widgetSettings,
    required this.network,
    required this.privateKeyInfo,
  });
}
