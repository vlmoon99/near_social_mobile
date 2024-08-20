import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/widgets/home_menu_list_tile.dart';
import 'package:near_social_mobile/routes/routes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20).r,
        children: [
          HomeMenuListTile(
            tile: const Icon(Icons.person_off),
            title: "Blocked Users",
            onTap: () {
              HapticFeedback.lightImpact();
              Modular.to.pushNamed(".${Routes.home.blockedUsersPage}");
            },
          ),
          SizedBox(height: 15.h),
          HomeMenuListTile(
            tile: const Icon(Icons.disabled_visible),
            title: "Hidden Content",
            onTap: () {
              HapticFeedback.lightImpact();
              Modular.to.pushNamed(".${Routes.home.hiddenPostsPage}");
            },
          ),
        ],
      ),
    );
  }
}
