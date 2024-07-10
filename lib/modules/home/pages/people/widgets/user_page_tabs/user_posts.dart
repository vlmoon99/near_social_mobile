import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/post_card.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

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
  bool allPostsLoaded = false;
  bool loadingMorePosts = false;

  @override
  Widget build(BuildContext context) {
    final PostsController postsController = Modular.get<PostsController>();
    return StreamBuilder(
      stream: postsController.stream,
      builder: (context, snapshot) {
        if (postsController.state.postsOfAccounts[widget.accountIdOfUser] ==
            null) {
          return const Center(child: SpinnerLoadingIndicator());
        }
        final List<Post> posts = List<Post>.from(
            postsController.state.postsOfAccounts[widget.accountIdOfUser] ??
                []);
        if (posts.isEmpty) {
          return const Center(child: Text('No posts yet'));
        }
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20).r,
          itemBuilder: (context, index) {
            if (index == posts.length) {
              return loadingMorePosts
                  ? const Center(child: SpinnerLoadingIndicator())
                  : CustomButton(
                      primary: true,
                      onPressed: allPostsLoaded
                          ? null
                          : () async {
                              try {
                                setState(() {
                                  loadingMorePosts = true;
                                });
                                final posts =
                                    await Modular.get<PostsController>()
                                        .loadMorePosts(
                                  postsOfAccountId: widget.accountIdOfUser,
                                  postsViewMode: PostsViewMode.account,
                                );
                                if (posts.isEmpty) {
                                  setState(() {
                                    allPostsLoaded = true;
                                  });
                                }
                              } catch (err) {
                                rethrow;
                              } finally {
                                setState(() {
                                  loadingMorePosts = false;
                                });
                              }
                            },
                      child: Text(
                        allPostsLoaded ? "No more posts" : "Load more posts",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
            }
            return PostCard(
              post: posts[index],
              postsViewMode: PostsViewMode.account,
              postsOfAccountId: widget.accountIdOfUser,
              allowToNavigateToPostAuthorPage:
                  posts[index].authorInfo.accountId != widget.accountIdOfUser,
              allowToNavigateToReposterAuthorPage:
                  posts[index].reposterInfo?.accountId !=
                      widget.accountIdOfUser,
            );
          },
          itemCount: posts.length + 1,
        );
      },
    );
  }
}
