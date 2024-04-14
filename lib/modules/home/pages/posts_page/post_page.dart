import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/comment_card.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/create_comment_dialog_body.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/shared_widgets/icon_button_with_counter.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';

class PostPage extends StatelessWidget {
  const PostPage(
      {super.key, required this.accountId, required this.blockHeight});

  final String accountId;
  final int blockHeight;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    final PostsController postsController = Modular.get<PostsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      runZonedGuarded(
        () {
          postsController.loadCommentsOfPost(
            accountId: accountId,
            blockHeight: blockHeight,
          );
        },
        (error, stack) {
          final AppExceptions appException = AppExceptions(
            messageForUser: "Error occurred. Please try later.",
            messageForDev: error.toString(),
            statusCode: AppErrorCodes.nearSocialApiError,
          );
          Modular.get<Catcher>().exceptionsHandler.add(appException);
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder(
            stream: postsController.stream,
            builder: (context, snapshot) {
              final post = postsController.state.posts.firstWhere(
                (element) =>
                    element.blockHeight == blockHeight &&
                    element.authorInfo.accountId == accountId,
              );
              return ListView(
                padding: REdgeInsets.all(15),
                children: [
                  Row(
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
                          placeholder: Image.asset(
                            NearAssets.standartAvatar,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          "${post.authorInfo.name} @${post.authorInfo.accountId}",
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    post.postBody.text.trim(),
                  ),
                  if (post.postBody.mediaLink != null) ...[
                    NearNetworkImage(imageUrl: post.postBody.mediaLink!),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButtonWithCounter(
                        iconPath: NearAssets.commentIcon,
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                child: CreateCommentDialog(
                                  descriptionTitle: Text.rich(
                                    style: TextStyle(fontSize: 14.sp),
                                    TextSpan(
                                      children: [
                                        const TextSpan(text: "Answer to "),
                                        TextSpan(
                                          text: "@${post.authorInfo.accountId}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  post: post,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      IconButtonWithCounter(
                        iconPath: NearAssets.likeIcon,
                        iconActivatedPath: NearAssets.activatedLikeIcon,
                        count: post.likeList.length,
                        activated: post.likeList.any(
                          (element) =>
                              element.accountId ==
                              authController.state.accountId,
                        ),
                        onPressed: () async {
                          final String accountId =
                              authController.state.accountId;
                          final String publicKey =
                              authController.state.publicKey;
                          final String privateKey =
                              authController.state.privateKey;
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
                            Modular.get<Catcher>().exceptionsHandler.add(exc);
                          }
                        },
                      ),
                      IconButtonWithCounter(
                        iconPath: NearAssets.repostIcon,
                        count: post.repostList.length,
                        activated: post.repostList.any(
                          (element) =>
                              element.accountId ==
                              authController.state.accountId,
                        ),
                        activatedColor: Colors.green,
                        onPressed: () async {
                          final String accountId =
                              authController.state.accountId;
                          final String publicKey =
                              authController.state.publicKey;
                          final String privateKey =
                              authController.state.privateKey;
                          if (post.repostList.any(
                              (element) => element.accountId == accountId)) {
                            return;
                          }
                          showDialog(
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
                                      Modular.to.pop(true);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text("No"),
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
                                );
                              } catch (err) {
                                final exc = AppExceptions(
                                  messageForUser: "Failed to like post",
                                  messageForDev: err.toString(),
                                  statusCode: AppErrorCodes.flutterchainError,
                                );
                                Modular.get<Catcher>()
                                    .exceptionsHandler
                                    .add(exc);
                              }
                            },
                          );
                        },
                      ),
                      IconButtonWithCounter(
                        iconPath: NearAssets.shareIcon,
                        onPressed: () async {
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
                  SizedBox(height: 10.h),
                  if (post.commentList != null) ...[
                    ...post.commentList!
                        .map(
                          (comment) => CommentCard(
                            comment: comment,
                            post: post,
                          ),
                        )
                        .toList()
                  ] else ...[
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  ],
                ],
              );
            }),
      ),
    );
  }
}
