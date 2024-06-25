import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:near_social_mobile/modules/home/apis/models/comment.dart';
import 'package:near_social_mobile/modules/home/apis/models/general_account_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/like.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:near_social_mobile/modules/home/apis/models/reposter.dart';
import 'package:near_social_mobile/modules/home/apis/models/reposter_info.dart';
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
          status: PostLoadingStatus.loading,
        ),
      );

      final List<Post> posts = await nearSocialApi.getPosts(
        targetAccounts: postsOfAccountId == null ? null : [postsOfAccountId],
        limit: 10,
      );
      switch (postsViewMode) {
        case PostsViewMode.main:
          {
            _streamController.add(
              state.copyWith(
                posts: posts,
                status: PostLoadingStatus.loaded,
              ),
            );
            for (var indexOfPost = 0;
                indexOfPost < state.posts.length;
                indexOfPost++) {
              _loadPostsDataAsync(indexOfPost, postsViewMode);
            }
            break;
          }
        case PostsViewMode.account:
          {
            _streamController.add(
              state.copyWith(
                postsOfAccounts: Map.of(state.postsOfAccounts)
                  ..[postsOfAccountId!] = posts,
                status: PostLoadingStatus.loaded,
              ),
            );
            for (var indexOfPost = 0;
                indexOfPost < state.postsOfAccounts[postsOfAccountId].length;
                indexOfPost++) {
              _loadPostsDataAsync(indexOfPost, postsViewMode, postsOfAccountId);
            }
            break;
          }
        case PostsViewMode.temporary:
          {
            // Not needed
            break;
          }
      }
    } catch (err) {
      rethrow;
    }
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

  List<Post> getPostsDueToPostsViewMode(PostsViewMode postsViewMode,
      [String? postsOfAccountId]) {
    late final List<Post> choosedPosts;

    switch (postsViewMode) {
      case PostsViewMode.main:
        {
          choosedPosts = state.posts;
          break;
        }
      case PostsViewMode.account:
        {
          choosedPosts =
              List<Post>.from(state.postsOfAccounts[postsOfAccountId]!);
          break;
        }
      case PostsViewMode.temporary:
        {
          choosedPosts = state.temporaryPosts;
          break;
        }
    }
    return choosedPosts;
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

      final List<Post> choosedPosts = getPostsDueToPostsViewMode(
        postsViewMode,
        postsOfAccountId,
      );

      final lastBlockHeightIndexOfPosts = choosedPosts
          .lastIndexWhere((element) => element.reposterInfo == null);
      final lastBlockHeightIndexOfReposts = choosedPosts
          .lastIndexWhere((element) => element.reposterInfo != null);
      final posts = await nearSocialApi.getPosts(
        lastBlockHeightIndexOfPosts: lastBlockHeightIndexOfPosts == -1
            ? null
            : choosedPosts.elementAt(lastBlockHeightIndexOfPosts).blockHeight,
        lastBlockHeightIndexOfReposts: lastBlockHeightIndexOfReposts == -1
            ? null
            : choosedPosts.elementAt(lastBlockHeightIndexOfReposts).blockHeight,
        targetAccounts: postsOfAccountId == null ? null : [postsOfAccountId],
      );

      posts.removeWhere(
        (post) =>
            post.blockHeight ==
                choosedPosts
                    .elementAt(lastBlockHeightIndexOfPosts)
                    .blockHeight ||
            post.blockHeight ==
                choosedPosts
                    .elementAt(lastBlockHeightIndexOfReposts)
                    .blockHeight,
      );

      final newPosts = [...choosedPosts, ...posts];

      switch (postsViewMode) {
        case PostsViewMode.main:
          {
            _streamController.add(
              state.copyWith(
                posts: newPosts,
                status: PostLoadingStatus.loaded,
              ),
            );
            break;
          }
        case PostsViewMode.account:
          {
            _streamController.add(
              state.copyWith(
                postsOfAccounts: Map.of(state.postsOfAccounts)
                  ..[postsOfAccountId!] = newPosts,
                status: PostLoadingStatus.loaded,
              ),
            );
            break;
          }
        case PostsViewMode.temporary:
          {
            _streamController.add(
              state.copyWith(
                temporaryPosts: newPosts,
                status: PostLoadingStatus.loaded,
              ),
            );
            break;
          }
      }

      for (var indexOfPost = (newPosts.length - posts.length - 1);
          indexOfPost < newPosts.length;
          indexOfPost++) {
        _loadPostsDataAsync(indexOfPost, postsViewMode, postsOfAccountId);
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

  Future<void> loadCommentsOfPost({
    required String accountId,
    required int blockHeight,
    String? postsOfAccountId,
    required PostsViewMode postsViewMode,
  }) async {
    try {
      late final Post post;

      switch (postsViewMode) {
        case PostsViewMode.main:
          {
            post = state.posts.firstWhere(
              (element) =>
                  element.blockHeight == blockHeight &&
                  element.authorInfo.accountId == accountId,
            );
            break;
          }
        case PostsViewMode.account:
          {
            post = state.postsOfAccounts[postsOfAccountId]!.firstWhere(
              (element) =>
                  element.blockHeight == blockHeight &&
                  element.authorInfo.accountId == accountId,
            );
            break;
          }
        case PostsViewMode.temporary:
          {
            post = state.temporaryPosts.firstWhere(
              (element) =>
                  element.blockHeight == blockHeight &&
                  element.authorInfo.accountId == accountId,
            );
            break;
          }
      }

      final commentsOfPost = await nearSocialApi.getCommentsOfPost(
        accountId: accountId,
        blockHeight: blockHeight,
      );

      _updateDataDueToPostsViewMode(
          post: post,
          commentList: commentsOfPost,
          postsViewMode: postsViewMode,
          postsOfAccountId: postsOfAccountId);

      for (var indexOfComment = 0;
          indexOfComment < commentsOfPost.length;
          indexOfComment++) {
        _loadCommentsDataAsync(
            post, indexOfComment, postsViewMode, postsOfAccountId);
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<void> updateCommentsOfPost({
    required String accountId,
    required int blockHeight,
    required PostsViewMode postsViewMode,
    String? postsOfAccountId,
  }) async {
    late final Post post;

    switch (postsViewMode) {
      case PostsViewMode.main:
        {
          post = state.posts.firstWhere(
            (element) =>
                element.blockHeight == blockHeight &&
                element.authorInfo.accountId == accountId,
          );
          break;
        }
      case PostsViewMode.account:
        {
          post = state.postsOfAccounts[postsOfAccountId]!.firstWhere(
            (element) =>
                element.blockHeight == blockHeight &&
                element.authorInfo.accountId == accountId,
          );
          break;
        }
      case PostsViewMode.temporary:
        {
          post = state.temporaryPosts.firstWhere(
            (element) =>
                element.blockHeight == blockHeight &&
                element.authorInfo.accountId == accountId,
          );
          break;
        }
    }
    final int indexOfPost = _getIndexOfPost(post, postsViewMode);

    final newCommentsOfPost = await nearSocialApi.getCommentsOfPost(
      accountId: accountId,
      blockHeight: blockHeight,
    );

    late final List<Comment> commentsOfPost;
    switch (postsViewMode) {
      case PostsViewMode.main:
        {
          commentsOfPost = state.posts[indexOfPost].commentList!;
          break;
        }
      case PostsViewMode.account:
        {
          commentsOfPost = state
              .postsOfAccounts[postsOfAccountId]![indexOfPost].commentList!;
          break;
        }
      case PostsViewMode.temporary:
        {
          commentsOfPost = state.temporaryPosts[indexOfPost].commentList!;
          break;
        }
    }

    newCommentsOfPost.removeWhere(
      (comment) => commentsOfPost.any(
        (element) =>
            element.blockHeight == comment.blockHeight &&
            element.authorInfo.accountId == comment.authorInfo.accountId,
      ),
    );

    final finalCommentsOfPost = [...newCommentsOfPost, ...commentsOfPost];

    _updateDataDueToPostsViewMode(
      postsViewMode: postsViewMode,
      post: post,
      commentList: finalCommentsOfPost,
      postsOfAccountId: postsOfAccountId,
    );

    for (var i = 0; i < finalCommentsOfPost.length; i++) {
      _loadCommentsDataAsync(post, i, postsViewMode, postsOfAccountId);
    }
  }

  Future<void> _loadCommentsDataAsync(
      Post post, int indexOfComment, PostsViewMode postsViewMode,
      [String? postsOfAccountId]) async {
    final int indexOfPost = _getIndexOfPost(post, postsViewMode);
    late final Comment comment;

    switch (postsViewMode) {
      case PostsViewMode.main:
        {
          comment = state.posts[indexOfPost].commentList![indexOfComment];
          break;
        }
      case PostsViewMode.account:
        {
          comment = state.postsOfAccounts[postsOfAccountId]![indexOfPost]
              .commentList![indexOfComment];
          break;
        }
      case PostsViewMode.temporary:
        {
          comment =
              state.temporaryPosts[indexOfPost].commentList![indexOfComment];
          break;
        }
    }

    nearSocialApi
        .getCommentContent(
      accountId: comment.authorInfo.accountId,
      blockHeight: comment.blockHeight,
    )
        .then(
      (commentBody) {
        late final List<Comment> commentsOfPost;
        switch (postsViewMode) {
          case PostsViewMode.main:
            {
              commentsOfPost = state.posts[indexOfPost].commentList!;
              break;
            }
          case PostsViewMode.account:
            {
              commentsOfPost = state
                  .postsOfAccounts[postsOfAccountId]![indexOfPost].commentList!;
              break;
            }
          case PostsViewMode.temporary:
            {
              commentsOfPost = state.temporaryPosts[indexOfPost].commentList!;
              break;
            }
        }
        _updateDataDueToPostsViewMode(
          postsViewMode: postsViewMode,
          post: post,
          commentList: commentsOfPost
            ..[indexOfComment] = commentsOfPost[indexOfComment].copyWith(
              commentBody: commentBody,
            ),
          postsOfAccountId: postsOfAccountId,
        );
      },
    );

    nearSocialApi
        .getDateOfBlockHeight(
      blockHeight: comment.blockHeight,
    )
        .then((date) {
      late final List<Comment> commentsOfPost;
      switch (postsViewMode) {
        case PostsViewMode.main:
          {
            commentsOfPost = state.posts[indexOfPost].commentList!;
            break;
          }
        case PostsViewMode.account:
          {
            commentsOfPost = state
                .postsOfAccounts[postsOfAccountId]![indexOfPost].commentList!;
            break;
          }
        case PostsViewMode.temporary:
          {
            commentsOfPost = state.temporaryPosts[indexOfPost].commentList!;
            break;
          }
      }
      _updateDataDueToPostsViewMode(
        postsViewMode: postsViewMode,
        post: post,
        commentList: commentsOfPost
          ..[indexOfComment] = commentsOfPost[indexOfComment].copyWith(
            date: date,
          ),
        postsOfAccountId: postsOfAccountId,
      );
    });

    nearSocialApi
        .getLikesOfComment(
      accountId: comment.authorInfo.accountId,
      blockHeight: comment.blockHeight,
    )
        .then(
      (likes) {
        late final List<Comment> commentsOfPost;
        switch (postsViewMode) {
          case PostsViewMode.main:
            {
              commentsOfPost = state.posts[indexOfPost].commentList!;
              break;
            }
          case PostsViewMode.account:
            {
              commentsOfPost = state
                  .postsOfAccounts[postsOfAccountId]![indexOfPost].commentList!;
              break;
            }
          case PostsViewMode.temporary:
            {
              commentsOfPost = state.temporaryPosts[indexOfPost].commentList!;
              break;
            }
        }
        _updateDataDueToPostsViewMode(
          postsViewMode: postsViewMode,
          post: post,
          commentList: commentsOfPost
            ..[indexOfComment] = commentsOfPost[indexOfComment].copyWith(
              likeList: likes,
            ),
          postsOfAccountId: postsOfAccountId,
        );
      },
    );
  }

  Future<void> updatePostsOfAccount({required String postsOfAccountId}) async {
    try {
      final newPosts = await nearSocialApi.getPosts(
        targetAccounts: [postsOfAccountId],
        limit: 10,
      );

      final currentPostsOfAccount = state.postsOfAccounts[postsOfAccountId];

      newPosts.removeWhere(
        (post) => currentPostsOfAccount.any(
          (element) =>
              element.blockHeight == post.blockHeight &&
              element.authorInfo.accountId == post.authorInfo.accountId &&
              element.reposterInfo == post.reposterInfo,
        ),
      );

      _streamController.add(
        state.copyWith(
          postsOfAccounts: Map.of(state.postsOfAccounts)
            ..[postsOfAccountId] = [...newPosts, ...currentPostsOfAccount],
          status: PostLoadingStatus.loaded,
        ),
      );
      for (var indexOfPost = 0;
          indexOfPost < state.postsOfAccounts[postsOfAccountId]!.length;
          indexOfPost++) {
        _loadPostsDataAsync(
            indexOfPost, PostsViewMode.account, postsOfAccountId);
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<void> _loadPostsDataAsync(int indexOfPost, PostsViewMode postsViewMode,
      [String? postsOfAccountId]) async {
    late final Post post;

    switch (postsViewMode) {
      case PostsViewMode.main:
        {
          post = state.posts[indexOfPost];
          break;
        }
      case PostsViewMode.account:
        {
          post = state.postsOfAccounts[postsOfAccountId]![indexOfPost];
          break;
        }
      case PostsViewMode.temporary:
        {
          post = state.temporaryPosts[indexOfPost];
          break;
        }
    }

    await nearSocialApi
        .getPostContent(
      accountId: post.authorInfo.accountId,
      blockHeight: post.blockHeight,
    )
        .then(
      (postBody) {
        _updateDataDueToPostsViewMode(
          post: post,
          postsViewMode: postsViewMode,
          postBody: postBody,
          postsOfAccountId: postsOfAccountId,
        );
      },
    );

    await nearSocialApi
        .getGeneralAccountInfo(accountId: post.authorInfo.accountId)
        .then((authorInfo) {
      _updateDataDueToPostsViewMode(
        post: post,
        postsViewMode: postsViewMode,
        authorInfo: authorInfo,
        postsOfAccountId: postsOfAccountId,
      );
    });
    if (post.reposterInfo != null) {
      await nearSocialApi
          .getGeneralAccountInfo(accountId: post.reposterInfo!.accountId)
          .then((authorInfo) {
        _updateDataDueToPostsViewMode(
          post: post,
          postsViewMode: postsViewMode,
          reposterInfo: post.reposterInfo!.copyWith(name: authorInfo.name),
          postsOfAccountId: postsOfAccountId,
        );
      });
      await nearSocialApi
          .getDateOfBlockHeight(
        blockHeight: post.reposterInfo!.blockHeight,
      )
          .then((date) {
        _updateDataDueToPostsViewMode(
          post: post,
          postsViewMode: postsViewMode,
          date: date,
          postsOfAccountId: postsOfAccountId,
        );
      });
    } else {
      await nearSocialApi
          .getDateOfBlockHeight(blockHeight: post.blockHeight)
          .then((date) {
        _updateDataDueToPostsViewMode(
          post: post,
          postsViewMode: postsViewMode,
          date: date,
          postsOfAccountId: postsOfAccountId,
        );
      });
    }

    await nearSocialApi
        .getLikesOfPost(
            accountId: post.authorInfo.accountId, blockHeight: post.blockHeight)
        .then((likes) {
      _updateDataDueToPostsViewMode(
        post: post,
        postsViewMode: postsViewMode,
        likeList: likes,
        postsOfAccountId: postsOfAccountId,
      );
    });

    await nearSocialApi
        .getRepostsOfPost(
            accountId: post.authorInfo.accountId, blockHeight: post.blockHeight)
        .then((reposts) {
      _updateDataDueToPostsViewMode(
        post: post,
        postsViewMode: postsViewMode,
        repostList: reposts,
        postsOfAccountId: postsOfAccountId,
      );
    });
  }

  Future<void> likePost({
    required Post post,
    required String accountId,
    required String publicKey,
    required String privateKey,
    required PostsViewMode postsViewMode,
    String? postsOfAccountId,
  }) async {
    final isLiked =
        post.likeList.any((element) => element.accountId == accountId);
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
        _updateDataDueToPostsViewMode(
          postsViewMode: postsViewMode,
          post: post,
          likeList: Set.of(post.likeList)
            ..removeWhere((element) => element.accountId == accountId),
          postsOfAccountId: postsOfAccountId,
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
        _updateDataDueToPostsViewMode(
          postsViewMode: postsViewMode,
          post: post,
          likeList: Set.of(post.likeList)
            ..add(
              Like(accountId: accountId),
            ),
          postsOfAccountId: postsOfAccountId,
        );
      }
    } catch (err) {
      if (isLiked) {
        _updateDataDueToPostsViewMode(
          postsViewMode: postsViewMode,
          post: post,
          likeList: Set.of(post.likeList)
            ..add(
              Like(accountId: accountId),
            ),
          postsOfAccountId: postsOfAccountId,
        );
      } else {
        _updateDataDueToPostsViewMode(
          postsViewMode: postsViewMode,
          post: post,
          likeList: Set.of(post.likeList)
            ..removeWhere((element) => element.accountId == accountId),
          postsOfAccountId: postsOfAccountId,
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
    String? postsOfAccountId,
  }) async {
    final indexOfPost = _getIndexOfPost(post, postsViewMode);
    final indexOfComment = post.commentList!.indexWhere(
      (element) =>
          element.blockHeight == comment.blockHeight &&
          element.authorInfo.accountId == comment.authorInfo.accountId,
    );
    final isLiked = post.commentList![indexOfComment].likeList
        .any((element) => element.accountId == accountId);

    late final List<Comment> commentsOfPost;
    switch (postsViewMode) {
      case PostsViewMode.main:
        {
          commentsOfPost = state.posts[indexOfPost].commentList!;
          break;
        }
      case PostsViewMode.account:
        {
          commentsOfPost = state
              .postsOfAccounts[postsOfAccountId]![indexOfPost].commentList!;
          break;
        }
      case PostsViewMode.temporary:
        {
          commentsOfPost = state.temporaryPosts[indexOfPost].commentList!;
          break;
        }
    }

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

        _updateDataDueToPostsViewMode(
          postsViewMode: postsViewMode,
          post: post,
          commentList: commentsOfPost
            ..[indexOfComment].copyWith(
              likeList: comment.likeList
                ..removeWhere(
                  (element) => element.accountId == accountId,
                ),
            ),
          postsOfAccountId: postsOfAccountId,
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

      _updateDataDueToPostsViewMode(
        postsViewMode: postsViewMode,
        post: post,
        commentList: commentsOfPost
          ..[indexOfComment].copyWith(
            likeList: comment.likeList
              ..add(
                Like(
                  accountId: accountId,
                ),
              ),
          ),
        postsOfAccountId: postsOfAccountId,
      );
    } catch (err) {
      // if (isLiked) {
      //   if (state.postsViewMode != postsViewMode) {
      //     if (postsViewMode == PostsViewMode.main) {
      //       _streamController.add(
      //         state.copyWith(
      //           mainPosts: List.of(state.mainPosts)
      //             ..[indexOfPost] = state.mainPosts[indexOfPost].copyWith(
      //               commentList: List.from(
      //                   state.mainPosts[indexOfPost].commentList ?? [])
      //                 ..[indexOfComment] = comment.copyWith(
      //                   likeList: comment.likeList
      //                     ..add(
      //                       Like(
      //                         accountId: accountId,
      //                       ),
      //                     ),
      //                 ),
      //             ),
      //         ),
      //       );
      //     }
      //     return;
      //   }
      //   _streamController.add(
      //     state.copyWith(
      //       posts: List.of(state.posts)
      //         ..[indexOfPost] = state.posts[indexOfPost].copyWith(
      //           commentList:
      //               List.from(state.posts[indexOfPost].commentList ?? [])
      //                 ..[indexOfComment] = comment.copyWith(
      //                   likeList: comment.likeList
      //                     ..add(
      //                       Like(
      //                         accountId: accountId,
      //                       ),
      //                     ),
      //                 ),
      //         ),
      //     ),
      //   );
      // } else {
      //   if (state.postsViewMode != postsViewMode) {
      //     if (postsViewMode == PostsViewMode.main) {
      //       _streamController.add(
      //         state.copyWith(
      //           mainPosts: List.of(state.mainPosts)
      //             ..[indexOfPost] = state.mainPosts[indexOfPost].copyWith(
      //               commentList: List.from(
      //                   state.mainPosts[indexOfPost].commentList ?? [])
      //                 ..[indexOfComment] = comment.copyWith(
      //                   likeList: comment.likeList
      //                     ..removeWhere(
      //                       (element) => element.accountId == accountId,
      //                     ),
      //                 ),
      //             ),
      //         ),
      //       );
      //     }
      //     return;
      //   }
      //   _streamController.add(
      //     state.copyWith(
      //       posts: List.of(state.posts)
      //         ..[indexOfPost] = state.posts[indexOfPost].copyWith(
      //           commentList:
      //               List.from(state.posts[indexOfPost].commentList ?? [])
      //                 ..[indexOfComment] = comment.copyWith(
      //                   likeList: comment.likeList
      //                     ..removeWhere(
      //                       (element) => element.accountId == accountId,
      //                     ),
      //                 ),
      //         ),
      //     ),
      //   );
      // }
      rethrow;
    }
  }

  Future<void> repostPost({
    required Post post,
    required String accountId,
    required String publicKey,
    required String privateKey,
    required PostsViewMode postsViewMode,
    String? postsOfAccountId,
  }) async {
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

      _updateDataDueToPostsViewMode(
        postsViewMode: postsViewMode,
        post: post,
        repostList: Set.of(post.repostList)
          ..add(
            Reposter(accountId: accountId),
          ),
        postsOfAccountId: postsOfAccountId,
      );
    } catch (err) {
      // _streamController.add(
      //   state.copyWith(
      //     posts: List.of(state.posts)
      //       ..[indexOfPost] = state.posts[indexOfPost].copyWith(
      //         repostList: Set.of(post.repostList)
      //           ..removeWhere((element) => element.accountId == accountId),
      //       ),
      //   ),
      // );
      rethrow;
    }
  }

  void _updateDataDueToPostsViewMode({
    required PostsViewMode postsViewMode,
    required Post post,
    String? postsOfAccountId,
    Set<Like>? likeList,
    List<Comment>? commentList,
    Set<Reposter>? repostList,
    PostBody? postBody,
    GeneralAccountInfo? authorInfo,
    ReposterInfo? reposterInfo,
    DateTime? date,
  }) {
    final indexOfPost = _getIndexOfPost(post, postsViewMode);
    switch (postsViewMode) {
      case PostsViewMode.main:
        {
          _streamController.add(
            state.copyWith(
              posts: List.of(state.posts)
                ..[indexOfPost] = state.posts[indexOfPost].copyWith(
                  likeList: likeList ?? state.posts[indexOfPost].likeList,
                  commentList:
                      commentList ?? state.posts[indexOfPost].commentList,
                  repostList: repostList ?? state.posts[indexOfPost].repostList,
                  postBody: postBody ?? state.posts[indexOfPost].postBody,
                  authorInfo: authorInfo ?? state.posts[indexOfPost].authorInfo,
                  reposterInfo:
                      reposterInfo ?? state.posts[indexOfPost].reposterInfo,
                  date: date ?? state.posts[indexOfPost].date,
                ),
            ),
          );
          break;
        }
      case PostsViewMode.account:
        {
          final newlistOfPostsForUser = List.from(
              state.postsOfAccounts[postsOfAccountId])
            ..[indexOfPost] =
                state.postsOfAccounts[postsOfAccountId][indexOfPost].copyWith(
              likeList: likeList ??
                  state.postsOfAccounts[postsOfAccountId][indexOfPost].likeList,
              commentList: commentList ??
                  state.postsOfAccounts[postsOfAccountId][indexOfPost]
                      .commentList,
              repostList: repostList ??
                  state.postsOfAccounts[postsOfAccountId][indexOfPost]
                      .repostList,
              postBody: postBody ??
                  state.postsOfAccounts[postsOfAccountId][indexOfPost].postBody,
              authorInfo: authorInfo ??
                  state.postsOfAccounts[postsOfAccountId][indexOfPost]
                      .authorInfo,
              reposterInfo: reposterInfo ??
                  state.postsOfAccounts[postsOfAccountId][indexOfPost]
                      .reposterInfo,
              date: date ??
                  state.postsOfAccounts[postsOfAccountId][indexOfPost].date,
            );
          _streamController.add(
            state.copyWith(
              postsOfAccounts: Map<String, dynamic>.from(state.postsOfAccounts)
                ..[postsOfAccountId!] = newlistOfPostsForUser,
            ),
          );
          break;
        }
      case PostsViewMode.temporary:
        {
          _streamController.add(
            state.copyWith(
              temporaryPosts: List.of(state.temporaryPosts)
                ..[indexOfPost] = state.temporaryPosts[indexOfPost].copyWith(
                  likeList:
                      likeList ?? state.temporaryPosts[indexOfPost].likeList,
                  commentList: commentList ??
                      state.temporaryPosts[indexOfPost].commentList,
                  repostList: repostList ??
                      state.temporaryPosts[indexOfPost].repostList,
                  postBody:
                      postBody ?? state.temporaryPosts[indexOfPost].postBody,
                  authorInfo: authorInfo ??
                      state.temporaryPosts[indexOfPost].authorInfo,
                  reposterInfo: reposterInfo ??
                      state.temporaryPosts[indexOfPost].reposterInfo,
                  date: date ?? state.temporaryPosts[indexOfPost].date,
                ),
            ),
          );
          break;
        }
    }
    return;
  }

  int _getIndexOfPost(Post post, PostsViewMode postsViewMode) {
    switch (postsViewMode) {
      case PostsViewMode.main:
        {
          return state.posts.indexWhere(
            (element) =>
                element.blockHeight == post.blockHeight &&
                element.authorInfo.accountId == post.authorInfo.accountId &&
                element.reposterInfo == post.reposterInfo,
          );
        }
      case PostsViewMode.account:
        {
          return state.postsOfAccounts[
                  post.reposterInfo?.accountId ?? post.authorInfo.accountId]
              .indexWhere((element) =>
                  element.blockHeight == post.blockHeight &&
                  element.authorInfo.accountId == post.authorInfo.accountId &&
                  element.reposterInfo == post.reposterInfo);
        }
      case PostsViewMode.temporary:
        {
          return state.temporaryPosts.indexWhere(
            (element) =>
                element.blockHeight == post.blockHeight &&
                element.authorInfo.accountId == post.authorInfo.accountId &&
                element.reposterInfo == post.reposterInfo,
          );
        }
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
  final Map<String, dynamic> postsOfAccounts;
  final PostLoadingStatus status;

  const Posts({
    this.posts = const [],
    this.temporaryPosts = const [],
    this.postsOfAccounts = const {},
    this.status = PostLoadingStatus.initial,
  });

  Posts copyWith({
    List<Post>? posts,
    List<Post>? temporaryPosts,
    Map<String, dynamic>? postsOfAccounts,
    PostLoadingStatus? status,
  }) {
    return Posts(
      posts: posts ?? this.posts,
      postsOfAccounts: postsOfAccounts ?? this.postsOfAccounts,
      temporaryPosts: temporaryPosts ?? this.temporaryPosts,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Posts &&
          runtimeType == other.runtimeType &&
          listEquals(posts, other.posts) &&
          listEquals(temporaryPosts, other.temporaryPosts) &&
          mapEquals(postsOfAccounts, other.postsOfAccounts) &&
          status == other.status;
}
