import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/post_card.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';

class UserPostsView extends StatefulWidget {
  const UserPostsView({
    super.key,
    required this.accountIdOfUser,
  });

  final String accountIdOfUser;

  @override
  State<UserPostsView> createState() => _UserPostsViewState();
}

class _UserPostsViewState extends State<UserPostsView> {
  List<Post> posts = [];

  bool allPostsLoaded = false;
  bool loadingMorePosts = false;

  @override
  void initState() {
    super.initState();
    Modular.get<PostsController>().stream.listen((postState) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) {
          setState(() {
            posts = postState.posts;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Modular.get<PostsController>().state.mainPosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (posts.isEmpty) {
      return const Center(child: Text('No posts yet'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20).r,
      itemBuilder: (context, index) {
        if (index == posts.length) {
          return loadingMorePosts
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: allPostsLoaded
                      ? null
                      : () {
                          runZonedGuarded(() {
                            setState(() {
                              loadingMorePosts = true;
                            });
                            Modular.get<PostsController>()
                                .loadMorePosts(
                              postsOfAccountId: widget.accountIdOfUser,
                            )
                                .then(
                              (posts) {
                                setState(() {
                                  loadingMorePosts = false;
                                });
                                if (posts.isEmpty) {
                                  setState(() {
                                    allPostsLoaded = true;
                                  });
                                }
                              },
                            );
                          }, (error, stack) {
                            setState(() {
                              loadingMorePosts = false;
                            });
                            final AppExceptions appException = AppExceptions(
                              messageForUser:
                                  "Error occurred. Please try later.",
                              messageForDev: error.toString(),
                              statusCode: AppErrorCodes.nearSocialApiError,
                            );
                            Modular.get<Catcher>()
                                .exceptionsHandler
                                .add(appException);
                          });
                        },
                  child: allPostsLoaded
                      ? const Text("No more posts")
                      : const Text("Load more posts"),
                );
        }
        return PostCard(
          post: posts[index],
        );
      },
      itemCount: posts.length + 1,
    );
  }
}
