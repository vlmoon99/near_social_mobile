import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:rxdart/rxdart.dart';

class AppExceptions {
  String messageForUser;
  String messageForDev;
  AppExceptions({
    required this.messageForUser,
    required this.messageForDev,
  });

  @override
  String toString() => "messageForDev$messageForDev";
}

class Catcher {
  final FlutterSecureStorage secureStorage;
  Catcher(this.secureStorage) {
    exceptionsHandler.listen((value) {
      log("exceptionsHandler catch the exception --> ${value.toString()}");
      showDialogForError(value);
    });
  }

  final exceptionsHandler = BehaviorSubject<AppExceptions>();

  void showDialogForError(
    AppExceptions exception,
  ) {
    showDialog(
      builder: (context) => AlertDialog(
        title: const Text('Error!'),
        actionsAlignment: MainAxisAlignment.center,
        content: Text(exception.messageForUser),
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

class ErrorMessageHandler {
  static String getErrorMessageForNotFlutterExceptions(dynamic error) {
    if (error is MissingPluginException) {
      return 'This feature requires a native plugin that is not available.';
    }

    return 'An error occurred. Please try again later.';
  }
}
