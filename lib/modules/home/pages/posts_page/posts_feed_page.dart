import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/create_post_dialog_body.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/post_card.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';

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
          statusCode: AppErrorCodes.nearSocialApiError,
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final PostsController postsController = Modular.get<PostsController>();
      if (postsController.state.status == PostLoadingStatus.initial) {
        runZonedGuarded(() {
          postsController.loadPosts();
        }, (error, stack) {
          final AppExceptions appException = AppExceptions(
            messageForUser: "Error occurred. Please try later.",
            messageForDev: error.toString(),
            statusCode: AppErrorCodes.nearSocialApiError,
          );
          Modular.get<Catcher>().exceptionsHandler.add(appException);
        });
      }
    });
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
                      PostCard(post: post),
                      if (postsController.state.status ==
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
