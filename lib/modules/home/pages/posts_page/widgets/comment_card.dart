import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/modules/home/apis/models/comment.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/create_comment_dialog_body.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/more_actions_for_comment_button.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/raw_text_to_content_formatter.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/image_full_screen_page.dart';
import 'package:near_social_mobile/shared_widgets/scale_animated_iconbutton.dart';
import 'package:near_social_mobile/shared_widgets/two_states_iconbutton.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';
import 'package:near_social_mobile/utils/date_to_string.dart';

class CommentCard extends StatelessWidget {
  const CommentCard({
    super.key,
    required this.comment,
    required this.post,
    required this.postsViewMode,
    this.postsOfAccountId,
  });

  final Comment comment;
  final Post post;
  final PostsViewMode postsViewMode;
  final String? postsOfAccountId;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0).r,
      ),
      elevation: 5,
      child: RPadding(
        padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatDateDependingOnCurrentTime(comment.date),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(10).r,
              onTap: () async {
                HapticFeedback.lightImpact();
                await Modular.get<UserListController>()
                    .addGeneralAccountInfoIfNotExists(
                  generalAccountInfo: comment.authorInfo,
                );
                Modular.to.pushNamed(
                  ".${Routes.home.userPage}?accountId=${comment.authorInfo.accountId}",
                );
              },
              child: SizedBox(
                height: 36.h,
                child: Row(
                  children: [
                    Container(
                      width: 35.h,
                      height: 35.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10).r,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: NearNetworkImage(
                        imageUrl: comment.authorInfo.profileImageLink,
                        errorPlaceholder: Image.asset(
                          NearAssets.standartAvatar,
                          fit: BoxFit.cover,
                        ),
                        placeholder: Image.asset(
                          NearAssets.standartAvatar,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (post.authorInfo.name != "")
                            Text(
                              comment.authorInfo.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          Text(
                            "@${comment.authorInfo.accountId}",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            RawTextToContentFormatter(
              rawText: comment.commentBody.text.trim(),
              imageHeight: .5.sh,
            ),
            if (comment.commentBody.mediaLink != null) ...[
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    Modular.routerDelegate.navigatorKey.currentContext!,
                    MaterialPageRoute(
                      builder: (context) => ImageFullScreen(
                        imageUrl: comment.commentBody.mediaLink!,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: comment.commentBody.mediaLink!,
                  child: NearNetworkImage(
                    imageUrl: comment.commentBody.mediaLink!,
                  ),
                ),
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
                            postsOfAccountId: postsOfAccountId,
                            postsViewMode: postsViewMode,
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
                      postsViewMode: postsViewMode,
                      postsOfAccountId: postsOfAccountId,
                    );
                  },
                ),
                if (post.authorInfo.accountId != authController.state.accountId)
                  MoreActionsForCommentButton(comment: comment),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
