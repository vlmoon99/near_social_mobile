import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutterchain/flutterchain_lib/constants/core/blockchain_response.dart';
import 'package:flutterchain/flutterchain_lib/constants/core/blockchains_gas.dart';
import 'package:flutterchain/flutterchain_lib/constants/core/supported_blockchains.dart';
import 'package:flutterchain/flutterchain_lib/formaters/chains/near_formater.dart';
import 'package:flutterchain/flutterchain_lib/models/chains/near/near_account_info_request.dart';
import 'package:flutterchain/flutterchain_lib/models/chains/near/near_blockchain_smart_contract_arguments.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/exceptions/near_social_api_exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/models/follower.dart';
import 'package:near_social_mobile/modules/home/apis/models/general_account_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/comment.dart';
import 'package:near_social_mobile/modules/home/apis/models/like.dart';
import 'package:near_social_mobile/modules/home/apis/models/near_widget_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/nft.dart';
import 'package:near_social_mobile/modules/home/apis/models/notification.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/reposter.dart';
import 'package:near_social_mobile/modules/home/apis/models/reposter_info.dart';
import 'package:near_social_mobile/network/dio_interceptors/retry_on_connection_changed_interceptor.dart';
import 'package:near_social_mobile/utils/is_web_image_avaliable.dart';

class NearSocialApi {
  final Dio _dio = Dio();
  final NearBlockChainService _nearBlockChainService;

  NearSocialApi({required NearBlockChainService nearBlockChainService})
      : _nearBlockChainService = nearBlockChainService {
    _dio.interceptors.addAll([
      RetryInterceptor(
        dio: _dio,
        logPrint: log,
        retries: 5,
        retryDelays: [
          ...List.generate(5, (index) => const Duration(seconds: 1))
        ],
      ),
      RetryOnConnectionChangeInterceptor(
        dio: _dio,
        connectivity: Connectivity(),
      ),
    ]);
  }

  Future<List<Post>> getPosts({
    int? lastBlockHeightIndexOfPosts,
    int? lastBlockHeightIndexOfReposts,
    List<String>? targetAccounts,
    int? limit = 10,
  }) async {
    try {
      final onlyPosts = await _getOnlyPosts(
          limit: limit,
          fromBlockHeight: lastBlockHeightIndexOfPosts,
          targetAccounts: targetAccounts);
      final reposts = await _getReposts(
        limit: limit,
        fromBlockHeight: lastBlockHeightIndexOfReposts,
        targetAccounts: targetAccounts,
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
        final authorInfo = GeneralAccountInfo(
          accountId: info.postCreationInfo.accountId,
          profileImageLink: "",
          name: "",
          description: "",
          backgroundImageLink: "",
          linktree: {},
          tags: [],
        );
        ReposterInfo? reposterInfo;
        if (info.reposterPostCreationInfo != null) {
          reposterInfo = ReposterInfo(
            accountInfo: GeneralAccountInfo(
              accountId: info.reposterPostCreationInfo!.accountId,
              profileImageLink: "",
              name: "",
              description: "",
              backgroundImageLink: "",
              linktree: {},
              tags: [],
            ),
            blockHeight: info.reposterPostCreationInfo!.blockHeight,
          );
        }

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
        );
      }

      return posts;
    } catch (err) {
      rethrow;
    }
  }

  Future<List<FullPostCreationInfo>> _getOnlyPosts({
    int? fromBlockHeight,
    int? limit,
    List<String>? targetAccounts,
  }) async {
    try {
      final data = {
        "action": "post",
        "key": "main",
        "options": {
          if (limit != null) "limit": limit,
          "order": "desc",
          if (fromBlockHeight != null) "from": fromBlockHeight,
          if (targetAccounts != null) "accountId": targetAccounts
        }
      };
      final response = await _dio.request(
        '${NearUrls.nearSocialApi}/index',
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
    int? limit,
    List<String>? targetAccounts,
  }) async {
    try {
      final data = {
        "action": "repost",
        "key": "main",
        "options": {
          if (limit != null) "limit": limit,
          "order": "desc",
          if (fromBlockHeight != null) "from": fromBlockHeight,
          if (targetAccounts != null) "accountId": targetAccounts,
        }
      };
      final response = await _dio.request(
        '${NearUrls.nearSocialApi}/index',
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
        '${NearUrls.nearSocialApi}/get',
        options: Options(
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
        ),
        data: data,
      );
      if (response.data[accountId] == null) {
        return PostBody(text: "", mediaLink: null);
      }

      late final Map<String, dynamic> postInfo;
      try {
        postInfo = jsonDecode(response.data[accountId]["post"]["main"]);
      } catch (err) {
        postInfo = {};
      }
      return PostBody(
        text: postInfo["text"] ?? "",
        mediaLink: postInfo["image"] != null
            ? postInfo["image"]["ipfs_cid"] != null
                ? NearUrls.nearSocialIpfsMediaHosting +
                    postInfo["image"]["ipfs_cid"]
                : postInfo["image"]["url"]
            : null,
      );
    } catch (err) {
      log("$err\n Post: accountId: $accountId, blockHeight: $blockHeight");
      return PostBody(text: "", mediaLink: null);
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
        '${NearUrls.nearSocialApi}/index',
        options: Options(
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
        ),
        data: data,
      );

      final likes =
          _convertToLikes(List<Map<String, dynamic>>.from(response.data));

      return likes;
    } catch (err) {
      rethrow;
    }
  }

  Set<Like> _convertToLikes(List<Map<String, dynamic>> data) {
    Map<String, Map<String, dynamic>> lastRecordOfUser = {};

    for (var item in data) {
      String accountId = item["accountId"];
      String type = item["value"]["type"];
      int blockHeight = item["blockHeight"];

      if (lastRecordOfUser[accountId] == null) {
        lastRecordOfUser[accountId] = {
          "type": type,
          "blockHeight": blockHeight
        };
      } else {
        if (lastRecordOfUser[accountId]!["blockHeight"] < blockHeight) {
          lastRecordOfUser[accountId] = {
            "type": type,
            "blockHeight": blockHeight
          };
        }
      }
    }

    Set<Like> result = {};

    lastRecordOfUser.forEach((key, value) {
      if (value["type"] == "like") {
        result.add(Like(accountId: key));
      }
    });

    return result;
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
        '${NearUrls.nearSocialApi}/index',
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
        '${NearUrls.nearSocialApi}/time?blockHeight=$blockHeight',
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
        // final CommentBody commentBody = await getCommentContent(
        //   accountId: info.accountId,
        //   blockHeight: info.blockHeight,
        // );
        // final date = await getDateOfBlockHeight(
        //   blockHeight: info.blockHeight,
        // );

        final authorInfo = await getGeneralAccountInfo(
          accountId: info.accountId,
        );

        // final likes = await getLikesOfComment(
        //   accountId: info.accountId,
        //   blockHeight: info.blockHeight,
        // );

        comments.add(
          Comment(
            authorInfo: authorInfo,
            blockHeight: info.blockHeight,
            commentBody: CommentBody(text: "Loading...", mediaLink: null),
            date: DateTime.now(),
            likeList: {},
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
        '${NearUrls.nearSocialApi}/index',
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

  Future<CommentBody> getCommentContent(
      {required String accountId, required int blockHeight}) async {
    try {
      final data = {
        "keys": ["$accountId/post/comment"],
        "blockHeight": blockHeight
      };
      final response = await _dio.request(
        '${NearUrls.nearSocialApi}/get',
        options: Options(
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
        ),
        data: data,
      );
      final commentInfo =
          jsonDecode(response.data[accountId]["post"]["comment"]);
      return CommentBody(
        text: commentInfo["text"],
        mediaLink: commentInfo["image"] != null
            ? commentInfo["image"]["ipfs_cid"] != null
                ? NearUrls.nearSocialIpfsMediaHosting +
                    commentInfo["image"]["ipfs_cid"]
                : commentInfo["image"]["url"]
            : null,
      );
    } catch (err) {
      rethrow;
    }
  }

  Future<Set<Like>> getLikesOfComment(
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
        '${NearUrls.nearSocialApi}/index',
        options: Options(
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
        ),
        data: data,
      );
      final likes =
          _convertToLikes(List<Map<String, dynamic>>.from(response.data));

      return likes;
    } catch (err) {
      rethrow;
    }
  }

  Future<GeneralAccountInfo> getGeneralAccountInfo(
      {required String accountId}) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final data = json.encode({
        "keys": ["$accountId/profile/**"]
      });
      final response = await _dio.request(
        '${NearUrls.nearSocialApi}/get',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      final profileInfo = (response.data as Map<String, dynamic>).isNotEmpty
          ? (response.data[accountId]["profile"] ?? {}) as Map<String, dynamic>
          : {};

      return GeneralAccountInfo(
          accountId: accountId,
          name: profileInfo["name"] ?? "",
          description: profileInfo["description"] ?? "",
          linktree: profileInfo["linktree"] ?? {},
          tags: profileInfo["tags"] != null
              ? (profileInfo["tags"] as Map<String, dynamic>).keys.toList()
              : [],
          profileImageLink:
              "https://i.near.social/magic/large/https://near.social/magic/img/account/$accountId",
          backgroundImageLink: _getLinkOfNearPicture(
              requestBody: profileInfo, typeOfImage: "backgroundImage"));
    } catch (err) {
      rethrow;
    }
  }

  String _getLinkOfNearPicture(
      {required Map requestBody, required String typeOfImage}) {
    String imageLink = "";

    try {
      if (requestBody[typeOfImage] != null) {
        final image = requestBody[typeOfImage];

        if (image["ipfs_cid"] != null) {
          imageLink = NearUrls.nearSocialIpfsMediaHosting + image["ipfs_cid"];
        } else if (image["url"] != null) {
          imageLink = image["url"];
        } else if (image["nft"] != null) {
          final nft = image["nft"];
          if (nft["contractId"] != null && nft["tokenId"] != null) {
            imageLink =
                "https://i.near.social/magic/large/https://near.social/magic/img/nft/${nft["contractId"]}/${nft["tokenId"]}";
          }
        }
      }
      return imageLink;
    } catch (err) {
      log(err.toString());
      return imageLink;
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
        NearBlockChainSmartContractArguments(
          accountId: accountId,
          publicKey: publicKey,
          toAddress: "social.near",
          privateKey: privateKey,
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
        NearBlockChainSmartContractArguments(
          accountId: accountId,
          publicKey: publicKey,
          privateKey: privateKey,
          toAddress: "social.near",
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
        NearBlockChainSmartContractArguments(
          accountId: accountId,
          publicKey: publicKey,
          toAddress: "social.near",
          privateKey: privateKey,
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
        NearBlockChainSmartContractArguments(
          accountId: accountId,
          publicKey: publicKey,
          toAddress: "social.near",
          privateKey: privateKey,
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
        NearBlockChainSmartContractArguments(
          accountId: accountId,
          publicKey: publicKey,
          toAddress: "social.near",
          privateKey: privateKey,
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
      final headers = {'Content-Type': 'image/jpeg'};

      final response = await _dio.request(
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
        NearBlockChainSmartContractArguments(
          accountId: accountId,
          publicKey: publicKey,
          toAddress: "social.near",
          privateKey: privateKey,
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
        NearBlockChainSmartContractArguments(
          accountId: accountId,
          publicKey: publicKey,
          toAddress: "social.near",
          privateKey: privateKey,
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

  Future<List<NearWidgetInfo>> getWidgetsList({String? accountId}) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final responseOfWidgetsListWithMetadata = await _dio.request(
        '${NearUrls.nearSocialApi}/get',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: {
          "keys": ["${accountId ?? "*"}/widget/*/metadata/**"]
        },
      );

      final List<String> listOfWidgetPaths = [];

      listOfWidgetPaths.addAll(
        (responseOfWidgetsListWithMetadata.data as Map<String, dynamic>)
            .keys
            .map((accountId) => "$accountId/widget/*")
            .toList(),
      );

      final responseOfAllWidgetsList = await _dio.request(
        '${NearUrls.nearSocialApi}/keys',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: {
          "keys": [...listOfWidgetPaths],
          "options": {"return_type": "BlockHeight"}
        },
      );

      final fullListOfWidgetsWithoutMetadata =
          responseOfAllWidgetsList.data as Map<String, dynamic>;

      final List<NearWidgetInfo> widgets = [];

      (responseOfWidgetsListWithMetadata.data as Map<String, dynamic>).forEach(
        (key, value) {
          final accountId = key;
          final listOfWidgetsData =
              (value["widget"] ?? {}) as Map<String, dynamic>;
          final widgetsNamesWithoutMetadata =
              ((fullListOfWidgetsWithoutMetadata[accountId]["widget"] ?? {})
                      as Map)
                  .keys
                  .toSet()
                  .difference(
                    listOfWidgetsData.keys.toSet(),
                  );
          widgets.addAll(widgetsNamesWithoutMetadata.map((widgetName) {
            return NearWidgetInfo(
              accountId: accountId,
              urlName: widgetName,
              name: "",
              description: "",
              imageUrl: "",
              tags: [],
              blockHeight: fullListOfWidgetsWithoutMetadata[accountId]
                      ?["widget"]?[widgetName] ??
                  0,
            );
          }));

          listOfWidgetsData.forEach(
            (key, value) {
              final widgetUrlName = key;
              final metadata = value["metadata"] as Map<String, dynamic>;
              widgets.add(
                NearWidgetInfo(
                  accountId: accountId,
                  urlName: widgetUrlName,
                  name: metadata["name"] ?? "",
                  description: metadata["description"] ?? "",
                  imageUrl: _getLinkOfNearPicture(
                      requestBody: metadata, typeOfImage: "image"),
                  tags: metadata["tags"] != null
                      ? (metadata["tags"] as Map<String, dynamic>).keys.toList()
                      : [],
                  blockHeight: fullListOfWidgetsWithoutMetadata[accountId]
                          ?["widget"]?[widgetUrlName] ??
                      0,
                ),
              );
            },
          );
        },
      );

      return widgets;
    } catch (err) {
      rethrow;
    }
  }

  Future<List<GeneralAccountInfo>> getNearSocialAccountList() async {
    try {
      var headers = {'Content-Type': 'application/json'};
      var data = {
        "keys": ["*/profile/**"]
      };
      var response = await _dio.request(
        '${NearUrls.nearSocialApi}/get',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );
      final List<GeneralAccountInfo> listOfNearSocialAccounts = [];
      (response.data as Map<String, dynamic>).forEach(
        (accountId, value) {
          final profileInfo = value["profile"] as Map<String, dynamic>;
          listOfNearSocialAccounts.add(
            GeneralAccountInfo(
                accountId: accountId,
                name: profileInfo["name"] ?? "",
                description: profileInfo["description"] ?? "",
                linktree: profileInfo["linktree"] ?? {},
                tags: profileInfo["tags"] != null && profileInfo["tags"] is Map
                    ? (profileInfo["tags"] as Map<String, dynamic>)
                        .keys
                        .toList()
                    : [],
                profileImageLink:
                    "https://i.near.social/magic/large/https://near.social/magic/img/account/$accountId",
                backgroundImageLink: _getLinkOfNearPicture(
                    requestBody: profileInfo, typeOfImage: "backgroundImage")),
          );
        },
      );

      return listOfNearSocialAccounts;
    } catch (err) {
      rethrow;
    }
  }

  Future<List<Follower>> getFollowingsOfAccount(
      {required String accountId}) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final data = {
        "keys": ["$accountId/graph/follow/*"]
      };
      var response = await _dio.request(
        '${NearUrls.nearSocialApi}/keys',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      if ((response.data as Map<String, dynamic>).isEmpty) {
        return [];
      }

      final List<Follower> followings =
          (response.data[accountId]["graph"]?["follow"] as Map<String, dynamic>)
              .keys
              .map((accoundIfOfFollowing) =>
                  Follower(accountId: accoundIfOfFollowing))
              .toList();
      return followings;
    } catch (err) {
      rethrow;
    }
  }

  Future<List<Follower>> getFollowersOfAccount(
      {required String accountId}) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final data = {
        "keys": ["*/graph/follow/$accountId"],
        "options": {"return_type": "BlockHeight", "values_only": true}
      };

      var response = await _dio.request(
        '${NearUrls.nearSocialApi}/keys',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      final List<Follower> followers = (response.data as Map<String, dynamic>)
          .keys
          .map((followerAccountId) => Follower(accountId: followerAccountId))
          .toList();
      return followers;
    } catch (err) {
      rethrow;
    }
  }

  Future<List<String>> getUserTagsOfAccount({required String accountId}) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final data = {
        "keys": ["*/nametag/$accountId/tags/*"]
      };
      final response = await _dio.request(
        '${NearUrls.nearSocialApi}/keys',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      final Set<String> userTags = {};

      if ((response.data as Map<String, dynamic>).isEmpty) {
        return [];
      }

      (response.data as Map<String, dynamic>).forEach((_, value) {
        userTags.addAll(
            (value["nametag"][accountId]["tags"] as Map<String, dynamic>)
                .keys
                .toList());
      });

      return userTags.toList();
    } catch (err) {
      rethrow;
    }
  }

  Future<void> followAccount({
    required String accountIdToFollow,
    required String accountId,
    required String publicKey,
    required String privateKey,
  }) async {
    try {
      final response = await _nearBlockChainService.callSmartContractFunction(
        NearBlockChainSmartContractArguments(
          accountId: accountId,
          publicKey: publicKey,
          toAddress: "social.near",
          privateKey: privateKey,
          args: {
            "data": {
              accountId: {
                "graph": {
                  "follow": {accountIdToFollow: ""}
                },
                "index": {
                  "graph":
                      '''{\\"key\\":\\"follow\\",\\"value\\":{\\"type\\":\\"follow\\",\\"accountId\\":\\"$accountIdToFollow\\"}}''',
                  "notify":
                      '''{\\"key\\":\\"$accountIdToFollow\\",\\"value\\":{\\"type\\":\\"follow\\"}}'''
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

  Future<void> unfollowAccount({
    required String accountIdToUnfollow,
    required String accountId,
    required String publicKey,
    required String privateKey,
  }) async {
    try {
      final response = await _nearBlockChainService.callSmartContractFunction(
        NearBlockChainSmartContractArguments(
          accountId: accountId,
          publicKey: publicKey,
          toAddress: "social.near",
          privateKey: privateKey,
          args: {
            "data": {
              accountId: {
                "graph": {
                  "follow": {accountIdToUnfollow: null}
                },
                "index": {
                  "graph":
                      '''{\\"key\\":\\"follow\\",\\"value\\":{\\"type\\":\\"unfollow\\",\\"accountId\\":\\"$accountIdToUnfollow\\"}}''',
                  "notify":
                      '''{\\"key\\":\\"$accountIdToUnfollow\\",\\"value\\":{\\"type\\":\\"unfollow\\"}}'''
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

  Future<void> pokeAccount({
    required String accountIdToPoke,
    required String accountId,
    required String publicKey,
    required String privateKey,
  }) async {
    try {
      final response = await _nearBlockChainService.callSmartContractFunction(
        NearBlockChainSmartContractArguments(
          accountId: accountId,
          publicKey: publicKey,
          toAddress: "social.near",
          privateKey: privateKey,
          args: {
            "data": {
              accountId: {
                "index": {
                  "graph":
                      '''{\\"key\\":\\"poke\\",\\"value\\":{\\"accountId\\":\\"$accountIdToPoke\\"}}''',
                  "notify":
                      '''{\\"key\\":\\"$accountIdToPoke\\",\\"value\\":{\\"type\\":\\"poke\\"}}'''
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

  Future<List<Nft>> getNftsOfAccount({required String accountIdOfUser}) async {
    final List<Nft> nftList = [];
    final nftListOfAccountResponse = await _dio
        .get("https://api.fastnear.com/v0/account/$accountIdOfUser/nft");

    final Set<String> nftContractIds =
        (List<String>.from(nftListOfAccountResponse.data["contract_ids"]))
            .toSet();

    for (var nftContractId in nftContractIds) {
      final nftsInfo = await _getAllNFTsMetadataInfoFromContractForUser(
        nftContractId: nftContractId,
        accountIdOfUser: accountIdOfUser,
      );

      for (var nftInfo in nftsInfo) {
        final tokenId = nftInfo['token_id'];

        final defaultImageUrl =
            "https://i.near.social/magic/large/https://near.social/magic/img/nft/$nftContractId/$tokenId";

        String? nftImageUrl;
        final reference = nftInfo["metadata"]["reference"] as String?;
        final media = nftInfo["metadata"]["media"] as String?;

        if (media != null &&
            media.startsWith("http") &&
            !media.contains("ipfs")) {
          //checking if media available by url
          final imageAvailable = await isWebImageAvailable(media);
          if (imageAvailable) {
            nftImageUrl = media;
          } else {
            log("Image not available: $media");
          }
        } else if (reference != null &&
            !reference.contains("ipfs") &&
            reference.length == 43) {
          // getting metadata info from arweave
          try {
            final metadataInfo =
                (await _dio.get("https://arweave.net/$reference")).data;

            nftImageUrl = metadataInfo["media"];
          } catch (err) {
            log("Failed to get metadata info from arweave: $err");
          }
        }

        nftList.add(Nft(
          contractId: nftContractId,
          tokenId: tokenId,
          title: nftInfo["metadata"]["title"] ?? "",
          description: nftInfo["metadata"]["description"] ?? "",
          imageUrl: nftImageUrl ?? defaultImageUrl,
        ));
      }
    }
    return nftList;
  }

  Future<List<Map<String, dynamic>>>
      _getAllNFTsMetadataInfoFromContractForUser({
    required String nftContractId,
    required String accountIdOfUser,
  }) async {
    Future<Map<String, dynamic>> getRawDataFromContract(
        Map<String, dynamic> args) async {
      final nftInfoResponse =
          await _nearBlockChainService.nearRpcClient.networkClient.dio.request(
        "",
        data: {
          'jsonrpc': '2.0',
          'id': 'dontcare',
          'method': 'query',
          'params': {
            'request_type': 'call_function',
            'finality': 'final',
            'account_id': nftContractId,
            'method_name': "nft_tokens_for_owner",
            'args_base64': base64.encode(utf8.encode(json.encode(args))),
          },
        },
        options: Options(
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      return nftInfoResponse.data;
    }

    final defaultArgs = {
      "account_id": accountIdOfUser,
      "from_index": "0",
      "limit": 1000 // to get as much data as possible
    };

    final nftInfoResponse = await getRawDataFromContract(defaultArgs);

    if (nftInfoResponse['error'] != null ||
        nftInfoResponse['result']['error'] != null) {
      return [];
      //TODO: solve problem with very large amount of nfts
      // if (nftInfoResponse['result']['error'] != null &&
      //     nftInfoResponse['result']['error'].contains("GasLimitExceeded")) {
      //   const step = 100;
      //   final Map<String, dynamic> indexedArgs = {
      //     "account_id": accountIdOfUser,
      //     "from_index": "0",
      //     "limit": step
      //   };
      //   final List<Map<String, dynamic>> listOfDecodedResponses = [];
      //   while (true) {
      //     final response = await _getRawDataFromContract(indexedArgs);
      //     final decodedResponse = List<Map<String, dynamic>>.from(json.decode(
      //       utf8.decode(
      //         List<int>.from(
      //           response['result']?['result'],
      //         ),
      //       ),
      //     ));
      //     listOfDecodedResponses.addAll(decodedResponse);
      //     if (decodedResponse.length < step) {
      //       break;
      //     }
      //     indexedArgs['from_index'] =
      //         (int.parse(indexedArgs['from_index']) + step).toString();
      //   }
      //   return listOfDecodedResponses;
      // } else {
      //   return [];
      // }
    }

    final decodedResponse = List<Map<String, dynamic>>.from(json.decode(
      utf8.decode(
        List<int>.from(
          nftInfoResponse['result']?['result'],
        ),
      ),
    ));

    return decodedResponse;
  }

  Future<List<Nft>> getMintbaseNfts({required String accountIdOfUser}) async {
    final nftListOfAccountResponse = (await _dio
        .get("https://api.fastnear.com/v0/account/$accountIdOfUser/nft"));

    final Set<String> nftContractIds =
        (List<String>.from(nftListOfAccountResponse.data["contract_ids"]))
            .where((nftContractId) => nftContractId.contains("mintbase"))
            .toSet();
    final List<Nft> nftList = [];

    for (var nftContractId in nftContractIds) {
      final nftsInfo = await _getAllNFTsMetadataInfoFromContractForUser(
        nftContractId: nftContractId,
        accountIdOfUser: accountIdOfUser,
      );

      for (var nftInfo in nftsInfo) {
        final tokenId = nftInfo['token_id'];

        final reference = nftInfo["metadata"]["reference"] as String?;

        if (reference == null ||
            reference.contains("ipfs") ||
            reference.length != 43) {
          log("Not mintbase NFT: $reference");
          continue;
        }

        final metadataInfo =
            (await _dio.get("https://arweave.net/$reference")).data;

        final nftImageUrl = metadataInfo["media"];

        nftList.add(Nft(
          contractId: nftContractId,
          tokenId: tokenId,
          title: nftInfo["metadata"]["title"] ?? "",
          description: metadataInfo["description"] ??
              nftInfo["metadata"]["description"] ??
              "",
          imageUrl: nftImageUrl,
        ));
      }
    }
    return nftList;
  }

  Future<List<Notification>> getNotificationsOfAccount({
    required String accountId,
    int? from,
  }) async {
    try {
      final response = await _dio.request(
        '${NearUrls.nearSocialApi}/index',
        options: Options(
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          "action": "notify",
          "key": accountId,
          "options": {
            "limit": 20,
            "order": "desc",
            if (from != null) "from": from,
          }
        },
      );
      final data = List<Map<String, dynamic>>.from(response.data);
      final List<Notification> notifications = [];

      for (var notificationData in data) {
        final accoundIdOfNotificationCreator = notificationData["accountId"];
        final blockHeight = notificationData["blockHeight"];
        final GeneralAccountInfo authorInfo = await getGeneralAccountInfo(
            accountId: accoundIdOfNotificationCreator);
        final DateTime date =
            await getDateOfBlockHeight(blockHeight: blockHeight);
        final typeOfNotification =
            getNotificationType(notificationData["value"]["type"]);
        notifications.add(
          Notification(
            authorInfo: authorInfo,
            blockHeight: blockHeight,
            date: date,
            notificationType: NotificationType(
              type: typeOfNotification,
              data: getNotificationData(
                notificationData["value"]["item"],
                typeOfNotification,
              ),
            ),
          ),
        );
      }
      return notifications;
    } catch (err) {
      rethrow;
    }
  }

  Future<PrivateKeyInfo> getAccessKeyInfo({
    required String accountId,
    required String key,
  }) async {
    try {
      final publicKeyOfSecretKey = await _nearBlockChainService
          .getPublicKeyFromSecretKeyFromNearApiJSFormat(key.split(":").last);
      final base58PubKey = await _nearBlockChainService
          .getBase58PubKeyFromHexValue(hexEncodedPubKey: publicKeyOfSecretKey);
      final request = {
        "jsonrpc": "2.0",
        "id": "dontcare",
        "method": "query",
        "params": {
          "request_type": "view_access_key",
          "finality": "final",
          "account_id": accountId,
          "public_key": base58PubKey
        }
      };
      final response =
          await _nearBlockChainService.nearRpcClient.networkClient.dio.request(
        "",
        options: Options(
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
        ),
        data: request,
      );
      final permission = response.data["result"]?["permission"];
      if (permission == null) {
        throw Exception(response.data["result"]["error"].toString());
      }
      if (permission is Map && permission.keys.first == "FunctionCall") {
        return PrivateKeyInfo(
          publicKey: publicKeyOfSecretKey,
          privateKey: key,
          base58PubKey: base58PubKey,
          privateKeyTypeInfo: PrivateKeyTypeInfo(
            type: PrivateKeyType.FunctionCall,
            receiverId: permission["FunctionCall"]["receiver_id"],
            methodNames: List<String>.from(
                permission["FunctionCall"]?["method_names"] ?? []),
          ),
        );
      } else if (permission is String && permission == "FullAccess") {
        return PrivateKeyInfo(
          publicKey: publicKeyOfSecretKey,
          privateKey: key,
          base58PubKey: base58PubKey,
          privateKeyTypeInfo: PrivateKeyTypeInfo(
            type: PrivateKeyType.FullAccess,
          ),
        );
      } else {
        throw Exception("Unknown permission type");
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<String> donateToAccount({
    required String accountId,
    required String publicKey,
    required String privateKey,
    required String amountToSend,
    required String receiverId,
  }) async {
    const transactionFeeFor2Transactions = "0.00001";

    final currentBalance = double.parse(await _nearBlockChainService
        .getWalletBalance(NearAccountInfoRequest(accountId: accountId)));
    final neededBalance = double.parse(amountToSend) +
        double.parse(EnterpriseVariables.amountOfServiceFeeForDonation) +
        double.parse(transactionFeeFor2Transactions);

    if (currentBalance < neededBalance) {
      throw AppExceptions(
        messageForUser:
            "Not enough balance. You have $currentBalance NEAR, but you need $neededBalance NEAR.",
        messageForDev:
            "Not enough balance. You have $currentBalance NEAR, but you need $neededBalance NEAR.",
      );
    }

    final txInfo = await _nearBlockChainService.getTransactionInfo(
      accountId: accountId,
      publicKey: publicKey,
    );

    late String txHash;

    try {
      txHash = await _sendTransferTransactions(
        fromAddress: accountId,
        toAddress: receiverId,
        privateKey: privateKey,
        transferAmount: amountToSend,
        nonce: txInfo.nonce,
        blockHash: txInfo.blockHash,
      );
    } on IncorrectNonceException catch (err) {
      final newNonce = err.data["data"]["TxExecutionError"]["InvalidTxError"]
          ["InvalidNonce"]["ak_nonce"];
      txHash = await _sendTransferTransactions(
        fromAddress: accountId,
        toAddress: receiverId,
        privateKey: privateKey,
        transferAmount: amountToSend,
        nonce: newNonce,
        blockHash: txInfo.blockHash,
      );
    } on AppExceptions catch (_) {
      rethrow;
    } catch (err) {
      throw AppExceptions(
        messageForUser: "Failed to send transfer.",
        messageForDev: "Error while sending transfer: ${err.toString()}",
      );
    }

    return txHash;
  }

  Future<String> _formTransferSignedAction({
    required String fromAddress,
    required String toAddress,
    required String privateKey,
    required String transferAmount,
    required String gas,
    required int nonce,
    required String blockHash,
  }) async {
    final transferAction = [
      {
        "type": "transfer",
        "data": {"amount": NearFormatter.nearToYoctoNear(transferAmount)}
      }
    ];

    final signedAction = await _nearBlockChainService.signNearActions(
      fromAddress: fromAddress,
      toAddress: toAddress,
      transferAmount: NearFormatter.nearToYoctoNear(transferAmount),
      privateKey: privateKey,
      gas: gas,
      nonce: nonce,
      blockHash: blockHash,
      actions: transferAction,
    );
    return signedAction;
  }

  Future<String> _sendTransferTransactions({
    required String fromAddress,
    required String toAddress,
    required String privateKey,
    required String transferAmount,
    required int nonce,
    required String blockHash,
  }) async {
    final gas = BlockchainGas.gas[BlockChains.near];

    final mainTransferSignedAction = await _formTransferSignedAction(
      fromAddress: fromAddress,
      toAddress: toAddress,
      privateKey: privateKey,
      transferAmount: transferAmount,
      gas: gas!,
      nonce: nonce,
      blockHash: blockHash,
    );

    final serviceFeeTransferSignedAction = await _formTransferSignedAction(
      fromAddress: fromAddress,
      toAddress: EnterpriseVariables.accountForCollectingServiceFee,
      transferAmount: EnterpriseVariables.amountOfServiceFeeForDonation,
      privateKey: privateKey,
      gas: gas,
      nonce: nonce + 1,
      blockHash: blockHash,
    );

    final mainTransfer = await _nearBlockChainService.nearRpcClient
        .sendSyncTx([mainTransferSignedAction]);

    if (mainTransfer.status != BlockchainResponses.success) {
      if (mainTransfer.data["cause"]["name"] == "INVALID_TRANSACTION" &&
          mainTransfer.data["data"]["TxExecutionError"]["InvalidTxError"]
                  ["InvalidNonce"] !=
              null) {
        throw IncorrectNonceException(data: mainTransfer.data);
      } else {
        throw AppExceptions(
          messageForUser: "Failed to send transfer.",
          messageForDev:
              "Error while sending transfer: ${mainTransfer.data.toString()}",
        );
      }
    }

    while ((await _nearBlockChainService.nearRpcClient
                .sendSyncTx([serviceFeeTransferSignedAction]))
            .status !=
        BlockchainResponses.success) {
      log("Retrying to send service fee transfer...");
    }

    return mainTransfer.data["txHash"];
  }
}
