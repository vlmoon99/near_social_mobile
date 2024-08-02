import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/filter_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

class MoreActionsForUserButton extends StatefulWidget {
  const MoreActionsForUserButton({
    super.key,
    required this.userAccountId,
  });

  final String userAccountId;

  @override
  State<MoreActionsForUserButton> createState() =>
      _MoreActionsForUserButtonState();
}

class _MoreActionsForUserButtonState extends State<MoreActionsForUserButton> {
  final textEditingControllerForReport = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    final FilterController filterController = Modular.get<FilterController>();
    return IconButton(
      onPressed: () {
        showModalBottomSheet(
          context: Modular.routerDelegate.navigatorKey.currentContext!,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ).r,
          ),
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(10.0).r,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (authController.state.accountId !=
                      widget.userAccountId) ...[
                    StreamBuilder(
                      stream: filterController.stream,
                      builder: (context, snapshot) {
                        final FiltersUtil filtersUtil = FiltersUtil(
                          filters: filterController.state,
                        );
                        final bool isBlocked =
                            filtersUtil.userIsBlocked(widget.userAccountId);
                        if (!isBlocked) {
                          return ListTile(
                            title: const Text(
                              "Block user",
                              style: TextStyle(
                                  color: NEARColors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                            leading: const Icon(Icons.person_off,
                                color: NEARColors.red),
                            onTap: () async {
                              showDialog(
                                context: Modular.routerDelegate.navigatorKey
                                    .currentContext!,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text(
                                        "Are you sure you want to block this user?",
                                        style: TextStyle(fontSize: 22)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 10),
                                    content: const Text(
                                      'You will not be able to see user\'s posts, comments and notifications. You can always unblock user later through "Blocked Users" tab in the "Settings"',
                                    ),
                                    actionsAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    actions: [
                                      CustomButton(
                                        primary: true,
                                        onPressed: () async {
                                          filterController.blockUser(
                                            accountId:
                                                authController.state.accountId,
                                            blockedAccountId:
                                                widget.userAccountId,
                                          );
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
                                          "Cancel",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ).then(
                                (value) {
                                  if (value != null && value) {
                                    Modular.to.pop(context);
                                  }
                                },
                              );
                            },
                          );
                        } else {
                          return ListTile(
                            title: const Text(
                              "Unblock user",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            leading: const Icon(Icons.person_off,
                                color: NEARColors.grey),
                            onTap: () async {
                              showDialog(
                                context: Modular.routerDelegate.navigatorKey
                                    .currentContext!,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text(
                                        "Are you sure you want to unblock this user?",
                                        style: TextStyle(fontSize: 22)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 10),
                                    actionsAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    actions: [
                                      CustomButton(
                                        primary: true,
                                        onPressed: () async {
                                          filterController.unblockUser(
                                            accountId:
                                                authController.state.accountId,
                                            blockedAccountId:
                                                widget.userAccountId,
                                          );
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
                                          "Cancel",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ).then(
                                (value) {
                                  if (value != null && value) {
                                    Modular.to.pop(context);
                                  }
                                },
                              );
                            },
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      icon: const Icon(
        Icons.more_vert,
      ),
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: WidgetStatePropertyAll(NEARColors.slate),
      ),
    );
  }
}
