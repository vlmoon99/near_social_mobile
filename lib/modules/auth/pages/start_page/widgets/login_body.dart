import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/vms/core/models/authorization_credentials.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_wallet_selector/near_wallet_selector.dart';
import 'package:near_social_mobile/utils/web/is_pwa.dart'
    if (dart.library.io) 'package:near_social_mobile/utils/web/is_pwa_stub.dart';

class LoginBody extends StatefulWidget {
  const LoginBody({super.key});

  @override
  State<LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<LoginBody> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb && !isPWA) {
      NearWalletSelector().init("mainnet", "social.near").then(
        (value) async {
          final account = await NearWalletSelector().getAccount();
          if (account == null) {
            return;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            NearWalletSelector().clearCredentials();
            Modular.to.pushReplacementNamed(
              Routes.auth.getRoute(Routes.auth.encryptData),
              arguments: AuthorizationCredentials(
                account.accountId,
                account.privateKey,
              ),
            );
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CustomButton(
            primary: true,
            onPressed: () async {
              Modular.to.pushNamed(
                Routes.auth.getRoute(Routes.auth.qrReader),
              );
            },
            child: const Text(
              "Login with QR code",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (kIsWeb && !isPWA) ...[
            SizedBox(height: 10.h),
            CustomButton(
              primary: true,
              onPressed: () async {
                NearWalletSelector().showSelector();
              },
              child: const Text(
                "Login with Wallet",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
