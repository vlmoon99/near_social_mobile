import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

class HomeMenuPage extends StatelessWidget {
  const HomeMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text("Account Information"),
            onTap: () {
              HapticFeedback.lightImpact();
              Modular.to.pushNamed(".${Routes.home.accountPage}");
            },
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text("Key Manager"),
            onTap: () {
              HapticFeedback.lightImpact();
              Modular.to.pushNamed(".${Routes.home.keyManagerPage}");
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () async {
              HapticFeedback.lightImpact();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(
                    "Are you sure you want to logout?",
                    textAlign: TextAlign.center,
                  ),
                  actionsAlignment: MainAxisAlignment.spaceEvenly,
                  actions: [
                    CustomButton(
                      primary: true,
                      onPressed: () {
                        Modular.to.pop(true);
                      },
                      child: const Text(
                        "Yes",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    CustomButton(
                      onPressed: () {
                        Modular.to.pop(false);
                      },
                      child: const Text(
                        "No",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ).then(
                (value) {
                  if (value != null && value) {
                    final AuthController authController =
                        Modular.get<AuthController>();
                    Modular.to.navigate(Routes.auth.getModule());
                    authController.logout();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
