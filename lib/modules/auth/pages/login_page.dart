import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/assets/localizations/localizations_strings.dart';
import 'package:near_social_mobile/routes/routes.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          LocalizationsStrings.auth.login.title,
        ).tr(),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            Modular.to.navigate(Routes.home.getModule());
          },
          child: const Text(
            "Go to the home module",
          ),
        ),
      ),
    );
  }
}
