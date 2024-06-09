import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/models/auth_info.dart';
import 'package:near_social_mobile/routes/routes.dart';

class AccountInfoPage extends StatelessWidget {
  const AccountInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    final AuthInfo authInfo = authController.state;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).r,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "AccountId: ${authInfo.accountId}",
            ),
            SizedBox(height: 20.h),
            Text(
              "PublicKey: ${authInfo.publicKey}",
            ),
            SizedBox(height: 20.h),
            Text(
              "SecretKey: ${authInfo.secretKey}",
            ),
            SizedBox(height: 20.h),
            Text(
              "PrivateKey: ${authInfo.privateKey}",
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
                  return const CircularProgressIndicator();
                }
              },
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () async {
                  await authController.logout();
                  Modular.to.navigate(Routes.auth.getModule());
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
