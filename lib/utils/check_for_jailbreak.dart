import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:flutter_modular/flutter_modular.dart';

Future<void> checkForJailbreak() async {
  final jailBreakedDevice = await FlutterJailbreakDetection.jailbroken;
  if (jailBreakedDevice) {
    showDialog(
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(
          "This device is ${Platform.isIOS ? 'jailbroken' : 'rooted'}. The security of the data in this application is not guaranteed.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
      context: Modular.routerDelegate.navigatorKey.currentContext!,
    );
  }
}
