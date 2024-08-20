import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

Future<void> checkForJailbreak() async {
  final jailBreakedDevice = await FlutterJailbreakDetection.jailbroken;
  if (jailBreakedDevice) {
    showDialog(
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(
          "This device is ${Platform.isIOS ? 'jailbroken' : 'rooted'}. The security of the data in this application is not guaranteed.",
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          CustomButton(
            primary: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      context: Modular.routerDelegate.navigatorKey.currentContext!,
    );
  }
}
