import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:html/parser.dart' as htmlParser;

// import 'models/post.dart';
// const defaultProfileImageUrl =
//     "https://ipfs.near.social/ipfs/bafkreibmiy4ozblcgv3fm3gc6q62s55em33vconbavfd2ekkuliznaq3zm";

class NearSocialApi {
  final Dio _dio = Dio();
  Future<List<Post>> getPosts({
    int? lastBlockHeightIndexOfPosts,
    int? lastBlockHeightIndexOfReposts,
  }) async {
    final onlyPosts = await _getOnlyPosts(
      limit: 10,
      fromBlockHeight: lastBlockHeightIndexOfPosts,
    );
    final reposts = await _getReposts(
      limit: 10,
      fromBlockHeight: lastBlockHeightIndexOfReposts,
    );

    final List<FullPostCreationInfo> fullpostsCreationInfo = [
      ...onlyPosts,
      ...reposts
    ]..sort(
        (a, b) {
          if (b.reposterPostCreationInfo != null) {
            return b.reposterPostCreationInfo!.blockHeight.compareTo(
              a.reposterPostCreationInfo != null
                  ? a.reposterPostCreationInfo!.blockHeight
                  : a.postCreationInfo.blockHeight,
            );
          } else {
            return b.postCreationInfo.blockHeight.compareTo(
              a.reposterPostCreationInfo != null
                  ? a.reposterPostCreationInfo!.blockHeight
                  : a.postCreationInfo.blockHeight,
            );
          }
        },
      );

    final List<Post> posts = [];

    for (final info in fullpostsCreationInfo) {
      final authorInfo = AuthorInfo(
        accountId: info.postCreationInfo.accountId,
        profileImageLink: "",
      );
      //     await getAuthorInfo(
      //   accountId: info.postCreationInfo.accountId,
      // );

      // final postBody = await getPostContent(
      //   accountId: info.postCreationInfo.accountId,
      //   blockHeight: info.postCreationInfo.blockHeight,
      // );

      // late DateTime date;

      ReposterInfo? reposterInfo;
      if (info.reposterPostCreationInfo != null) {
        // final reposterAuthorInfo = await getAuthorInfo(
        //   accountId: info.reposterPostCreationInfo!.accountId,
        // );
        reposterInfo = ReposterInfo(
          accountId: info.reposterPostCreationInfo!.accountId,
          // name: reposterAuthorInfo.name,
          blockHeight: info.reposterPostCreationInfo!.blockHeight,
        );
        // date = await getDateOfBlockHeight(
        //   blockHeight: info.reposterPostCreationInfo!.blockHeight,
        // );
      } else {
        // date = await getDateOfBlockHeight(
        //   blockHeight: info.postCreationInfo.blockHeight,
        // );
      }

      // final likes = await getLikesOfPost(
      //   accountId: info.postCreationInfo.accountId,
      //   blockHeight: info.postCreationInfo.blockHeight,
      // );

      // final reposters = await getRepostsOfPost(
      //   accountId: info.postCreationInfo.accountId,
      //   blockHeight: info.postCreationInfo.blockHeight,
      // );
      posts.add(
        Post(
          authorInfo: authorInfo,
          blockHeight: info.postCreationInfo.blockHeight,
          date: DateTime.now(),
          postBody: PostBody(text: "Loading"),
          reposterInfo: reposterInfo,
          likeList: [],
          repostList: [],
          commentList: null,
        ),
        // Post(
        //   authorInfo: authorInfo,
        //   blockHeight: info.postCreationInfo.blockHeight,
        //   date: date,
        //   postBody: postBody,
        //   reposterInfo: reposterInfo,
        //   likeList: likes,
        //   repostList: reposters,
        //   commentList: null,
        // ),
      );
    }

    return posts;
  }

  Future<List<FullPostCreationInfo>> _getOnlyPosts({
    int? fromBlockHeight,
    int limit = 30,
  }) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final data = {
        "action": "post",
        "key": "main",
        "options": {
          "limit": limit,
          "order": "desc",
          if (fromBlockHeight != null) "from": fromBlockHeight,
        }
      };
      final response = await _dio.request(
        'https://api.near.social/index',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      final List<FullPostCreationInfo> posts =
          List<Map<String, dynamic>>.from(response.data)
              .map(
                (value) => FullPostCreationInfo(
                  postCreationInfo: PostCreationInfo(
                    accountId: value["accountId"],
                    blockHeight: value["blockHeight"],
                  ),
                ),
              )
              .toList();

      return posts;
    } catch (err) {
      // print(err.toString());
      rethrow;
    }
  }

  Future<List<FullPostCreationInfo>> _getReposts({
    int? fromBlockHeight,
    int limit = 30,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    final data = {
      "action": "repost",
      "key": "main",
      "options": {
        "limit": limit,
        "order": "desc",
        if (fromBlockHeight != null) "from": fromBlockHeight,
      }
    };
    final response = await _dio.request(
      'https://api.near.social/index',
      options: Options(
        method: 'POST',
        headers: headers,
      ),
      data: data,
    );

    final List<FullPostCreationInfo> reposts =
        List<Map<String, dynamic>>.from(response.data).map((value) {
      final repostedPath = value["value"]["item"]["path"] as String;
      final repostedAccountId =
          repostedPath.substring(0, repostedPath.indexOf("/post/main"));
      final repostedBlockHeight = value["value"]["item"]["blockHeight"];
      return FullPostCreationInfo(
        postCreationInfo: PostCreationInfo(
          accountId: repostedAccountId,
          blockHeight: repostedBlockHeight,
        ),
        reposterPostCreationInfo: PostCreationInfo(
          accountId: value["accountId"],
          blockHeight: value["blockHeight"],
        ),
      );
    }).toList();

    return reposts;
  }

  Future<PostBody> getPostContent(
      {required String accountId, required int blockHeight}) async {
    final headers = {'Content-Type': 'application/json'};
    final data = {
      "keys": ["$accountId/post/main"],
      "blockHeight": blockHeight
    };
    final response = await _dio.request(
      'https://api.near.social/get',
      options: Options(
        method: 'POST',
        headers: headers,
      ),
      data: data,
    );
    if (response.data[accountId] == null) {
      return PostBody(text: "", mediaLink: null);
    }
    final postInfo = jsonDecode(response.data[accountId]["post"]["main"]);
    const urlTemplateForImage = "https://ipfs.near.social/ipfs/";
    return PostBody(
      text: postInfo["text"] ?? "",
      mediaLink: postInfo["image"] != null
          ? postInfo["image"]["ipfs_cid"] != null
              ? urlTemplateForImage + postInfo["image"]["ipfs_cid"]
              : postInfo["image"]["url"]
          : null,
    );
  }

  Future<List<Like>> getLikesOfPost({
    required String accountId,
    required int blockHeight,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    final data = {
      "action": "like",
      "key": {
        "type": "social",
        "path": "$accountId/post/main",
        "blockHeight": blockHeight
      }
    };
    final response = await _dio.request(
      'https://api.near.social/index',
      options: Options(
        method: 'POST',
        headers: headers,
      ),
      data: data,
    );

    final likes = List<Map<String, dynamic>>.from(response.data)
        .map((info) => Like(accountId: info["accountId"]))
        .toList();

    return likes;
  }

  Future<List<Reposter>> getRepostsOfPost({
    required String accountId,
    required int blockHeight,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    final data = json.encode({
      "action": "repost",
      "key": {
        "type": "social",
        "path": "$accountId/post/main",
        "blockHeight": blockHeight
      }
    });
    final response = await _dio.request(
      'https://api.near.social/index',
      options: Options(
        method: 'POST',
        headers: headers,
      ),
      data: data,
    );
    final reposts = List<Map<String, dynamic>>.from(response.data)
        .map((info) => Reposter(accountId: info["accountId"]))
        .toList();
    return reposts;
  }

  Future<DateTime> getDateOfBlockHeight({required int blockHeight}) async {
    final response = await _dio.request(
      'https://api.near.social/time?blockHeight=$blockHeight',
      options: Options(
        method: 'GET',
      ),
    );
    final epochTime = response.data as int;

    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(epochTime);

    return dateTime;
  }

  Future<List<Comment>> getCommentsOfPost({
    required String accountId,
    required int blockHeight,
  }) async {
    final commentsInfoCreation = await _getListOfCommentCreationInfoOfPost(
      accountId: accountId,
      blockHeight: blockHeight,
    );

    final List<Comment> comments = [];

    for (final info in commentsInfoCreation) {
      final commentBody = await _getCommentContent(
        accountId: info.accountId,
        blockHeight: info.blockHeight,
      );
      final date = await getDateOfBlockHeight(
        blockHeight: info.blockHeight,
      );

      final authorInfo = await getAuthorInfo(
        accountId: info.accountId,
      );

      final likes = await _getLikesOfComment(
        accountId: info.accountId,
        blockHeight: info.blockHeight,
      );

      comments.add(
        Comment(
          authorInfo: authorInfo,
          blockHeight: info.blockHeight,
          text: commentBody.text,
          date: date,
          likeList: likes,
        ),
      );
    }

    return comments;
  }

  Future<List<CommentCreationInfo>> _getListOfCommentCreationInfoOfPost({
    required String accountId,
    required int blockHeight,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    final data = json.encode({
      "action": "comment",
      "key": {
        "type": "social",
        "path": "$accountId/post/main",
        "blockHeight": blockHeight
      },
      "options": {"limit": 50, "order": "desc", "subscribe": true}
    });
    final response = await _dio.request(
      'https://api.near.social/index',
      options: Options(
        method: 'POST',
        headers: headers,
      ),
      data: data,
    );
    final comments = List<Map<String, dynamic>>.from(response.data)
        .map(
          (info) => CommentCreationInfo(
            accountId: info["accountId"],
            blockHeight: info["blockHeight"],
          ),
        )
        .toList();
    // print(comments);
    return comments;
    // print(response.data);
  }

  Future<CommentBody> _getCommentContent(
      {required String accountId, required int blockHeight}) async {
    final headers = {'Content-Type': 'application/json'};
    final data = {
      "keys": ["$accountId/post/comment"],
      "blockHeight": blockHeight
    };
    final response = await _dio.request(
      'https://api.near.social/get',
      options: Options(
        method: 'POST',
        headers: headers,
      ),
      data: data,
    );
    final commentInfo = jsonDecode(response.data[accountId]["post"]["comment"]);
    return CommentBody(text: commentInfo["text"]);
  }

  Future<List<Like>> _getLikesOfComment(
      {required String accountId, required int blockHeight}) async {
    final headers = {'Content-Type': 'application/json'};
    final data = {
      "action": "like",
      "key": {
        "type": "social",
        "path": "$accountId/post/comment",
        "blockHeight": blockHeight
      }
    };
    final response = await _dio.request(
      'https://api.near.social/index',
      options: Options(
        method: 'POST',
        headers: headers,
      ),
      data: data,
    );
    final likes = List<Map<String, dynamic>>.from(response.data)
        .map((info) => Like(accountId: info["accountId"]))
        .toList();

    return likes;
  }

  // String _getProfilePictureUrl({required String accountId}) {
  //   // return "https://i.near.social/magic/thumbnail/https://near.social/magic/img/account/$accountId";
  //   return "https://i.near.social/magic/large/https://near.social/magic/img/account/$accountId";
  // }

  Future<AuthorInfo> getAuthorInfo({required String accountId}) async {
    final response = await _dio.request(
      'https://near.social/mob.near/widget/ProfilePage?accountId=$accountId',
      options: Options(
        method: 'GET',
      ),
    );
    final htmlResponse = response.data;
    // Parse the HTML response
    final document = htmlParser.parse(htmlResponse);

    // Extract the title tag contents which contains the name
    final titleElement = document.querySelector('title');
    final titleText = titleElement!.text;

    // Extract the name from the title text
    // "truedove38.near | Near Social"
    final int endOfUserName = titleText.indexOf('(');

    late String? name;
    if (endOfUserName == -1) {
      name = null;
    } else {
      name = titleText.substring(0, endOfUserName).trim();
    }

    // Extract the og:image meta tag content which contains the picture URL
    final ogImageElement = document.querySelector('meta[property="og:image"]');
    final pictureUrl = ogImageElement!.attributes['content']!;

    // print("Name: $name, pictureUrl $pictureUrl ");

    return AuthorInfo(
      accountId: accountId,
      name: name,
      profileImageLink: pictureUrl,
    );
  }
}

class FullPostCreationInfo {
  final PostCreationInfo postCreationInfo;
  final PostCreationInfo? reposterPostCreationInfo;

  FullPostCreationInfo({
    required this.postCreationInfo,
    this.reposterPostCreationInfo,
  });

  @override
  String toString() {
    return 'FullPostCreationInfo(postCreationInfo: $postCreationInfo, reposterPostCreationInfo: $reposterPostCreationInfo)';
  }
}

class PostCreationInfo {
  String accountId;
  int blockHeight;

  PostCreationInfo({
    required this.accountId,
    required this.blockHeight,
  });

  @override
  String toString() {
    return 'PostCreationInfo(accountId: $accountId, blockHeight: $blockHeight)';
  }
}

class CommentCreationInfo {
  final String accountId;
  final int blockHeight;

  CommentCreationInfo({
    required this.accountId,
    required this.blockHeight,
  });
}

class CommentBody {
  final String text;

  CommentBody({
    required this.text,
  });
}

void main(List<String> args) async {
  final NearSocialApi nearSocialApi = NearSocialApi();
  // final resp =
  await nearSocialApi.getAuthorInfo(accountId: "liquidator38.near");
  // print(resp);
  // final commentsList = await nearSocialApi.getListOfCommentsOfPost(
  //   accountId: "nearmedia.near",
  //   blockHeight: 114782251,
  // );
  // print(commentsList);
}
