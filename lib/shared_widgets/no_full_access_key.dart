import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
              TextSpan(text: "To proceed with a donation, please add a "),
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
      ],
    );
  }
}