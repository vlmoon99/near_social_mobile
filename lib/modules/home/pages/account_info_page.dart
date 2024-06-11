import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/models/auth_info.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class AccountInfoPage extends StatelessWidget {
  const AccountInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    final AuthInfo authInfo = authController.state;
    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset("assets/media/icons/near_social_logo.svg"),
        centerTitle: true,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).r,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SelectableText(
              "AccountId: ${authInfo.accountId}",
            ),
            SizedBox(height: 20.h),
            SelectableText(
              "PublicKey: ${authInfo.publicKey}",
            ),
            SizedBox(height: 20.h),
            SelectableText(
              "SecretKey: ${authInfo.secretKey}",
            ),
            SizedBox(height: 20.h),
            FutureBuilder(
              future: Modular.get<NearBlockChainService>()
                  .getWalletBalance(authInfo.accountId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Text(
                    "Near Amount: ${snapshot.data}",
                  );
                } else {
                  return const SpinnerLoadingIndicator();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
