// ignore_for_file: hash_and_equals

import 'package:flutter/foundation.dart';
import 'package:near_social_mobile/modules/home/apis/models/author_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/comment.dart';
import 'package:near_social_mobile/modules/home/apis/models/like.dart';
import 'package:near_social_mobile/modules/home/apis/models/reposter.dart';
import 'package:near_social_mobile/modules/home/apis/models/reposter_info.dart';

class Post {
  final AuthorInfo authorInfo;
  final int blockHeight;
  final DateTime date;
  final PostBody postBody;
  final ReposterInfo? reposterInfo;
  final Set<Like> likeList;
  final Set<Reposter> repostList;
  final List<Comment>? commentList;

  Post({
    required this.authorInfo,
    required this.blockHeight,
    required this.date,
    required this.postBody,
    this.reposterInfo,
    required this.likeList,
    required this.repostList,
    required this.commentList,
  });

  Post copyWith({
    AuthorInfo? authorInfo,
    int? blockHeight,
    DateTime? date,
    PostBody? postBody,
    ReposterInfo? reposterInfo,
    Set<Like>? likeList,
    Set<Reposter>? repostList,
    List<Comment>? commentList,
  }) {
    return Post(
      authorInfo: authorInfo ?? this.authorInfo,
      blockHeight: blockHeight ?? this.blockHeight,
      date: date ?? this.date,
      postBody: postBody ?? this.postBody,
      reposterInfo: reposterInfo ?? this.reposterInfo,
      likeList: likeList ?? this.likeList,
      repostList: repostList ?? this.repostList,
      commentList: commentList ?? this.commentList,
    );
  }

  @override
  operator ==(Object other) =>
      other is Post &&
      other.blockHeight == blockHeight &&
      other.authorInfo == authorInfo &&
      other.date == date &&
      other.postBody == postBody &&
      other.reposterInfo == reposterInfo &&
      setEquals(other.likeList, likeList) &&
      setEquals(other.repostList, repostList) &&
      listEquals(other.commentList, commentList);

  @override
  String toString() {
    return """Post(authorAccountId: ${authorInfo.accountId}, blockHeight: $blockHeight, 
    date: $date, postBody: $postBody, authorProfileImageLink: ${authorInfo.profileImageLink}, 
    reposterInfo: $reposterInfo, likeList: $likeList, repostList: $repostList, 
    commentList: $commentList)""";
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


class PostBody {
  String text;
  String? mediaLink;

  PostBody({
    required this.text,
    this.mediaLink,
  });

  @override
  operator ==(Object other) =>
      other is PostBody && other.text == text && other.mediaLink == mediaLink;

  @override
  String toString() {
    return 'PostBody(text: $text, mediaLink: $mediaLink)';
  }
}


