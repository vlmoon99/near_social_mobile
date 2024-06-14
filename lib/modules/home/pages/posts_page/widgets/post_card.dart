import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/scale_animated_iconbutton.dart';
import 'package:near_social_mobile/shared_widgets/two_states_iconbutton.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    final PostsController postsController = Modular.get<PostsController>();
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Modular.to.pushNamed(
          ".${Routes.home.postPage}?accountId=${post.authorInfo.accountId}&blockHeight=${post.blockHeight}",
        );
      },
      child: Card(
        child: Padding(
          padding: REdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  DateFormat('hh:mm a MMM dd, yyyy').format(post.date),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              if (post.reposterInfo != null) ...[
                Text(
                  "Reposted by ${post.reposterInfo?.name ?? ""} @${post.reposterInfo!.accountId}",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
              RPadding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                    "${post.authorInfo.name} @${post.authorInfo.accountId}"),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 200.h,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: NearNetworkImage(
                        imageUrl: post.authorInfo.profileImageLink,
                        errorPlaceholder: Image.asset(
                          NearAssets.standartAvatar,
                          fit: BoxFit.cover,
                        ),
                        placeholder: Stack(
                          children: [
                            Image.asset(
                              NearAssets.standartAvatar,
                              fit: BoxFit.cover,
                            ),
                            const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          Text(
                            post.postBody.text
                                .replaceAll(RegExp(r'!\[(.*?)\]\((.*?)\)'), "")
                                .replaceAll(RegExp(r'\[(.*?)\]\((.*?)\)'), "")
                                .trim(),
                          ),
                          if (post.postBody.mediaLink != null) ...[
                            NearNetworkImage(
                              imageUrl: post.postBody.mediaLink!,
                            ),
                          ],
                        ],
                      ),
                    ),
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
                        );
                      } catch (err) {
                        final exc = AppExceptions(
                          messageForUser: "Failed to like post",
                          messageForDev: err.toString(),
                          statusCode: AppErrorCodes.flutterchainError,
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
                            actions: [
                              TextButton(
                                child: const Text("Yes"),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Modular.to.pop(true);
                                },
                              ),
                              TextButton(
                                child: const Text("No"),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
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
                            );
                          } catch (err) {
                            final exc = AppExceptions(
                              messageForUser: "Failed to like post",
                              messageForDev: err.toString(),
                              statusCode: AppErrorCodes.flutterchainError,
                            );
                            throw exc;
                          }
                        },
                      );
                    },
                  ),
                  TwoStatesIconButton(
                    iconPath: NearAssets.shareIcon,
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final nearSocialApi = Modular.get<NearSocialApi>();
                      final urlOfPost = nearSocialApi.getUrlOfPost(
                        accountId: post.authorInfo.accountId,
                        blockHeight: post.blockHeight,
                      );
                      Clipboard.setData(ClipboardData(text: urlOfPost));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Url of post coppied to clipboard"),
                        ),
                      );
                    },
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
