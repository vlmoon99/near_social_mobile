import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:near_social_mobile/modules/home/apis/models/comment.dart';
import 'package:near_social_mobile/modules/home/apis/models/general_account_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/like.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:near_social_mobile/modules/home/apis/models/reposter.dart';
import 'package:near_social_mobile/modules/home/apis/models/reposter_info.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/vms/core/filter_controller.dart';
import 'package:near_social_mobile/modules/vms/core/models/filters.dart';
import 'package:near_social_mobile/utils/future_queue.dart';
import 'package:rxdart/rxdart.dart';

class PostsController {
  final NearSocialApi nearSocialApi;
  PostsController(this.nearSocialApi);

  final BehaviorSubject<Posts> _streamController =
      BehaviorSubject.seeded(const Posts());

  Stream<Posts> get stream => _streamController.stream.distinct();
  Posts get state => _streamController.value;

  final FutureQueue _futureQueue = FutureQueue(
    timeout: const Duration(milliseconds: 1000),
  );

  Future<void> loadPosts(
      {String? postsOfAccountId,
      required PostsViewMode postsViewMode,
      Filters? filters}) async {
    try {
      if (postsViewMode == PostsViewMode.main) {
        _streamController.add(
          state.copyWith(
            status: PostLoadingStatus.loading,
          ),
        );
      }

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
              ),
            );
            break;
          }
        case PostsViewMode.account:
          {
            _streamController.add(
              state.copyWith(
                postsOfAccounts: Map.of(state.postsOfAccounts)
                  ..[postsOfAccountId!] = posts,
              ),
            );
            break;
          }
        case PostsViewMode.temporary:
          {
            // Not needed
            break;
          }
      }

      checkPostsForFullLoadAndLoadIfNecessary(
        postsViewMode: postsViewMode,
        filters: filters,
        postsOfAccountId: postsOfAccountId,
      );

      _streamController.add(
        state.copyWith(
          status: PostLoadingStatus.loaded,
        ),
      );
    } catch (err) {
      rethrow;
    }
  }

  Future<void> checkPostsForFullLoadAndLoadIfNecessary(
      {required PostsViewMode postsViewMode,
      Filters? filters,
      String? postsOfAccountId}) async {
    final summaryPosts = getPostsDueToPostsViewMode(
      postsViewMode,
      postsOfAccountId,
    );

    if (filters != null) {
      final FiltersUtil filtersUtil = FiltersUtil(filters: filters);

      for (var i = 0; i < summaryPosts.length; i++) {
        final post = summaryPosts[i];
        if (!post.fullyLoaded &&
            !filtersUtil.postIsHided(
                post.authorInfo.accountId, post.blockHeight)) {
          _loadPostsDataAsync(i, postsViewMode, postsOfAccountId);
        }
      }
    } else {
      for (var i = 0; i < summaryPosts.length; i++) {
        final post = summaryPosts[i];
        if (!post.fullyLoaded) {
          _loadPostsDataAsync(i, postsViewMode, postsOfAccountId);
        }
      }
    }
  }

  Future<void> loadAndAddSinglePostIfNotExistToTempList({
    required GeneralAccountInfo accountInfo,
    required int blockHeight,
  }) async {
    if (state.temporaryPosts.isNotEmpty &&
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
            fullyLoaded: true,
          ),
          ...state.temporaryPosts
        ],
      ),
    );
  }

  List<Post> getPostsDueToPostsViewMode(PostsViewMode postsViewMode,
      [String? postsOfAccountId]) {
    late final List<Post> chosenPosts;

    switch (postsViewMode) {
      case PostsViewMode.main:
        {
          chosenPosts = List.of(state.posts);
          break;
        }
      case PostsViewMode.account:
        {
          chosenPosts = List.of(state.postsOfAccounts[postsOfAccountId]!);
          break;
        }
      case PostsViewMode.temporary:
        {
          chosenPosts = List.of(state.temporaryPosts);
          break;
        }
    }
    return chosenPosts;
  }

  Future<List<Post>> loadMorePosts(
      {String? postsOfAccountId,
      required PostsViewMode postsViewMode,
      Filters? filters}) async {
    try {
      log("Loading more posts");
      _streamController.add(
        state.copyWith(
          status: PostLoadingStatus.loadingMorePosts,
        ),
      );

      final List<Post> chosenPosts = getPostsDueToPostsViewMode(
        postsViewMode,
        postsOfAccountId,
      );

      final lastBlockHeightIndexOfPosts =
          chosenPosts.lastIndexWhere((element) => element.reposterInfo == null);
      final lastBlockHeightIndexOfReposts =
          chosenPosts.lastIndexWhere((element) => element.reposterInfo != null);
      final posts = await nearSocialApi.getPosts(
        lastBlockHeightIndexOfPosts: lastBlockHeightIndexOfPosts == -1
            ? null
            : chosenPosts.elementAt(lastBlockHeightIndexOfPosts).blockHeight,
        lastBlockHeightIndexOfReposts: lastBlockHeightIndexOfReposts == -1
            ? null
            : chosenPosts.elementAt(lastBlockHeightIndexOfReposts).blockHeight,
        targetAccounts: postsOfAccountId == null ? null : [postsOfAccountId],
        limit: 15,
      );

      if (lastBlockHeightIndexOfPosts != -1) {
        posts.removeWhere((post) =>
            post.blockHeight ==
            chosenPosts.elementAt(lastBlockHeightIndexOfPosts).blockHeight);
      }

      if (lastBlockHeightIndexOfReposts != -1) {
        posts.removeWhere(
          (post) =>
              post.blockHeight ==
              chosenPosts.elementAt(lastBlockHeightIndexOfReposts).blockHeight,
        );
      }

      final newPosts = [...chosenPosts, ...posts];

      switch (postsViewMode) {
        case PostsViewMode.main:
          {
            _streamController.add(
              state.copyWith(posts: newPosts),
            );
            break;
          }
        case PostsViewMode.account:
          {
            _streamController.add(
              state.copyWith(
                  postsOfAccounts: Map.of(state.postsOfAccounts)
                    ..[postsOfAccountId!] = newPosts),
            );
            break;
          }
        case PostsViewMode.temporary:
          {
            _streamController.add(
              state.copyWith(temporaryPosts: newPosts),
            );
            break;
          }
      }

      checkPostsForFullLoadAndLoadIfNecessary(
        postsViewMode: postsViewMode,
        filters: filters,
        postsOfAccountId: postsOfAccountId,
      );

      _streamController.add(
        state.copyWith(
          status: PostLoadingStatus.loaded,
        ),
      );

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
        postsOfAccountId: postsOfAccountId,
      );

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
    final int indexOfPost =
        _getIndexOfPost(post, postsViewMode, postsOfAccountId);

    final newCommentsOfPost = await nearSocialApi.getCommentsOfPost(
      accountId: accountId,
      blockHeight: blockHeight,
    );

    late final List<Comment> commentsOfPost;
    switch (postsViewMode) {
      case PostsViewMode.main:
        {
          commentsOfPost = List.of(state.posts[indexOfPost].commentList!);
          break;
        }
      case PostsViewMode.account:
        {
          commentsOfPost = List.of(state
              .postsOfAccounts[postsOfAccountId]![indexOfPost].commentList!);
          break;
        }
      case PostsViewMode.temporary:
        {
          commentsOfPost =
              List.of(state.temporaryPosts[indexOfPost].commentList!);
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
    final int indexOfPost =
        _getIndexOfPost(post, postsViewMode, postsOfAccountId);
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

    final CommentBody commentBody = await nearSocialApi.getCommentContent(
      accountId: comment.authorInfo.accountId,
      blockHeight: comment.blockHeight,
    );

    final DateTime date = await nearSocialApi.getDateOfBlockHeight(
      blockHeight: comment.blockHeight,
    );

    final List<Like> likes = await nearSocialApi.getLikesOfComment(
      accountId: comment.authorInfo.accountId,
      blockHeight: comment.blockHeight,
    );

    late final List<Comment> commentsOfPost;
    switch (postsViewMode) {
      case PostsViewMode.main:
        {
          commentsOfPost =
              List<Comment>.of(state.posts[indexOfPost].commentList!);
          break;
        }
      case PostsViewMode.account:
        {
          commentsOfPost = List<Comment>.of(state
              .postsOfAccounts[postsOfAccountId]![indexOfPost].commentList!);
          break;
        }
      case PostsViewMode.temporary:
        {
          commentsOfPost =
              List<Comment>.of(state.temporaryPosts[indexOfPost].commentList!);
          break;
        }
    }
    _updateDataDueToPostsViewMode(
      postsViewMode: postsViewMode,
      post: post,
      commentList: commentsOfPost
        ..[indexOfComment] = commentsOfPost[indexOfComment].copyWith(
          commentBody: commentBody,
          likeList: likes,
          date: date,
        ),
      postsOfAccountId: postsOfAccountId,
    );
  }

  Future<void> updatePostsOfAccount(
      {required String postsOfAccountId, Filters? filters}) async {
    try {
      final FiltersUtil filtersUtil =
          FiltersUtil(filters: filters ?? const Filters());
      final newPosts = await nearSocialApi.getPosts(
        targetAccounts: [postsOfAccountId],
        limit: 10,
      );

      newPosts.removeWhere(
        (post) => state.postsOfAccounts[postsOfAccountId]!.any(
          (element) =>
              (element.blockHeight == post.blockHeight &&
                  element.authorInfo.accountId == post.authorInfo.accountId &&
                  element.reposterInfo == post.reposterInfo) ||
              filtersUtil.postIsHided(
                  post.authorInfo.accountId, post.blockHeight),
        ),
      );

      _streamController.add(
        state.copyWith(
          postsOfAccounts: Map.of(state.postsOfAccounts)
            ..[postsOfAccountId] = [
              ...newPosts,
              ...state.postsOfAccounts[postsOfAccountId]!
            ],
          status: PostLoadingStatus.loaded,
        ),
      );

      checkPostsForFullLoadAndLoadIfNecessary(
        postsViewMode: PostsViewMode.account,
        postsOfAccountId: postsOfAccountId,
        filters: filters,
      );
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

    ReposterInfo? actualReposterInfo;
    late final DateTime actualDateOfPost;
    if (post.reposterInfo != null) {
      actualReposterInfo = post.reposterInfo!.copyWith(
        accountInfo: await nearSocialApi.getGeneralAccountInfo(
            accountId: post.reposterInfo!.accountInfo.accountId),
      );
      actualDateOfPost = await nearSocialApi.getDateOfBlockHeight(
        blockHeight: post.reposterInfo!.blockHeight,
      );
    } else {
      actualDateOfPost = await nearSocialApi.getDateOfBlockHeight(
          blockHeight: post.blockHeight);
    }

    final loadedPosts = getPostsDueToPostsViewMode(
      postsViewMode,
      postsOfAccountId,
    ).where((element) => element.fullyLoaded == true).toList();
    if (loadedPosts.any((element) =>
        element.blockHeight == post.blockHeight &&
        element.authorInfo.accountId == post.authorInfo.accountId)) {
      final postToCopyInfo = loadedPosts.firstWhere((element) =>
          element.blockHeight == post.blockHeight &&
          element.authorInfo.accountId == post.authorInfo.accountId);

      _updateDataDueToPostsViewMode(
        post: post,
        postsViewMode: postsViewMode,
        postsOfAccountId: postsOfAccountId,
        repostList: postToCopyInfo.repostList,
        likeList: postToCopyInfo.likeList,
        date: actualDateOfPost,
        authorInfo: postToCopyInfo.authorInfo,
        reposterInfo: actualReposterInfo,
        postBody: postToCopyInfo.postBody,
        fullyLoaded: true,
      );
      return;
    }

    final actualPostBody = await nearSocialApi.getPostContent(
      accountId: post.authorInfo.accountId,
      blockHeight: post.blockHeight,
    );

    final actualAuthorInfo = await nearSocialApi.getGeneralAccountInfo(
        accountId: post.authorInfo.accountId);

    final actualLikeList = await nearSocialApi.getLikesOfPost(
        accountId: post.authorInfo.accountId, blockHeight: post.blockHeight);

    final actualRepostsOfPostList = await nearSocialApi.getRepostsOfPost(
        accountId: post.authorInfo.accountId, blockHeight: post.blockHeight);

    _updateDataDueToPostsViewMode(
      post: post,
      postsViewMode: postsViewMode,
      postsOfAccountId: postsOfAccountId,
      repostList: actualRepostsOfPostList,
      likeList: actualLikeList,
      date: actualDateOfPost,
      authorInfo: actualAuthorInfo,
      reposterInfo: actualReposterInfo,
      postBody: actualPostBody,
      fullyLoaded: true,
    );
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
          likeList: List.of(post.likeList)
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
          likeList: List.of(post.likeList)
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
          likeList: List.of(post.likeList)
            ..add(
              Like(accountId: accountId),
            ),
          postsOfAccountId: postsOfAccountId,
        );
      } else {
        _updateDataDueToPostsViewMode(
          postsViewMode: postsViewMode,
          post: post,
          likeList: List.of(post.likeList)
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
    final indexOfPost = _getIndexOfPost(post, postsViewMode, postsOfAccountId);
    final indexOfComment = post.commentList!.indexWhere(
      (element) =>
          element.blockHeight == comment.blockHeight &&
          element.authorInfo.accountId == comment.authorInfo.accountId,
    );
    final isLiked = post.commentList![indexOfComment].likeList
        .any((element) => element.accountId == accountId);

    List<Comment> commentsOfPost() {
      switch (postsViewMode) {
        case PostsViewMode.main:
          {
            return List.of(state.posts[indexOfPost].commentList!);
          }
        case PostsViewMode.account:
          {
            return List.of(state
                .postsOfAccounts[postsOfAccountId]![indexOfPost].commentList!);
          }
        case PostsViewMode.temporary:
          {
            return List.of(state.temporaryPosts[indexOfPost].commentList!);
          }
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
          commentList: commentsOfPost()
            ..[indexOfComment] = commentsOfPost()[indexOfComment].copyWith(
              likeList: List.of(comment.likeList)
                ..removeWhere((element) => element.accountId == accountId),
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
        _updateDataDueToPostsViewMode(
          postsViewMode: postsViewMode,
          post: post,
          commentList: commentsOfPost()
            ..[indexOfComment] = commentsOfPost()[indexOfComment].copyWith(
              likeList: List.of(comment.likeList)
                ..add(Like(accountId: accountId)),
            ),
          postsOfAccountId: postsOfAccountId,
        );
      }
    } catch (err) {
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
        repostList: List.of(post.repostList)
          ..add(
            Reposter(accountId: accountId),
          ),
        postsOfAccountId: postsOfAccountId,
      );
    } catch (err) {
      rethrow;
    }
  }

  void _updateDataDueToPostsViewMode({
    required PostsViewMode postsViewMode,
    required Post post,
    String? postsOfAccountId,
    List<Like>? likeList,
    List<Comment>? commentList,
    List<Reposter>? repostList,
    PostBody? postBody,
    GeneralAccountInfo? authorInfo,
    ReposterInfo? reposterInfo,
    DateTime? date,
    bool? fullyLoaded,
  }) {
    final indexOfPost = _getIndexOfPost(post, postsViewMode, postsOfAccountId);
    if (indexOfPost == -1) {
      return;
    }
    switch (postsViewMode) {
      case PostsViewMode.main:
        {
          _streamController.add(
            state.copyWith(
              posts: List<Post>.of(state.posts)
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
                  fullyLoaded:
                      fullyLoaded ?? state.posts[indexOfPost].fullyLoaded,
                ),
            ),
          );
          break;
        }
      case PostsViewMode.account:
        {
          final newListOfPostsForUser = List<Post>.of(
              state.postsOfAccounts[postsOfAccountId]!)
            ..[indexOfPost] =
                state.postsOfAccounts[postsOfAccountId]![indexOfPost].copyWith(
              likeList: likeList ??
                  state
                      .postsOfAccounts[postsOfAccountId]![indexOfPost].likeList,
              commentList: commentList ??
                  state.postsOfAccounts[postsOfAccountId]![indexOfPost]
                      .commentList,
              repostList: repostList ??
                  state.postsOfAccounts[postsOfAccountId]![indexOfPost]
                      .repostList,
              postBody: postBody ??
                  state
                      .postsOfAccounts[postsOfAccountId]![indexOfPost].postBody,
              authorInfo: authorInfo ??
                  state.postsOfAccounts[postsOfAccountId]![indexOfPost]
                      .authorInfo,
              reposterInfo: reposterInfo ??
                  state.postsOfAccounts[postsOfAccountId]![indexOfPost]
                      .reposterInfo,
              date: date ??
                  state.postsOfAccounts[postsOfAccountId]![indexOfPost].date,
              fullyLoaded: fullyLoaded ??
                  state.postsOfAccounts[postsOfAccountId]![indexOfPost]
                      .fullyLoaded,
            );
          _streamController.add(
            state.copyWith(
              postsOfAccounts: Map<String, List<Post>>.of(state.postsOfAccounts)
                ..[postsOfAccountId!] = newListOfPostsForUser,
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
                  fullyLoaded: fullyLoaded ??
                      state.temporaryPosts[indexOfPost].fullyLoaded,
                ),
            ),
          );
          break;
        }
    }
    return;
  }

  int _getIndexOfPost(
      Post post, PostsViewMode postsViewMode, String? postsOfAccountId) {
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
          return state.postsOfAccounts[postsOfAccountId]!.indexWhere(
            (element) =>
                element.blockHeight == post.blockHeight &&
                element.authorInfo.accountId == post.authorInfo.accountId &&
                element.reposterInfo == post.reposterInfo,
          );
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

  Future<void> clear() async {
    _streamController.add(const Posts());
  }
}

enum PostLoadingStatus {
  initial,
  loading,
  loadingMorePosts,
  loaded,
}

enum PostsViewMode { main, account, temporary }

class Posts extends Equatable {
  final List<Post> posts;
  final List<Post> temporaryPosts;
  final Map<String, List<Post>> postsOfAccounts;
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
    Map<String, List<Post>>? postsOfAccounts,
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
  List<Object?> get props => [
        posts,
        temporaryPosts,
        postsOfAccounts,
        status,
      ];

  @override
  bool? get stringify => true;
}
