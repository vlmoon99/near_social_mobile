import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/filter_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

class MoreActionsForPostButton extends StatefulWidget {
  const MoreActionsForPostButton({
    super.key,
    required this.post,
    required this.postsViewMode,
  });

  final Post post;
  final PostsViewMode postsViewMode;

  @override
  State<MoreActionsForPostButton> createState() =>
      _MoreActionsForPostButtonState();
}

class _MoreActionsForPostButtonState extends State<MoreActionsForPostButton> {
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
                  ListTile(
                    title: const Text("Share",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    leading: SvgPicture.asset(
                      NearAssets.shareIcon,
                      theme: const SvgTheme(
                        currentColor: NEARColors.slate,
                      ),
                      width: 20.h,
                      height: 20.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10).r,
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final nearSocialApi = Modular.get<NearSocialApi>();
                      final urlOfPost = nearSocialApi.getUrlOfPost(
                        accountId: widget.post.authorInfo.accountId,
                        blockHeight: widget.post.blockHeight,
                      );
                      Clipboard.setData(ClipboardData(text: urlOfPost));
                      Modular.to.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Url of post coppied to clipboard"),
                        ),
                      );
                    },
                  ),
                  if (authController.state.accountId !=
                      widget.post.authorInfo.accountId)
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
                                                  .post.authorInfo.accountId,
                                              blockHeightToReport:
                                                  widget.post.blockHeight,
                                              message:
                                                  textEditingControllerForReport
                                                      .text,
                                              reportType:
                                                  FirebaseDatabasePathKeys
                                                      .reportedPostsPath,
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
                  if (widget.postsViewMode == PostsViewMode.main &&
                      authController.state.accountId !=
                          widget.post.authorInfo.accountId) ...[
                    ListTile(
                      title: const Text(
                        "Hide this post",
                        style: TextStyle(
                            color: NEARColors.red, fontWeight: FontWeight.bold),
                      ),
                      leading: const Icon(Icons.remove_red_eye,
                          color: NEARColors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10).r,
                      ),
                      onTap: () async {
                        showDialog(
                          context: Modular
                              .routerDelegate.navigatorKey.currentContext!,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text(
                                  "Are you sure you want to hide this post?",
                                  style: TextStyle(fontSize: 22)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                              content: const Text(
                                'You can always restore them later through "Hidden content" tab in the "Settings"',
                              ),
                              actionsAlignment: MainAxisAlignment.spaceEvenly,
                              actions: [
                                CustomButton(
                                  primary: true,
                                  onPressed: () async {
                                    Modular.get<FilterController>().hidePost(
                                      accountId: authController.state.accountId,
                                      accountIdToHide:
                                          widget.post.authorInfo.accountId,
                                      blockHeightToHide:
                                          widget.post.blockHeight,
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
                    ListTile(
                      title: const Text(
                        "Hide posts of this user",
                        style: TextStyle(
                            color: NEARColors.red, fontWeight: FontWeight.bold),
                      ),
                      leading: const Icon(Icons.person_remove,
                          color: NEARColors.red),
                      onTap: () async {
                        showDialog(
                          context: Modular
                              .routerDelegate.navigatorKey.currentContext!,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text(
                                  "Are you sure you want to hide posts of this user?",
                                  style: TextStyle(fontSize: 22)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                              content: const Text(
                                'You can always restore them later through "Hidden content" tab in the "Settings"',
                              ),
                              actionsAlignment: MainAxisAlignment.spaceEvenly,
                              actions: [
                                CustomButton(
                                  primary: true,
                                  onPressed: () async {
                                    Modular.get<FilterController>()
                                        .hidePostsOfUser(
                                      accountId: authController.state.accountId,
                                      accountIdToHide:
                                          widget.post.authorInfo.accountId,
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
                  ]
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
