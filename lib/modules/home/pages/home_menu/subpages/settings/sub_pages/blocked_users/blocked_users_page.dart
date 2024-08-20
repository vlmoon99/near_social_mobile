import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/settings/sub_pages/widgets/bloked_user_tile.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/filter_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FilterController filterController = Modular.get<FilterController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Blocked Users",
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
      ),
      body: StreamBuilder(
        stream: filterController.stream,
        builder: (context, snapshot) {
          final blockedUsers = filterController.state.blockedAccounts;
          if (blockedUsers.isEmpty) {
            return const Center(
              child: Text("No blocked users",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(15).r,
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              return BlockedUserTile(
                accountIdOfBlockedUser: blockedUsers[index],
                actionToDoTile: "Unblock",
                actionToDoOnPressed: () {
                  showDialog(
                    context:
                        Modular.routerDelegate.navigatorKey.currentContext!,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                            "Are you sure you want to unblock @${blockedUsers[index]} ?",
                            style: const TextStyle(fontSize: 22)),
                        actionsAlignment: MainAxisAlignment.spaceEvenly,
                        actions: [
                          CustomButton(
                            primary: true,
                            onPressed: () async {
                              final AuthController authController =
                                  Modular.get<AuthController>();
                              Modular.get<FilterController>().unblockUser(
                                accountId: authController.state.accountId,
                                blockedAccountId: blockedUsers[index],
                              );
                              Modular.to.pop();
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
                              Modular.to.pop();
                            },
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
