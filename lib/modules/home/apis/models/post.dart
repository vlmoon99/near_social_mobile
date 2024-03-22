// ignore_for_file: hash_and_equals

import 'package:flutter/foundation.dart';

class Post {
  final AuthorInfo authorInfo;
  final int blockHeight;
  final DateTime date;
  final PostBody postBody;
  final ReposterInfo? reposterInfo;
  final List<Like> likeList;
  final List<Reposter> repostList;
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
    List<Like>? likeList,
    List<Reposter>? repostList,
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
      listEquals(other.likeList, likeList) &&
      listEquals(other.repostList, repostList) &&
      listEquals(other.commentList, commentList);

  @override
  String toString() {
    return """Post(authorAccountId: ${authorInfo.accountId}, blockHeight: $blockHeight, 
    date: $date, postBody: $postBody, authorProfileImageLink: ${authorInfo.profileImageLink}, 
    reposterInfo: $reposterInfo, likeList: $likeList, repostList: $repostList, 
    commentList: $commentList)""";
  }
}

class ReposterInfo {
  final String accountId;
  final String? name;
  final int blockHeight;

  ReposterInfo({
    required this.accountId,
    this.name,
    required this.blockHeight,
  });

  ReposterInfo copyWith({
    String? accountId,
    String? name,
    int? blockHeight,
  }) {
    return ReposterInfo(
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      blockHeight: blockHeight ?? this.blockHeight,
    );
  }

  @override
  operator ==(Object other) =>
      other is ReposterInfo &&
      other.blockHeight == blockHeight &&
      other.accountId == accountId;
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

class Reposter {
  String accountId;

  Reposter({
    required this.accountId,
  });

  @override
  operator ==(Object other) =>
      other is Reposter && other.accountId == accountId;

  @override
  String toString() {
    return 'Reposter(accountId: $accountId)';
  }
}

class Like {
  String accountId;

  Like({
    required this.accountId,
  });

  @override
  String toString() {
    return 'Like(accountId: $accountId)';
  }

  @override
  operator ==(Object other) => other is Like && other.accountId == accountId;
}

class Comment {
  final AuthorInfo authorInfo;
  final int blockHeight;
  final DateTime date;
  final String text;
  final List<Like> likeList;

  Comment({
    required this.authorInfo,
    required this.blockHeight,
    required this.date,
    required this.text,
    required this.likeList,
  });

  @override
  operator ==(Object other) =>
      other is Comment &&
      other.blockHeight == blockHeight &&
      other.authorInfo == authorInfo &&
      other.date == date &&
      other.text == text &&
      listEquals(other.likeList, likeList);

  @override
  String toString() {
    return 'Comment(authorAccountId: ${authorInfo.accountId}, blockHeight: $blockHeight, date: $date, text: $text, authorProfileImageLink: ${authorInfo.profileImageLink}, likeList: $likeList)';
  }
}

class AuthorInfo {
  final String accountId;
  final String? name;
  final String profileImageLink;

  AuthorInfo({
    required this.accountId,
    this.name,
    required this.profileImageLink,
  });

  @override
  operator ==(Object other) =>
      other is AuthorInfo &&
      other.accountId == accountId &&
      other.name == name &&
      other.profileImageLink == profileImageLink;
}
