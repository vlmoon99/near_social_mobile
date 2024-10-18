// ignore_for_file: hash_and_equals

import 'package:equatable/equatable.dart';
import 'package:near_social_mobile/modules/home/apis/models/general_account_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/like.dart';

class Comment extends Equatable {
  final GeneralAccountInfo authorInfo;
  final int blockHeight;
  final DateTime date;
  final CommentBody commentBody;
  final List<Like> likeList;

  const Comment({
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
  List<Object?> get props =>
      [authorInfo, blockHeight, date, commentBody, likeList];

  @override
  bool? get stringify => true;
}

class CommentCreationInfo extends Equatable {
  final String accountId;
  final int blockHeight;

  const CommentCreationInfo({
    required this.accountId,
    required this.blockHeight,
  });

  @override
  List<Object?> get props => [accountId, blockHeight];

  @override
  bool? get stringify => true;
}

class CommentBody extends Equatable {
  final String text;
  final String? mediaLink;

  const CommentBody({required this.text, required this.mediaLink});

  @override
  List<Object?> get props => [text, mediaLink];

  @override
  bool? get stringify => true;
}
