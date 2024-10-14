import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

Future<bool> askToConfirmAction(
    {required String title, String? content}) async {
  final confirm = await showDialog<bool>(
    context: Modular.routerDelegate.navigatorKey.currentContext!,
    builder: (context) {
      return AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        content: content == null
            ? null
            : Text(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          CustomButton(
            primary: true,
            onPressed: () {
              Modular.to.pop(true);
            },
            child: const Text("Yes"),
          ),
          CustomButton(
            primary: false,
            onPressed: () {
              Modular.to.pop(false);
            },
            child: const Text("No"),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
      );
    },
  );

  return confirm ?? false;
}
