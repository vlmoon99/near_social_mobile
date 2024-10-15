import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/key_manager/key_manager_page.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

class NoFullAccessKeyBannerBody extends StatelessWidget {
  const NoFullAccessKeyBannerBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("No Full Access Key available!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 5.h),
        const Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 16),
            children: [
              TextSpan(text: "To proceed with the operation, please add a "),
              TextSpan(
                text: "Full Access Key",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: " in the "),
              TextSpan(
                text: "Key Manager",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: " section, accessible via the "),
              TextSpan(
                text: "Menu",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: "."),
            ],
          ),
        ),
        CustomButton(
          primary: true,
          onPressed: () {
            Modular.to.pop();
            Navigator.of(Modular.routerDelegate.navigatorKey.currentContext!)
                .push(
              MaterialPageRoute(
                builder: (context) {
                  return const KeyManagerPage();
                },
              ),
            );
          },
          child: const Text(
            "Add Key",
          ),
        ),
      ],
    );
  }
}
