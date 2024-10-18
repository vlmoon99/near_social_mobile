// ignore_for_file: hash_and_equals

import 'package:equatable/equatable.dart';
import 'package:near_social_mobile/modules/home/apis/models/general_account_info.dart';
import 'package:near_social_mobile/modules/home/apis/models/comment.dart';
import 'package:near_social_mobile/modules/home/apis/models/like.dart';
import 'package:near_social_mobile/modules/home/apis/models/reposter.dart';
import 'package:near_social_mobile/modules/home/apis/models/reposter_info.dart';

class Post extends Equatable {
  final GeneralAccountInfo authorInfo;
  final int blockHeight;
  final DateTime date;
  final PostBody postBody;
  final ReposterInfo? reposterInfo;
  final List<Like> likeList;
  final List<Reposter> repostList;
  final List<Comment>? commentList;
  final bool fullyLoaded;

  const Post({
    required this.authorInfo,
    required this.blockHeight,
    required this.date,
    required this.postBody,
    this.reposterInfo,
    required this.likeList,
    required this.repostList,
    required this.commentList,
    this.fullyLoaded = false,
  });

  Post copyWith({
    GeneralAccountInfo? authorInfo,
    int? blockHeight,
    DateTime? date,
    PostBody? postBody,
    ReposterInfo? reposterInfo,
    List<Like>? likeList,
    List<Reposter>? repostList,
    List<Comment>? commentList,
    bool? fullyLoaded,
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
      fullyLoaded: fullyLoaded ?? this.fullyLoaded,
    );
  }

  @override
  List<Object?> get props => [
        authorInfo,
        blockHeight,
        date,
        postBody,
        reposterInfo,
        likeList,
        repostList,
        commentList,
        fullyLoaded,
      ];

  @override
  bool? get stringify => true;
}

class FullPostCreationInfo extends Equatable {
  final PostCreationInfo postCreationInfo;
  final PostCreationInfo? reposterPostCreationInfo;

  const FullPostCreationInfo({
    required this.postCreationInfo,
    this.reposterPostCreationInfo,
  });

  @override
  List<Object?> get props => [postCreationInfo, reposterPostCreationInfo];
      
  @override
  bool? get stringify => true;
}

class PostCreationInfo extends Equatable {
  final String accountId;
  final int blockHeight;

  const PostCreationInfo({
    required this.accountId,
    required this.blockHeight,
  });

  @override
  List<Object?> get props => [accountId, blockHeight];
      
  @override
  bool? get stringify => true;
}

class PostBody extends Equatable {
  final String text;
  final String? mediaLink;

  const PostBody({
    required this.text,
    this.mediaLink,
  });

  @override
  List<Object?> get props => [text, mediaLink];
      
  @override
  bool? get stringify => true;
}
