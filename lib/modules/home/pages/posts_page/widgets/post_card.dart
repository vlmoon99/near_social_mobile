import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/more_actions_for_post_button.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/raw_text_to_content_formatter.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/scale_animated_iconbutton.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';
import 'package:near_social_mobile/utils/date_to_string.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.postsViewMode,
    this.postsOfAccountId,
    this.allowToNavigateToPostAuthorPage = true,
    this.allowToNavigateToReposterAuthorPage = true,
  });
  final Post post;
  final PostsViewMode postsViewMode;
  final String? postsOfAccountId;
  final bool allowToNavigateToPostAuthorPage;
  final bool allowToNavigateToReposterAuthorPage;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    final PostsController postsController = Modular.get<PostsController>();
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Modular.to.pushNamed(
          ".${Routes.home.postPage}?accountId=${post.authorInfo.accountId}&blockHeight=${post.blockHeight}&postsViewMode=${postsViewMode.index}&postsOfAccountId=${postsOfAccountId ?? ""}&allowToNavigateToPostAuthorPage=$allowToNavigateToPostAuthorPage",
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0).r,
        ),
        elevation: 5,
        child: Padding(
          padding: REdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatDateDependingOnCurrentTime(post.date),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
              if (post.reposterInfo != null) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(10).r,
                  onTap: allowToNavigateToReposterAuthorPage
                      ? () async {
                          HapticFeedback.lightImpact();
                          await Modular.get<UserListController>()
                              .addGeneralAccountInfoIfNotExists(
                            generalAccountInfo: post.reposterInfo!.accountInfo,
                          );
                          Modular.to.pushNamed(
                            ".${Routes.home.userPage}?accountId=${post.reposterInfo!.accountInfo.accountId}",
                          );
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3).r,
                    child: Text(
                      "Reposted by ${post.reposterInfo?.accountInfo.name ?? ""} @${post.reposterInfo!.accountInfo.accountId}",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ],
              InkWell(
                borderRadius: BorderRadius.circular(10).r,
                onTap: allowToNavigateToPostAuthorPage
                    ? () async {
                        HapticFeedback.lightImpact();
                        await Modular.get<UserListController>()
                            .addGeneralAccountInfoIfNotExists(
                          generalAccountInfo: post.authorInfo,
                        );
                        Modular.to.pushNamed(
                          ".${Routes.home.userPage}?accountId=${post.authorInfo.accountId}",
                        );
                      }
                    : null,
                child: SizedBox(
                  height: 37.h,
                  child: Row(
                    children: [
                      Container(
                        width: 35.h,
                        height: 35.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10).r,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: NearNetworkImage(
                          imageUrl: post.authorInfo.profileImageLink,
                          errorPlaceholder: Image.asset(
                            NearAssets.standartAvatar,
                            fit: BoxFit.cover,
                          ),
                          placeholder: Image.asset(
                            NearAssets.standartAvatar,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.h),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (post.authorInfo.name != "")
                              Text(
                                post.authorInfo.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            Text(
                              "@${post.authorInfo.accountId}",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: post.authorInfo.name != ""
                                  ? const TextStyle(
                                      color: NEARColors.grey,
                                      fontSize: 13,
                                    )
                                  : const TextStyle(
                                      fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 200.h,
                ),
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    RawTextToContentFormatter(
                      rawText: post.postBody.text.trim(),
                      heroAnimForImages: false,
                      imageHeight: .5.sh,
                      responsive: false,
                    ),
                    if (post.postBody.mediaLink != null) ...[
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: .5.sh),
                        child: NearNetworkImage(
                          imageUrl: post.postBody.mediaLink!,
                          boxFit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ScaleAnimatedIconButtonWithCounter(
                    iconPath: NearAssets.likeIcon,
                    iconActivatedPath: NearAssets.activatedLikeIcon,
                    activated: post.likeList.any(
                      (element) =>
                          element.accountId == authController.state.accountId,
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final String accountId = authController.state.accountId;
                      final String publicKey = authController.state.publicKey;
                      final String privateKey = authController.state.privateKey;
                      try {
                        await postsController.likePost(
                          post: post,
                          accountId: accountId,
                          publicKey: publicKey,
                          privateKey: privateKey,
                          postsViewMode: postsViewMode,
                          postsOfAccountId: postsOfAccountId,
                        );
                      } catch (err) {
                        final exc = AppExceptions(
                          messageForUser: "Failed to like post",
                          messageForDev: err.toString(),
                        );
                        throw exc;
                      }
                    },
                    count: post.likeList.length,
                  ),
                  ScaleAnimatedIconButtonWithCounter(
                    iconPath: NearAssets.repostIcon,
                    count: post.repostList.length,
                    activated: post.repostList.any(
                      (element) =>
                          element.accountId == authController.state.accountId,
                    ),
                    activatedColor: Colors.green,
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final String accountId = authController.state.accountId;
                      final String publicKey = authController.state.publicKey;
                      final String privateKey = authController.state.privateKey;
                      if (post.repostList
                          .any((element) => element.accountId == accountId)) {
                        return;
                      }
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text(
                              "Repost",
                            ),
                            content: const Text(
                              "Are you sure you want to repost this post?",
                            ),
                            actionsAlignment: MainAxisAlignment.spaceEvenly,
                            actions: [
                              CustomButton(
                                primary: true,
                                child: const Text(
                                  "Yes",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  Modular.to.pop(true);
                                },
                              ),
                              CustomButton(
                                child: const Text(
                                  "No",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  Modular.to.pop(false);
                                },
                              ),
                            ],
                          );
                        },
                      ).then(
                        (answer) async {
                          if (answer == null || !answer) {
                            return;
                          }
                          try {
                            await postsController.repostPost(
                              post: post,
                              accountId: accountId,
                              publicKey: publicKey,
                              privateKey: privateKey,
                              postsViewMode: postsViewMode,
                              postsOfAccountId: postsOfAccountId,
                            );
                          } catch (err) {
                            final exc = AppExceptions(
                              messageForUser: "Failed to repost post",
                              messageForDev: err.toString(),
                            );
                            throw exc;
                          }
                        },
                      );
                    },
                  ),
                  MoreActionsForPostButton(
                    post: post,
                    postsViewMode: postsViewMode,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
