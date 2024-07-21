import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/modules/home/apis/models/comment.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/filter_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

class MoreActionsForCommentButton extends StatefulWidget {
  const MoreActionsForCommentButton({
    super.key,
    required this.comment,
  });

  final Comment comment;

  @override
  State<MoreActionsForCommentButton> createState() =>
      _MoreActionsForCommentButtonState();
}

class _MoreActionsForCommentButtonState
    extends State<MoreActionsForCommentButton> {
  final textEditingControllerForReport = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
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
                      widget.comment.authorInfo.accountId) ...[
                    ListTile(
                      title: const Text(
                        "Report",
                        style: TextStyle(
                            color: NEARColors.red, fontWeight: FontWeight.bold),
                      ),
                      leading: const Icon(
                        Icons.flag_outlined,
                        color: NEARColors.red,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10).r,
                      ),
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        Modular.to.pop(context);
                        showDialog(
                          context: Modular
                              .routerDelegate.navigatorKey.currentContext!,
                          builder: (context) {
                            return Dialog(
                              child: RPadding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Report",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 10.h),
                                    Container(
                                      padding: const EdgeInsets.all(10).r,
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius:
                                            BorderRadius.circular(10).r,
                                      ),
                                      child: TextField(
                                        controller:
                                            textEditingControllerForReport,
                                        maxLines: 10,
                                        decoration:
                                            const InputDecoration.collapsed(
                                          hintText: "Write your report here...",
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        CustomButton(
                                          primary: true,
                                          onPressed: () async {
                                            Modular.get<FilterController>()
                                                .sendReport(
                                              accountId: authController
                                                  .state.accountId,
                                              accountIdToReport: widget
                                                  .comment.authorInfo.accountId,
                                              blockHeightToReport:
                                                  widget.comment.blockHeight,
                                              message:
                                                  textEditingControllerForReport
                                                      .text,
                                              reportType:
                                                  FirebaseDatabasePathKeys
                                                      .reportedCommentsPath,
                                            )
                                                .then(
                                              (_) {
                                                textEditingControllerForReport
                                                    .clear();
                                                ScaffoldMessenger.of(Modular
                                                        .routerDelegate
                                                        .navigatorKey
                                                        .currentContext!)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Report sent. Thank you for your help!",
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Sending your report...",
                                                ),
                                              ),
                                            );

                                            Modular.to.pop(context);
                                          },
                                          child: const Text(
                                            "Report",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        CustomButton(
                                          onPressed: () {
                                            Modular.to.pop(context);
                                          },
                                          child: const Text(
                                            "Cancel",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    ListTile(
                      title: const Text(
                        "Block user",
                        style: TextStyle(
                            color: NEARColors.red, fontWeight: FontWeight.bold),
                      ),
                      leading:
                          const Icon(Icons.person_off, color: NEARColors.red),
                      onTap: () async {
                        showDialog(
                          context: Modular
                              .routerDelegate.navigatorKey.currentContext!,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text(
                                  "Are you sure you want to block this user?",
                                  style: TextStyle(fontSize: 22)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                              content: const Text(
                                'You can always unblock user later through "Blocked Users" tab in the "Settings"',
                              ),
                              actionsAlignment: MainAxisAlignment.spaceEvenly,
                              actions: [
                                CustomButton(
                                  primary: true,
                                  onPressed: () async {
                                    Modular.get<FilterController>().blockUser(
                                      accountId: authController.state.accountId,
                                      blockedAccountId:
                                          widget.comment.authorInfo.accountId,
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
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.more_horiz),
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: WidgetStatePropertyAll(NEARColors.grey),
      ),
    );
  }
}
