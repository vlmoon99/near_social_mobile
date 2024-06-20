import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:near_social_mobile/modules/home/apis/models/comment.dart';
import 'package:near_social_mobile/modules/home/apis/models/general_account_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/like.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:near_social_mobile/modules/home/apis/models/reposter.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/utils/future_queue.dart';
import 'package:rxdart/rxdart.dart';

class PostsController {
  final NearSocialApi nearSocialApi;
  PostsController(this.nearSocialApi);

  final BehaviorSubject<Posts> _streamController =
      BehaviorSubject.seeded(const Posts());

  Stream<Posts> get stream => _streamController.stream;
  Posts get state => _streamController.value;

  final FutureQueue _futureQueue = FutureQueue(
    timeout: const Duration(milliseconds: 1000),
  );

  Future<void> loadPosts(
      {String? postsOfAccountId, required PostsViewMode postsViewMode}) async {
    try {
      _streamController.add(
        state.copyWith(
            status: PostLoadingStatus.loading, postsViewMode: postsViewMode),
      );

      late final List<Post> posts;

      if (postsOfAccountId != null) {
        posts = await nearSocialApi.getPosts(
          targetAccounts: [postsOfAccountId],
          limit: 10,
        );
        if (state.postsViewMode != postsViewMode) {
          return;
        }
        _streamController.add(
          state.copyWith(
            posts: posts,
            mainPosts: state.posts,
            status: PostLoadingStatus.loaded,
            postsViewMode: postsViewMode,
          ),
        );
      } else {
        if (state.postsViewMode != postsViewMode) {
          return;
        }
        posts = await nearSocialApi.getPosts();
        _streamController.add(
          state.copyWith(
            posts: posts,
            status: PostLoadingStatus.loaded,
          ),
        );
      }

      for (var indexOfPost = 0;
          indexOfPost < state.posts.length;
          indexOfPost++) {
        _loadPostsDataAsync(indexOfPost, postsViewMode);
      }
    } catch (err) {
      rethrow;
    }
  }

  void changePostsChannelToMain([String? accountId]) async {
    if (state.postsViewMode == PostsViewMode.account) {
      _streamController.add(
        state.copyWith(
          posts: state.mainPosts,
          postsOfAccounts: Map.of(state.postsOfAccounts)
            ..[accountId!] = state.posts,
          mainPosts: [],
          postsViewMode: PostsViewMode.main,
        ),
      );
    }
    if (state.postsViewMode == PostsViewMode.temporary) {
      _streamController.add(
        state.copyWith(
          posts: state.mainPosts,
          temporaryPosts: state.posts,
          postsViewMode: PostsViewMode.main,
        ),
      );
    }
  }

  Future<void> changePostsChannelToAccount(String accountId) async {
    if (state.postsOfAccounts[accountId] == null) {
      await loadPosts(
          postsOfAccountId: accountId, postsViewMode: PostsViewMode.account);
    } else {
      _streamController.add(
        state.copyWith(
          posts: state.postsOfAccounts[accountId]!,
          mainPosts: state.posts,
          postsViewMode: PostsViewMode.account,
        ),
      );
      await updatePostsOfAccount(
          postsOfAccountId: accountId, postsViewMode: PostsViewMode.account);
    }
  }

  void changePostsChannelToTemporary() async {
    _streamController.add(
      state.copyWith(
        posts: state.temporaryPosts,
        mainPosts: state.posts,
        postsViewMode: PostsViewMode.temporary,
      ),
    );
  }

  Future<void> loadAndAddSinglePostIfNotExistToTempList({
    required GeneralAccountInfo accountInfo,
    required int blockHeight,
  }) async {
    if (state.temporaryPosts.length > 1 &&
        state.temporaryPosts.any((element) =>
            element.blockHeight == blockHeight &&
            element.authorInfo.accountId == accountInfo.accountId)) {
      return;
    }

    final postBody = await nearSocialApi.getPostContent(
      accountId: accountInfo.accountId,
      blockHeight: blockHeight,
    );

    final data = await nearSocialApi.getDateOfBlockHeight(
      blockHeight: blockHeight,
    );

    final likeList = await nearSocialApi.getLikesOfPost(
        accountId: accountInfo.accountId, blockHeight: blockHeight);

    final repostList = await nearSocialApi.getRepostsOfPost(
        accountId: accountInfo.accountId, blockHeight: blockHeight);

    // if (state.postsViewMode != PostsViewMode.temporary) {
    //   return;
    // }
    _streamController.add(
      state.copyWith(
        temporaryPosts: [
          Post(
            authorInfo: accountInfo,
            postBody: postBody,
            likeList: likeList,
            repostList: repostList,
            blockHeight: blockHeight,
            date: data,
            commentList: null,
          ),
          ...state.temporaryPosts
        ],
      ),
    );
  }

  Future<List<Post>> loadMorePosts(
      {String? postsOfAccountId, required PostsViewMode postsViewMode}) async {
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
        lastBlockHeightIndexOfPosts: lastBlockHeightIndexOfPosts == -1
            ? null
            : state.posts.elementAt(lastBlockHeightIndexOfPosts).blockHeight,
        lastBlockHeightIndexOfReposts: lastBlockHeightIndexOfReposts == -1
            ? null
            : state.posts.elementAt(lastBlockHeightIndexOfReposts).blockHeight,
        targetAccounts: postsOfAccountId == null ? null : [postsOfAccountId],
      );

      posts.removeWhere(
        (post) =>
            post.blockHeight ==
                state.posts
                    .elementAt(lastBlockHeightIndexOfPosts)
                    .blockHeight ||
            post.blockHeight ==
                state.posts
                    .elementAt(lastBlockHeightIndexOfReposts)
                    .blockHeight,
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
        _loadPostsDataAsync(indexOfPost, postsViewMode);
      }

      return posts;
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
      {required String accountId,
      required int blockHeight,
      required PostsViewMode postsViewMode}) async {
    try {
      final int indexOfPost = state.posts.indexWhere((element) {
        return element.blockHeight == blockHeight &&
            element.authorInfo.accountId == accountId;
      });

      final commentsOfPost = await nearSocialApi.getCommentsOfPost(
        accountId: accountId,
        blockHeight: blockHeight,
      );
      if (state.postsViewMode != postsViewMode) {
        return;
      }
      _streamController.add(
        state.copyWith(
          posts: List.of(state.posts)
            ..[indexOfPost] =
                state.posts[indexOfPost].copyWith(commentList: commentsOfPost),
        ),
      );

      for (var indexOfComment = 0;
          indexOfComment < commentsOfPost.length;
          indexOfComment++) {
        _loadCommentsDataAsync(indexOfPost, indexOfComment, postsViewMode);
      }
      // }
    } catch (err) {
      rethrow;
    }
  }

  Future<void> updateCommentsOfPost(
      {required String accountId,
      required int blockHeight,
      required PostsViewMode postsViewMode}) async {
    final int indexOfPost = state.posts.indexWhere((element) {
      return element.blockHeight == blockHeight &&
          element.authorInfo.accountId == accountId;
    });
    final commentsOfPost = await nearSocialApi.getCommentsOfPost(
      accountId: accountId,
      blockHeight: blockHeight,
    );

    if (state.postsViewMode != postsViewMode) {
      return;
    }

    commentsOfPost.removeWhere(
      (comment) => state.posts[indexOfPost].commentList!.any(
        (element) =>
            element.blockHeight == comment.blockHeight &&
            element.authorInfo.accountId == comment.authorInfo.accountId,
      ),
    );

    _streamController.add(
      state.copyWith(
        posts: List.of(state.posts)
          ..[indexOfPost] = state.posts[indexOfPost].copyWith(commentList: [
            ...commentsOfPost,
            ...state.posts[indexOfPost].commentList!
          ]),
        status: PostLoadingStatus.loaded,
      ),
    );

    for (var i = 0; i < state.posts[indexOfPost].commentList!.length; i++) {
      _loadCommentsDataAsync(indexOfPost, i, postsViewMode);
    }
  }

  Future<void> _loadCommentsDataAsync(
      int indexOfPost, int indexOfComment, PostsViewMode postsViewMode) async {
    final Comment comment =
        state.posts[indexOfPost].commentList![indexOfComment];

    nearSocialApi
        .getCommentContent(
      accountId: comment.authorInfo.accountId,
      blockHeight: comment.blockHeight,
    )
        .then(
      (commentBody) {
        if (state.postsViewMode != postsViewMode) {
          return;
        }
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(
                commentList: List.of(state.posts[indexOfPost].commentList!)
                  ..[indexOfComment] = state
                      .posts[indexOfPost].commentList![indexOfComment]
                      .copyWith(commentBody: commentBody),
              ),
          ),
        );
      },
    );

    nearSocialApi
        .getDateOfBlockHeight(
      blockHeight: comment.blockHeight,
    )
        .then((date) {
      if (state.postsViewMode != postsViewMode) {
        return;
      }
      _streamController.add(
        state.copyWith(
          posts: List.of(state.posts)
            ..[indexOfPost] = state.posts[indexOfPost].copyWith(
              commentList: List.of(state.posts[indexOfPost].commentList!)
                ..[indexOfComment] = state
                    .posts[indexOfPost].commentList![indexOfComment]
                    .copyWith(date: date),
            ),
        ),
      );
    });

    nearSocialApi
        .getLikesOfComment(
      accountId: comment.authorInfo.accountId,
      blockHeight: comment.blockHeight,
    )
        .then(
      (likes) {
        if (state.postsViewMode != postsViewMode) {
          return;
        }
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(
                commentList: List.of(state.posts[indexOfPost].commentList!)
                  ..[indexOfComment] = state
                      .posts[indexOfPost].commentList![indexOfComment]
                      .copyWith(likeList: likes),
              ),
          ),
        );
      },
    );
  }

  Future<void> updatePostsOfAccount(
      {required String postsOfAccountId,
      required PostsViewMode postsViewMode}) async {
    try {
      final newPosts = await nearSocialApi.getPosts(
        targetAccounts: [postsOfAccountId],
        limit: 10,
      );

      newPosts.removeWhere(
        (post) => state.posts.any(
          (element) =>
              element.blockHeight == post.blockHeight &&
              element.authorInfo.accountId == post.authorInfo.accountId &&
              element.reposterInfo == post.reposterInfo,
        ),
      );
      if (state.postsViewMode != postsViewMode) {
        return;
      }
      _streamController.add(
        state.copyWith(
          posts: [...newPosts, ...state.posts],
          status: PostLoadingStatus.loaded,
        ),
      );
      for (var indexOfPost = 0;
          indexOfPost < state.posts.length;
          indexOfPost++) {
        _loadPostsDataAsync(indexOfPost, postsViewMode);
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<void> _loadPostsDataAsync(
      int indexOfPost, PostsViewMode postsViewMode) async {
    if (indexOfPost > state.posts.length) {
      return;
    }
    final post = state.posts[indexOfPost];

    await nearSocialApi
        .getPostContent(
      accountId: post.authorInfo.accountId,
      blockHeight: post.blockHeight,
    )
        .then(
      (postBody) {
        if (postsViewMode != state.postsViewMode) {
          return;
        }
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] =
                  state.posts[indexOfPost].copyWith(postBody: postBody),
          ),
        );
      },
    );

    await nearSocialApi
        .getGeneralAccountInfo(accountId: post.authorInfo.accountId)
        .then((authorInfo) {
      if (postsViewMode != state.postsViewMode) {
        return;
      }
      _streamController.add(
        state.copyWith(
          posts: List.of(state.posts)
            ..[indexOfPost] =
                state.posts[indexOfPost].copyWith(authorInfo: authorInfo),
        ),
      );
    });
    if (post.reposterInfo != null) {
      await nearSocialApi
          .getGeneralAccountInfo(accountId: post.reposterInfo!.accountId)
          .then((authorInfo) {
        if (postsViewMode != state.postsViewMode) {
          return;
        }
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
      await nearSocialApi
          .getDateOfBlockHeight(
        blockHeight: post.reposterInfo!.blockHeight,
      )
          .then((date) {
        if (postsViewMode != state.postsViewMode) {
          return;
        }
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(date: date),
          ),
        );
      });
    } else {
      await nearSocialApi
          .getDateOfBlockHeight(blockHeight: post.blockHeight)
          .then((date) {
        if (postsViewMode != state.postsViewMode) {
          return;
        }
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(date: date),
          ),
        );
      });
    }

    await nearSocialApi
        .getLikesOfPost(
            accountId: post.authorInfo.accountId, blockHeight: post.blockHeight)
        .then((likes) {
      if (postsViewMode != state.postsViewMode) {
        return;
      }
      _streamController.add(
        state.copyWith(
          posts: List.of(state.posts)
            ..[indexOfPost] = state.posts[indexOfPost].copyWith(
              likeList: likes,
            ),
        ),
      );
    });
    await nearSocialApi
        .getRepostsOfPost(
            accountId: post.authorInfo.accountId, blockHeight: post.blockHeight)
        .then((reposts) {
      if (postsViewMode != state.postsViewMode) {
        return;
      }
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
    required PostsViewMode postsViewMode,
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
        await _futureQueue.addToQueue(
          () => nearSocialApi.unlikePost(
            accountIdOfPost: post.authorInfo.accountId,
            accountId: accountId,
            blockHeight: post.blockHeight,
            publicKey: publicKey,
            privateKey: privateKey,
          ),
        );
        if (state.postsViewMode != postsViewMode) {
          return;
        }
        _streamController.add(
          state.copyWith(
            posts: List.of(state.posts)
              ..[indexOfPost] = state.posts[indexOfPost].copyWith(
                likeList: Set.of(post.likeList)
                  ..removeWhere((element) => element.accountId == accountId),
              ),
          ),
        );
      } else {
        await _futureQueue.addToQueue(
          () => nearSocialApi.likePost(
            accountIdOfPost: post.authorInfo.accountId,
            accountId: accountId,
            blockHeight: post.blockHeight,
            publicKey: publicKey,
            privateKey: privateKey,
          ),
        );
        if (state.postsViewMode != postsViewMode) {
          return;
        }
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
      }
    } catch (err) {
      if (isLiked) {
        if (state.postsViewMode != postsViewMode) {
          return;
        }
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
        if (state.postsViewMode != postsViewMode) {
          return;
        }
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
    required PostsViewMode postsViewMode,
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
        await _futureQueue.addToQueue(
          () => nearSocialApi.unlikeComment(
            accountIdOfPost: comment.authorInfo.accountId,
            accountId: accountId,
            blockHeight: comment.blockHeight,
            publicKey: publicKey,
            privateKey: privateKey,
          ),
        );
        if (state.postsViewMode != postsViewMode) {
          return;
        }
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
      } else {
        await _futureQueue.addToQueue(
          () => nearSocialApi.likeComment(
            accountIdOfPost: comment.authorInfo.accountId,
            accountId: accountId,
            blockHeight: comment.blockHeight,
            publicKey: publicKey,
            privateKey: privateKey,
          ),
        );
      }
      if (state.postsViewMode != postsViewMode) {
        return;
      }
      _streamController.add(
        state.copyWith(
          posts: List.of(state.posts)
            ..[indexOfPost] = state.posts[indexOfPost].copyWith(
              commentList: List.from(state.posts[indexOfPost].commentList ?? [])
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
    } catch (err) {
      if (isLiked) {
        if (state.postsViewMode != postsViewMode) {
          return;
        }
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
        if (state.postsViewMode != postsViewMode) {
          return;
        }
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
    required PostsViewMode postsViewMode,
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
      await _futureQueue.addToQueue(
        () => nearSocialApi.repostPost(
          accountIdOfPost: post.authorInfo.accountId,
          accountId: accountId,
          blockHeight: post.blockHeight,
          publicKey: publicKey,
          privateKey: privateKey,
        ),
      );
      if (state.postsViewMode != postsViewMode) {
        return;
      }
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
    } catch (err) {
      if (state.postsViewMode != postsViewMode) {
        return;
      }
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

enum PostsViewMode { main, account, temporary }

@immutable
class Posts {
  final List<Post> posts;
  final List<Post> temporaryPosts;
  final List<Post> mainPosts;
  final Map<String, dynamic> postsOfAccounts;
  final PostLoadingStatus status;
  final PostsViewMode postsViewMode;

  const Posts({
    this.posts = const [],
    this.mainPosts = const [],
    this.temporaryPosts = const [],
    this.postsOfAccounts = const {},
    this.status = PostLoadingStatus.initial,
    this.postsViewMode = PostsViewMode.main,
  });

  Posts copyWith({
    List<Post>? posts,
    List<Post>? mainPosts,
    List<Post>? temporaryPosts,
    Map<String, dynamic>? postsOfAccounts,
    PostLoadingStatus? status,
    PostsViewMode? postsViewMode,
  }) {
    return Posts(
      posts: posts ?? this.posts,
      postsOfAccounts: postsOfAccounts ?? this.postsOfAccounts,
      mainPosts: mainPosts ?? this.mainPosts,
      temporaryPosts: temporaryPosts ?? this.temporaryPosts,
      status: status ?? this.status,
      postsViewMode: postsViewMode ?? this.postsViewMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Posts &&
          runtimeType == other.runtimeType &&
          listEquals(posts, other.posts) &&
          listEquals(mainPosts, other.mainPosts) &&
          listEquals(temporaryPosts, other.temporaryPosts) &&
          mapEquals(postsOfAccounts, other.postsOfAccounts) &&
          status == other.status &&
          postsViewMode == other.postsViewMode;
}
