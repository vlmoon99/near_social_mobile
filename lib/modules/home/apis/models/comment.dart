// ignore_for_file: hash_and_equals

import 'package:flutter/foundation.dart';
import 'package:near_social_mobile/modules/home/apis/models/general_account_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/like.dart';

class Comment {
  final GeneralAccountInfo authorInfo;
  final int blockHeight;
  final DateTime date;
  final CommentBody commentBody;
  final List<Like> likeList;

  Comment({
    required this.authorInfo,
    required this.blockHeight,
    required this.date,
    required this.commentBody,
    required this.likeList,
  });

  Comment copyWith({
    GeneralAccountInfo? authorInfo,
    int? blockHeight,
    DateTime? date,
    CommentBody? commentBody,
    List<Like>? likeList,
  }) {
    return Comment(
      authorInfo: authorInfo ?? this.authorInfo,
      blockHeight: blockHeight ?? this.blockHeight,
      date: date ?? this.date,
      commentBody: commentBody ?? this.commentBody,
      likeList: likeList ?? this.likeList,
    );
  }

  @override
  operator ==(Object other) =>
      other is Comment &&
      other.blockHeight == blockHeight &&
      other.authorInfo == authorInfo &&
      other.date == date &&
      other.commentBody == commentBody &&
      listEquals(other.likeList, likeList);

  @override
  String toString() {
    return 'Comment(authorAccountId: ${authorInfo.accountId}, blockHeight: $blockHeight, date: $date, text: ${commentBody.text}, authorProfileImageLink: ${authorInfo.profileImageLink}, likeList: $likeList)';
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
  final String? mediaLink;

  CommentBody({required this.text, required this.mediaLink});

  @override
  operator ==(Object other) =>
      other is CommentBody &&
      other.text == text &&
      other.mediaLink == mediaLink;
}
