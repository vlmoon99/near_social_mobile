import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showSuccessDialog({
  required String txHash,
  required String title,
}) async {
  await showDialog(
    context: Modular.routerDelegate.navigatorKey.currentContext!,
    builder: (context) {
      return Dialog(
        insetPadding: REdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(16.0).r,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 3.h),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  children: [
                    const TextSpan(
                      text: "Txn Hash: ",
                    ),
                    TextSpan(
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(
                              Uri.parse("https://nearblocks.io/txns/$txHash"));
                        },
                      text: txHash,
                      style: const TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
