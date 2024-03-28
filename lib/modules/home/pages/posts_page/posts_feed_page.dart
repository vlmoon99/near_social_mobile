import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/create_post_dialog_body.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/icon_button_with_counter.dart';

class PostsFeedPage extends StatefulWidget {
  const PostsFeedPage({super.key});

  @override
  State<PostsFeedPage> createState() => _PostsFeedPageState();
}

class _PostsFeedPageState extends State<PostsFeedPage> {
  final _scrollController = ScrollController();

  void _onScroll() async {
    final postsConroller = Modular.get<PostsController>();
    if (_isBottom &&
        postsConroller.state.status != PostLoadingStatus.loadingMorePosts) {
      runZonedGuarded(() {
        postsConroller.loadMorePosts();
      }, (error, stack) {
        final AppExceptions appException = AppExceptions(
          messageForUser: "Error occurred. Please try later.",
          messageForDev: error.toString(),
          statusCode: AppErrorCodes.cryptoError,
        );
        Modular.get<Catcher>().exceptionsHandler.add(appException);
      });
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.8);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PostsController postsController = Modular.get<PostsController>();
    final AuthController authController = Modular.get<AuthController>();
    return Scaffold(
      body: StreamBuilder<Posts>(
        stream: postsController.stream,
        builder: (context, _) {
          final postsState = postsController.state;
          if (postsState.status == PostLoadingStatus.loaded ||
              postsState.status == PostLoadingStatus.loadingMorePosts) {
            return RefreshIndicator(
              onRefresh: () async {
                return postsController.loadPosts();
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 15).r,
                itemBuilder: (context, index) {
                  final post = postsState.posts[index];
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () {
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
                                    DateFormat('hh:mm a MMM dd, yyyy')
                                        .format(post.date),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                                if (post.reposterInfo != null) ...[
                                  Text(
                                    "Reposted by ${post.reposterInfo?.name ?? ""} @${post.reposterInfo!.accountId}",
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                                RPadding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                      "${post.authorInfo.name ?? ""} @${post.authorInfo.accountId}"),
                                ),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: 200.h,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Image.asset(
                                              "assets/media/images/standart_avatar.png",
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: ListView(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          children: [
                                            Text(
                                              post.postBody.text.trim(),
                                            ),
                                            if (post.postBody.mediaLink !=
                                                null) ...[
                                              Image.network(
                                                post.postBody.mediaLink!,
                                                headers: const {
                                                  "Referer":
                                                      "https://near.social/"
                                                },
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const CircularProgressIndicator();
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    IconButtonWithCounter(
                                      iconPath:
                                          "assets/media/icons/like_icon.svg",
                                      iconActivatedPath:
                                          "assets/media/icons/like_activated.svg",
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
                                            messageForUser:
                                                "Failed to like post",
                                            messageForDev: err.toString(),
                                            statusCode:
                                                AppErrorCodes.flutterchainError,
                                          );
                                          Modular.get<Catcher>()
                                              .exceptionsHandler
                                              .add(exc);
                                        }
                                      },
                                    ),
                                    IconButtonWithCounter(
                                      iconPath:
                                          "assets/media/icons/repost_icon.svg",
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
                                        if (post.repostList.any((element) =>
                                            element.accountId == accountId)) {
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
                                                messageForUser:
                                                    "Failed to like post",
                                                messageForDev: err.toString(),
                                                statusCode: AppErrorCodes
                                                    .flutterchainError,
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
                                      iconPath:
                                          "assets/media/icons/share_icon.svg",
                                      onPressed: () async {
                                        final nearSocialApi =
                                            Modular.get<NearSocialApi>();
                                        final urlOfPost =
                                            nearSocialApi.getUrlOfPost(
                                          accountId: post.authorInfo.accountId,
                                          blockHeight: post.blockHeight,
                                        );
                                        Clipboard.setData(
                                            ClipboardData(text: urlOfPost));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Url of post coppied to clipboard"),
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
                      ),
                      if (postsState.status ==
                              PostLoadingStatus.loadingMorePosts &&
                          index == postsState.posts.length - 1) ...[
                        const Center(child: CircularProgressIndicator()),
                      ]
                    ],
                  );
                },
                itemCount: postsState.posts.length,
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return const Dialog(
                child: CreatePostDialog(),
              );
            },
          );
        },
        child: const Icon(Icons.post_add),
      ),
    );
  }
}
