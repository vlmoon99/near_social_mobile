import 'dart:developer';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:rxdart/rxdart.dart';

class AppExceptions extends Equatable {
  final String messageForUser;
  final String messageForDev;
  const AppExceptions({
    required this.messageForUser,
    required this.messageForDev,
  });

  @override
  String toString() => "messageForDev$messageForDev";

  @override
  List<Object?> get props => [messageForUser, messageForDev];
}

class Catcher {
  bool dialogIsOpen = false;
  Catcher() {
    exceptionsHandler.listen((value) {
      log("exceptionsHandler catch the exception --> ${value.toString()}");
      showDialogForError(value);
    });
  }

  final exceptionsHandler = BehaviorSubject<AppExceptions>();

  void showDialogForError(AppExceptions exception) {
    if (dialogIsOpen) {
      return;
    }
    dialogIsOpen = true;
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
    ).then(
      (_) {
        dialogIsOpen = false;
      },
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
