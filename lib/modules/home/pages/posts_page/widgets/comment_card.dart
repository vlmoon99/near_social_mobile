import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/modules/home/apis/models/comment.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/create_comment_dialog_body.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/shared_widgets/scale_animated_iconbutton.dart';
import 'package:near_social_mobile/shared_widgets/two_states_iconbutton.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';

class CommentCard extends StatelessWidget {
  const CommentCard({super.key, required this.comment, required this.post});

  final Comment comment;
  final Post post;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    return Card(
      child: RPadding(
        padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                DateFormat('hh:mm a MMM dd, yyyy').format(comment.date),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12.sp,
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: NearNetworkImage(
                    imageUrl: comment.authorInfo.profileImageLink,
                    placeholder: Image.asset(
                      NearAssets.standartAvatar,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    "${comment.authorInfo.name} @${comment.authorInfo.accountId}",
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              comment.commentBody.text.trim(),
            ),
            if (comment.commentBody.mediaLink != null) ...[
              NearNetworkImage(
                imageUrl: comment.commentBody.mediaLink!,
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TwoStatesIconButton(
                  iconPath: NearAssets.commentIcon,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          child: CreateCommentDialog(
                            descriptionTitle: Text.rich(
                              style: TextStyle(fontSize: 14.sp),
                              TextSpan(
                                children: [
                                  const TextSpan(text: "Answer to "),
                                  TextSpan(
                                    text: "@${comment.authorInfo.accountId}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            post: post,
                            initialText: "@${comment.authorInfo.accountId}, ",
                          ),
                        );
                      },
                    );
                  },
                ),
                ScaleAnimatedIconButtonWithCounter(
                  iconPath: NearAssets.likeIcon,
                  iconActivatedPath: NearAssets.activatedLikeIcon,
                  count: comment.likeList.length,
                  activated: comment.likeList.any(
                    (element) =>
                        element.accountId == authController.state.accountId,
                  ),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await Modular.get<PostsController>().likeComment(
                      post: post,
                      comment: comment,
                      accountId: authController.state.accountId,
                      publicKey: authController.state.publicKey,
                      privateKey: authController.state.privateKey,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
