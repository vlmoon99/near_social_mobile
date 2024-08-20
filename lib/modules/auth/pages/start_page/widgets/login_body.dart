import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

class LoginBody extends StatelessWidget {
  const LoginBody({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      primary: true,
      onPressed: () async {
        Modular.to.pushNamed(
          Routes.auth.getRoute(Routes.auth.qrReader),
        );
      },
      child: const Text(
        "Login with QR code",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
