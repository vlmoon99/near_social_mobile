import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/routes/routes.dart';

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
              Modular.to.pushNamed(".${Routes.home.accountPage}");
            },
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text("Key Manager"),
            onTap: () {
              Modular.to.pushNamed(".${Routes.home.keyManagerPage}");
            },
          ),
        ],
      ),
    );
  }
}
