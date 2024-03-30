import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutterchain/flutterchain_lib/models/chains/near/near_blockchain_smart_contract_arguments.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/modules/home/apis/models/author_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/comment.dart';
import 'package:near_social_mobile/modules/home/apis/models/like.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:near_social_mobile/modules/home/apis/models/reposter.dart';
import 'package:near_social_mobile/modules/home/apis/models/reposter_info.dart';

class NearSocialApi {
  final Dio _dio = Dio();
  final NearBlockChainService _nearBlockChainService;

  NearSocialApi({required NearBlockChainService nearBlockChainService})
      : _nearBlockChainService = nearBlockChainService;

  Future<List<Post>> getPosts({
    int? lastBlockHeightIndexOfPosts,
    int? lastBlockHeightIndexOfReposts,
  }) async {
    try {
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
            likeList: {},
            repostList: {},
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
    } catch (err) {
      rethrow;
    }
  }

  Future<List<FullPostCreationInfo>> _getOnlyPosts({
    int? fromBlockHeight,
    int limit = 30,
  }) async {
    try {
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
          headers: {'Content-Type': 'application/json'},
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
      rethrow;
    }
  }

  Future<List<FullPostCreationInfo>> _getReposts({
    int? fromBlockHeight,
    int limit = 30,
  }) async {
    try {
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
          headers: {'Content-Type': 'application/json'},
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
    } catch (err) {
      rethrow;
    }
  }

  Future<PostBody> getPostContent(
      {required String accountId, required int blockHeight}) async {
    try {
      final data = {
        "keys": ["$accountId/post/main"],
        "blockHeight": blockHeight
      };
      final response = await _dio.request(
        'https://api.near.social/get',
        options: Options(
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
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
    } catch (err) {
      rethrow;
    }
  }

  Future<Set<Like>> getLikesOfPost({
    required String accountId,
    required int blockHeight,
  }) async {
    try {
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
          headers: {'Content-Type': 'application/json'},
        ),
        data: data,
      );

      final likes = List<Map<String, dynamic>>.from(response.data)
          .map((info) => Like(accountId: info["accountId"]))
          .toSet();

      return likes;
    } catch (err) {
      rethrow;
    }
  }

  Future<Set<Reposter>> getRepostsOfPost({
    required String accountId,
    required int blockHeight,
  }) async {
    try {
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
          headers: {'Content-Type': 'application/json'},
        ),
        data: data,
      );
      final reposts = List<Map<String, dynamic>>.from(response.data)
          .map((info) => Reposter(accountId: info["accountId"]))
          .toSet();
      return reposts;
    } catch (err) {
      rethrow;
    }
  }

  Future<DateTime> getDateOfBlockHeight({required int blockHeight}) async {
    try {
      final response = await _dio.request(
        'https://api.near.social/time?blockHeight=$blockHeight',
        options: Options(
          method: 'GET',
        ),
      );
      final epochTime = response.data as int;

      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(epochTime);

      return dateTime;
    } catch (err) {
      rethrow;
    }
  }

  Future<List<Comment>> getCommentsOfPost({
    required String accountId,
    required int blockHeight,
    int? from,
  }) async {
    try {
      final commentsInfoCreation = await _getListOfCommentCreationInfoOfPost(
        accountId: accountId,
        blockHeight: blockHeight,
      );

      final List<Comment> comments = [];

      for (final info in commentsInfoCreation) {
        final CommentBody commentBody = await _getCommentContent(
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
            commentBody: commentBody,
            date: date,
            likeList: likes,
          ),
        );
      }

      return comments;
    } catch (err) {
      rethrow;
    }
  }

  Future<List<CommentCreationInfo>> _getListOfCommentCreationInfoOfPost({
    required String accountId,
    required int blockHeight,
    int? from,
  }) async {
    try {
      final data = json.encode({
        "action": "comment",
        "key": {
          "type": "social",
          "path": "$accountId/post/main",
          "blockHeight": blockHeight
        },
        "options": {
          "limit": 50,
          "order": "desc",
          if (from != null) "from": from,
        }
      });
      final response = await _dio.request(
        'https://api.near.social/index',
        options: Options(
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
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
      return comments;
    } catch (err) {
      rethrow;
    }
  }

  Future<CommentBody> _getCommentContent(
      {required String accountId, required int blockHeight}) async {
    try {
      final data = {
        "keys": ["$accountId/post/comment"],
        "blockHeight": blockHeight
      };
      final response = await _dio.request(
        'https://api.near.social/get',
        options: Options(
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
        ),
        data: data,
      );
      final commentInfo =
          jsonDecode(response.data[accountId]["post"]["comment"]);
      const urlTemplateForImage = "https://ipfs.near.social/ipfs/";
      return CommentBody(
        text: commentInfo["text"],
        mediaLink: commentInfo["image"] != null
            ? commentInfo["image"]["ipfs_cid"] != null
                ? urlTemplateForImage + commentInfo["image"]["ipfs_cid"]
                : commentInfo["image"]["url"]
            : null,
      );
    } catch (err) {
      rethrow;
    }
  }

  Future<List<Like>> _getLikesOfComment(
      {required String accountId, required int blockHeight}) async {
    try {
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
          headers: {'Content-Type': 'application/json'},
        ),
        data: data,
      );
      final likes = List<Map<String, dynamic>>.from(response.data)
          .map((info) => Like(accountId: info["accountId"]))
          .toList();

      return likes;
    } catch (err) {
      rethrow;
    }
  }

  Future<AuthorInfo> getAuthorInfo({required String accountId}) async {
    try {
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
      final int endOfUserName = titleText.indexOf('(');

      late String? name;
      if (endOfUserName == -1) {
        name = null;
      } else {
        name = titleText.substring(0, endOfUserName).trim();
      }

      // Extract the og:image meta tag content which contains the picture URL
      final ogImageElement =
          document.querySelector('meta[property="og:image"]');
      final pictureUrl = ogImageElement!.attributes['content']!;

      return AuthorInfo(
        accountId: accountId,
        name: name,
        profileImageLink: pictureUrl,
      );
    } catch (err) {
      rethrow;
    }
  }

  String getUrlOfPost({required String accountId, required int blockHeight}) {
    return "https://near.social/mob.near/widget/MainPage.N.Post.Page?accountId=$accountId&blockHeight=$blockHeight";
  }

  Future<void> likePost({
    required String accountIdOfPost,
    required int blockHeight,
    required String accountId,
    required String publicKey,
    required String privateKey,
  }) async {
    try {
      final response = await _nearBlockChainService.callSmartContractFunction(
        "social.near",
        accountId,
        privateKey,
        publicKey,
        NearBlockChainSmartContractArguments(
          args: {
            "data": {
              accountId: {
                "index": {
                  "like":
                      '''{\\"key\\":{\\"type\\":\\"social\\",\\"path\\":\\"$accountIdOfPost/post/main\\",\\"blockHeight\\":$blockHeight},\\"value\\":{\\"type\\":\\"like\\"}}''',
                  "notify":
                      '''{\\"key\\":\\"$accountIdOfPost\\",\\"value\\":{\\"type\\":\\"like\\",\\"item\\":{\\"type\\":\\"social\\",\\"path\\":\\"$accountIdOfPost/post/main\\",\\"blockHeight\\":$blockHeight}}}'''
                }
              }
            }
          },
          method: "set",
          transferAmount: "0",
        ),
      );

      if (response.status != "success") {
        throw Exception(
            response.data["error"] ?? "Failed to call smart contract");
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<void> unlikePost({
    required String accountIdOfPost,
    required int blockHeight,
    required String accountId,
    required String publicKey,
    required String privateKey,
  }) async {
    try {
      final response = await _nearBlockChainService.callSmartContractFunction(
        "social.near",
        accountId,
        privateKey,
        publicKey,
        NearBlockChainSmartContractArguments(
          args: {
            "data": {
              accountId: {
                "index": {
                  "like":
                      '''{\\"key\\":{\\"type\\":\\"social\\",\\"path\\":\\"$accountIdOfPost/post/main\\",\\"blockHeight\\":$blockHeight},\\"value\\":{\\"type\\":\\"unlike\\"}}'''
                }
              }
            }
          },
          method: "set",
          transferAmount: "0",
        ),
      );

      if (response.status != "success") {
        throw Exception(
            response.data["error"] ?? "Failed to call smart contract");
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<void> likeComment({
    required String accountIdOfPost,
    required int blockHeight,
    required String accountId,
    required String publicKey,
    required String privateKey,
  }) async {
    try {
      final response = await _nearBlockChainService.callSmartContractFunction(
        "social.near",
        accountId,
        privateKey,
        publicKey,
        NearBlockChainSmartContractArguments(
          args: {
            "data": {
              accountId: {
                "index": {
                  "like":
                      '''{\\"key\\":{\\"type\\":\\"social\\",\\"path\\":\\"$accountIdOfPost/post/comment\\",\\"blockHeight\\":$blockHeight},\\"value\\":{\\"type\\":\\"like\\"}}'''
                }
              }
            }
          },
          method: "set",
          transferAmount: "0",
        ),
      );

      if (response.status != "success") {
        throw Exception(
            response.data["error"] ?? "Failed to call smart contract");
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<void> unlikeComment({
    required String accountIdOfPost,
    required int blockHeight,
    required String accountId,
    required String publicKey,
    required String privateKey,
  }) async {
    try {
      final response = await _nearBlockChainService.callSmartContractFunction(
        "social.near",
        accountId,
        privateKey,
        publicKey,
        NearBlockChainSmartContractArguments(
          args: {
            "data": {
              accountId: {
                "index": {
                  "like":
                      '''{\\"key\\":{\\"type\\":\\"social\\",\\"path\\":\\"$accountIdOfPost/post/comment\\",\\"blockHeight\\":$blockHeight},\\"value\\":{\\"type\\":\\"unlike\\"}}'''
                }
              }
            }
          },
          method: "set",
          transferAmount: "0",
        ),
      );

      if (response.status != "success") {
        throw Exception(
            response.data["error"] ?? "Failed to call smart contract");
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<void> repostPost({
    required String accountIdOfPost,
    required int blockHeight,
    required String accountId,
    required String publicKey,
    required String privateKey,
  }) async {
    try {
      final response = await _nearBlockChainService.callSmartContractFunction(
        "social.near",
        accountId,
        privateKey,
        publicKey,
        NearBlockChainSmartContractArguments(
          args: {
            "data": {
              accountId: {
                "index": {
                  "repost":
                      '''[{\\"key\\":\\"main\\",\\"value\\":{\\"type\\":\\"repost\\",\\"item\\":{\\"type\\":\\"social\\",\\"path\\":\\"$accountIdOfPost/post/main\\",\\"blockHeight\\":$blockHeight}}},{\\"key\\":{\\"type\\":\\"social\\",\\"path\\":\\"$accountIdOfPost/post/main\\",\\"blockHeight\\":$blockHeight},\\"value\\":{\\"type\\":\\"repost\\"}}]''',
                  "notify":
                      '''{\\"key\\":\\"$accountIdOfPost\\",\\"value\\":{\\"type\\":\\"repost\\",\\"item\\":{\\"type\\":\\"social\\",\\"path\\":\\"$accountIdOfPost/post/main\\",\\"blockHeight\\":$blockHeight}}}'''
                }
              }
            }
          },
          method: "set",
          transferAmount: "0",
        ),
      );

      if (response.status != "success") {
        throw Exception(
            response.data["error"] ?? "Failed to call smart contract");
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<String> uploadFileToNearFileHosting({required String filepath}) async {
    try {
      final file = File(filepath);
      var headers = {'Content-Type': 'image/jpeg'};

      var response = await _dio.request(
        'https://ipfs.near.social/add',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: file.readAsBytesSync(),
      );
      return response.data["cid"];
    } catch (err) {
      rethrow;
    }
  }

  Future<void> comentThePost({
    required String accountIdOfPost,
    required int blockHeight,
    required String accountId,
    required String publicKey,
    required String privateKey,
    required PostBody postBody,
  }) async {
    try {
      final imageParameters = postBody.mediaLink != null
          ? """,\\"image\\":{\\"ipfs_cid\\":\\"${postBody.mediaLink}\\"}"""
          : "";
      final response = await _nearBlockChainService.callSmartContractFunction(
        "social.near",
        accountId,
        privateKey,
        publicKey,
        NearBlockChainSmartContractArguments(
          args: {
            "data": {
              accountId: {
                "post": {
                  "comment":
                      """{\\"item\\":{\\"type\\":\\"social\\",\\"path\\":\\"$accountIdOfPost/post/main\\",\\"blockHeight\\":$blockHeight},\\"type\\":\\"md\\",\\"text\\":\\"${postBody.text}\\"$imageParameters}"""
                },
                "index": {
                  "comment":
                      """{\\"key\\":{\\"type\\":\\"social\\",\\"path\\":\\"$accountIdOfPost/post/main\\",\\"blockHeight\\":$blockHeight},\\"value\\":{\\"type\\":\\"md\\"}}""",
                  "notify":
                      """{\\"key\\":\\"$accountIdOfPost\\",\\"value\\":{\\"type\\":\\"comment\\",\\"item\\":{\\"type\\":\\"social\\",\\"path\\":\\"$accountIdOfPost/post/main\\",\\"blockHeight\\":$blockHeight}}}"""
                }
              }
            }
          },
          method: "set",
          transferAmount: "0",
        ),
      );

      if (response.status != "success") {
        throw Exception(
            response.data["error"] ?? "Failed to call smart contract");
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<void> createPost({
    required String accountId,
    required String publicKey,
    required String privateKey,
    required PostBody postBody,
  }) async {
    try {
      final imageParameters = postBody.mediaLink != null
          ? """,\\"image\\":{\\"ipfs_cid\\":\\"${postBody.mediaLink}\\"}"""
          : "";
      final response = await _nearBlockChainService.callSmartContractFunction(
        "social.near",
        accountId,
        privateKey,
        publicKey,
        NearBlockChainSmartContractArguments(
          args: {
            "data": {
              accountId: {
                "post": {
                  "main":
                      """{\\"type\\":\\"md\\",\\"text\\":\\"${postBody.text}\\"$imageParameters}"""
                },
                "index": {
                  "post":
                      """{\\"key\\":\\"main\\",\\"value\\":{\\"type\\":\\"md\\"}}"""
                }
              }
            }
          },
          method: "set",
          transferAmount: "0",
        ),
      );

      if (response.status != "success") {
        throw Exception(
            response.data["error"] ?? "Failed to call smart contract");
      }
    } catch (err) {
      rethrow;
    }
  }
}