import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:near_social_mobile/modules/home/apis/models/comment.dart';
import 'package:near_social_mobile/modules/home/apis/models/like.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:near_social_mobile/modules/home/apis/models/reposter.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:rxdart/rxdart.dart';

class PostsController {
  final NearSocialApi nearSocialApi;
  PostsController(this.nearSocialApi);

  final BehaviorSubject<Posts> _streamController =
      BehaviorSubject.seeded(const Posts());

  Stream<Posts> get stream => _streamController.stream;
  Posts get state => _streamController.value;

  Future<void> loadPosts() async {
    try {
      _streamController.add(
        state.copyWith(status: PostLoadingStatus.loading),
      );

      final posts = await nearSocialApi.getPosts();

      _streamController.add(
        state.copyWith(
          posts: posts,
          status: PostLoadingStatus.loaded,
        ),
      );

      for (var indexOfPost = 0;
          indexOfPost < state.posts.length;
          indexOfPost++) {
        _loadPostsDataAsync(indexOfPost);
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<void> loadMorePosts() async {
    try {
      log("Loading more posts");
      _streamController.add(
        state.copyWith(
          status: PostLoadingStatus.loadingMorePosts,
        ),
      );
      final lastBlockHeightIndexOfPosts =
          state.posts.lastIndexWhere((element) => element.reposterInfo == null);
      final lastBlockHeightIndexOfReposts =
          state.posts.lastIndexWhere((element) => element.reposterInfo != null);
      final posts = await nearSocialApi.getPosts(
        lastBlockHeightIndexOfPosts:
            state.posts.elementAt(lastBlockHeightIndexOfPosts).blockHeight,
        lastBlockHeightIndexOfReposts:
            state.posts.elementAt(lastBlockHeightIndexOfReposts).blockHeight,
      );

      final newPosts = [...state.posts, ...posts];
      _streamController.add(
        state.copyWith(
          posts: newPosts,
          status: PostLoadingStatus.loaded,
        ),
      );
      for (var indexOfPost = (state.posts.length - posts.length - 1);
          indexOfPost < state.posts.length;
          indexOfPost++) {
        _loadPostsDataAsync(indexOfPost);
      }
    } catch (err) {
      _streamController.add(
        state.copyWith(
          status: PostLoadingStatus.loaded,
        ),
      );
      rethrow;
    }
  }

  Future<void> loadCommentsOfPost(
      {required String accountId, required int blockHeight}) async {
    try {
      final int indexOfPost = state.posts.indexWhere((element) {
        return element.blockHeight == blockHeight &&
            element.authorInfo.accountId == accountId;
      });

      if (state.posts[indexOfPost].commentList != null) {
        nearSocialApi
            .getCommentsOfPost(
          accountId: accountId,
          blockHeight: blockHeight,
        )
            .then((commentsOfPost) {
          _streamController.add(
            state.copyWith(
              posts: List.of(state.posts)
                ..[indexOfPost] = state.posts[indexOfPost]
                    .copyWith(commentList: commentsOfPost),
            ),
          );
        });
      } else {
        final commentsOfPost = await nearSocialApi.getCommentsOfPost(
          accountId: accountId,
          blockHeight: blockHeight,
        );

        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost]
                  .copyWith(commentList: commentsOfPost),
          ),
        );
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<void> _loadPostsDataAsync(int indexOfPost) async {
    final post = state.posts[indexOfPost];

    nearSocialApi
        .getPostContent(
      accountId: post.authorInfo.accountId,
      blockHeight: post.blockHeight,
    )
        .then(
      (postBody) {
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] =
                  state.posts[indexOfPost].copyWith(postBody: postBody),
          ),
        );
      },
    );

    nearSocialApi
        .getGeneralAccountInfo(accountId: post.authorInfo.accountId)
        .then((authorInfo) {
      _streamController.add(
        state.copyWith(
          posts: List.of(state.posts)
            ..[indexOfPost] =
                state.posts[indexOfPost].copyWith(authorInfo: authorInfo),
        ),
      );
    });
    if (post.reposterInfo != null) {
      nearSocialApi
          .getGeneralAccountInfo(accountId: post.reposterInfo!.accountId)
          .then((authorInfo) {
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(
                reposterInfo:
                    post.reposterInfo!.copyWith(name: authorInfo.name),
              ),
          ),
        );
      });
      nearSocialApi
          .getDateOfBlockHeight(
        blockHeight: post.reposterInfo!.blockHeight,
      )
          .then((date) {
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(date: date),
          ),
        );
      });
    } else {
      nearSocialApi
          .getDateOfBlockHeight(blockHeight: post.blockHeight)
          .then((date) {
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(date: date),
          ),
        );
      });
    }

    nearSocialApi
        .getLikesOfPost(
            accountId: post.authorInfo.accountId, blockHeight: post.blockHeight)
        .then((likes) {
      _streamController.add(
        state.copyWith(
          posts: List.of(state.posts)
            ..[indexOfPost] = state.posts[indexOfPost].copyWith(
              likeList: likes,
            ),
        ),
      );
    });
    nearSocialApi
        .getRepostsOfPost(
            accountId: post.authorInfo.accountId, blockHeight: post.blockHeight)
        .then((reposts) {
      _streamController.add(
        state.copyWith(
          posts: List.of(state.posts)
            ..[indexOfPost] = state.posts[indexOfPost].copyWith(
              repostList: reposts,
            ),
        ),
      );
    });
  }

  Future<void> likePost({
    required Post post,
    required String accountId,
    required String publicKey,
    required String privateKey,
  }) async {
    final isLiked =
        post.likeList.any((element) => element.accountId == accountId);
    final indexOfPost = state.posts.indexWhere(
      (element) =>
          element.blockHeight == post.blockHeight &&
          element.authorInfo.accountId == post.authorInfo.accountId &&
          element.reposterInfo == post.reposterInfo,
    );
    try {
      if (isLiked) {
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(
                likeList: Set.of(post.likeList)
                  ..removeWhere((element) => element.accountId == accountId),
              ),
          ),
        );
        await nearSocialApi.unlikePost(
          accountIdOfPost: post.authorInfo.accountId,
          accountId: accountId,
          blockHeight: post.blockHeight,
          publicKey: publicKey,
          privateKey: privateKey,
        );
      } else {
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(
                likeList: Set.of(post.likeList)
                  ..add(
                    Like(accountId: accountId),
                  ),
              ),
          ),
        );
        await nearSocialApi.likePost(
          accountIdOfPost: post.authorInfo.accountId,
          accountId: accountId,
          blockHeight: post.blockHeight,
          publicKey: publicKey,
          privateKey: privateKey,
        );
      }
    } catch (err) {
      if (isLiked) {
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(
                likeList: Set.of(post.likeList)
                  ..add(
                    Like(accountId: accountId),
                  ),
              ),
          ),
        );
      } else {
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(
                likeList: Set.of(post.likeList)
                  ..removeWhere((element) => element.accountId == accountId),
              ),
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> likeComment({
    required Post post,
    required Comment comment,
    required String accountId,
    required String publicKey,
    required String privateKey,
  }) async {
    final indexOfPost = state.posts.indexWhere(
      (element) =>
          element.blockHeight == post.blockHeight &&
          element.authorInfo.accountId == post.authorInfo.accountId &&
          element.reposterInfo == post.reposterInfo,
    );
    final indexOfComment = post.commentList!.indexWhere(
      (element) =>
          element.blockHeight == comment.blockHeight &&
          element.authorInfo.accountId == comment.authorInfo.accountId,
    );
    final isLiked = post.commentList![indexOfComment].likeList
        .any((element) => element.accountId == accountId);

    try {
      if (isLiked) {
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(
                commentList:
                    List.from(state.posts[indexOfPost].commentList ?? [])
                      ..[indexOfComment] = comment.copyWith(
                        likeList: comment.likeList
                          ..removeWhere(
                            (element) => element.accountId == accountId,
                          ),
                      ),
              ),
          ),
        );
        await nearSocialApi.unlikeComment(
          accountIdOfPost: comment.authorInfo.accountId,
          accountId: accountId,
          blockHeight: comment.blockHeight,
          publicKey: publicKey,
          privateKey: privateKey,
        );
      } else {
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(
                commentList:
                    List.from(state.posts[indexOfPost].commentList ?? [])
                      ..[indexOfComment] = comment.copyWith(
                        likeList: comment.likeList
                          ..add(
                            Like(
                              accountId: accountId,
                            ),
                          ),
                      ),
              ),
          ),
        );
        await nearSocialApi.likeComment(
          accountIdOfPost: comment.authorInfo.accountId,
          accountId: accountId,
          blockHeight: comment.blockHeight,
          publicKey: publicKey,
          privateKey: privateKey,
        );
      }
    } catch (err) {
      if (isLiked) {
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(
                commentList:
                    List.from(state.posts[indexOfPost].commentList ?? [])
                      ..[indexOfComment] = comment.copyWith(
                        likeList: comment.likeList
                          ..add(
                            Like(
                              accountId: accountId,
                            ),
                          ),
                      ),
              ),
          ),
        );
      } else {
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(
                commentList:
                    List.from(state.posts[indexOfPost].commentList ?? [])
                      ..[indexOfComment] = comment.copyWith(
                        likeList: comment.likeList
                          ..removeWhere(
                            (element) => element.accountId == accountId,
                          ),
                      ),
              ),
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> repostPost({
    required Post post,
    required String accountId,
    required String publicKey,
    required String privateKey,
  }) async {
    if (post.repostList.any((element) => element.accountId == accountId)) {
      return;
    }
    final indexOfPost = state.posts.indexWhere(
      (element) =>
          element.blockHeight == post.blockHeight &&
          element.authorInfo.accountId == post.authorInfo.accountId &&
          element.reposterInfo == post.reposterInfo,
    );
    try {
      _streamController.add(
        state.copyWith(
          posts: List.of(state.posts)
            ..[indexOfPost] = state.posts[indexOfPost].copyWith(
              repostList: Set.of(post.repostList)
                ..add(
                  Reposter(accountId: accountId),
                ),
            ),
        ),
      );
      await nearSocialApi.repostPost(
        accountIdOfPost: post.authorInfo.accountId,
        accountId: accountId,
        blockHeight: post.blockHeight,
        publicKey: publicKey,
        privateKey: privateKey,
      );
    } catch (err) {
      _streamController.add(
        state.copyWith(
          posts: List.of(state.posts)
            ..[indexOfPost] = state.posts[indexOfPost].copyWith(
              repostList: Set.of(post.repostList)
                ..removeWhere((element) => element.accountId == accountId),
            ),
        ),
      );
      rethrow;
    }
  }
}

enum PostLoadingStatus {
  initial,
  loading,
  loadingMorePosts,
  loaded,
}

@immutable
class Posts {
  final List<Post> posts;
  final PostLoadingStatus status;

  const Posts({
    this.posts = const [],
    this.status = PostLoadingStatus.initial,
  });

  Posts copyWith({
    List<Post>? posts,
    PostLoadingStatus? status,
  }) {
    return Posts(
      posts: posts ?? this.posts,
      status: status ?? this.status,
    );
  }
}
