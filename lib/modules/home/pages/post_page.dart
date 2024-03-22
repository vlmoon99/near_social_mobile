import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/shared_widgets/icon_button_with_counter.dart';

class PostPage extends StatelessWidget {
  const PostPage(
      {super.key, required this.accountId, required this.blockHeight});

  // final Post post;

  final String accountId;
  final int blockHeight;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    final PostsController postsController = Modular.get<PostsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      postsController.loadCommentsOfPost(
        accountId: accountId,
        blockHeight: blockHeight,
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
                        child: Image.network(
                          fit: BoxFit.cover,
                          post.authorInfo.profileImageLink,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              "assets/media/images/standart_avatar.png",
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          "${post.authorInfo.name ?? ""} @${post.authorInfo.accountId}",
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    post.postBody.text.trim(),
                  ),
                  if (post.postBody.mediaLink != null) ...[
                    Image.network(
                      post.postBody.mediaLink!,
                      headers: const {"Referer": "https://near.social/"},
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const CircularProgressIndicator();
                      },
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButtonWithCounter(
                        iconPath: "assets/media/icons/comment_icon.svg",
                        onPressed: () {},
                      ),
                      IconButtonWithCounter(
                        iconPath: "assets/media/icons/like_icon.svg",
                        count: post.likeList.length,
                        activated: post.likeList.any(
                          (element) =>
                              element.accountId ==
                              authController.state.accountId,
                        ),
                        onPressed: () {},
                      ),
                      IconButtonWithCounter(
                        iconPath: "assets/media/icons/repost_icon.svg",
                        count: post.repostList.length,
                        activated: post.repostList.any(
                          (element) =>
                              element.accountId ==
                              authController.state.accountId,
                        ),
                        activatedColor: Colors.green,
                        onPressed: () {},
                      ),
                      IconButtonWithCounter(
                        iconPath: "assets/media/icons/share_icon.svg",
                        onPressed: () {},
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  if (post.commentList != null) ...[
                    ...post.commentList!.map((e) => Text(e.text)).toList()
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

// class CommentCard extends StatelessWidget {
//   const CommentCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }