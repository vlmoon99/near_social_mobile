import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/comment_card.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/create_comment_dialog_body.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/more_actions_for_post_button.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/raw_text_to_content_formatter.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/filter_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/services/pausable_timer.dart';
import 'package:near_social_mobile/services/position_retained_scroll_physics.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/image_full_screen_page.dart';
import 'package:near_social_mobile/shared_widgets/scale_animated_iconbutton.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';
import 'package:near_social_mobile/shared_widgets/two_states_iconbutton.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';
import 'package:rxdart/rxdart.dart';

class PostPage extends StatefulWidget {
  const PostPage({
    super.key,
    required this.accountId,
    required this.blockHeight,
    required this.postsViewMode,
    String? postsOfAccountId,
    this.allowToNavigateToPostAuthorPage = true,
  }) : postsOfAccountId = postsOfAccountId == '' ? null : postsOfAccountId;

  final String accountId;
  final int blockHeight;
  final PostsViewMode postsViewMode;
  final String? postsOfAccountId;
  final bool allowToNavigateToPostAuthorPage;

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  late final PausableTimer updateCommentsTimer;

  @override
  void initState() {
    super.initState();
    final PostsController postsController = Modular.get<PostsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final posts = postsController.getPostsDueToPostsViewMode(
          widget.postsViewMode, widget.postsOfAccountId);
      if (posts.firstWhere((element) {
            return element.blockHeight == widget.blockHeight &&
                element.authorInfo.accountId == widget.accountId;
          }).commentList ==
          null) {
        postsController.loadCommentsOfPost(
          accountId: widget.accountId,
          blockHeight: widget.blockHeight,
          postsViewMode: widget.postsViewMode,
          postsOfAccountId: widget.postsOfAccountId,
        );
      } else {
        postsController.updateCommentsOfPost(
          accountId: widget.accountId,
          blockHeight: widget.blockHeight,
          postsViewMode: widget.postsViewMode,
          postsOfAccountId: widget.postsOfAccountId,
        );
      }
    });
    updateCommentsTimer = PausableTimer.periodic(
      const Duration(seconds: 40),
      () async {
        updateCommentsTimer.pause();
        postsController.updateCommentsOfPost(
          accountId: widget.accountId,
          blockHeight: widget.blockHeight,
          postsViewMode: widget.postsViewMode,
          postsOfAccountId: widget.postsOfAccountId,
        );
        updateCommentsTimer.start();
      },
    )..start();
  }

  @override
  void dispose() {
    updateCommentsTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    final PostsController postsController = Modular.get<PostsController>();
    final FilterController filterController = Modular.get<FilterController>();
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder(
            stream: Rx.merge([postsController.stream, filterController.stream]),
            builder: (context, snapshot) {
              final posts = postsController.getPostsDueToPostsViewMode(
                  widget.postsViewMode, widget.postsOfAccountId);
              final post = posts.firstWhere((element) =>
                  element.blockHeight == widget.blockHeight &&
                  element.authorInfo.accountId == widget.accountId);
              return ListView(
                padding: REdgeInsets.all(15),
                physics: const PositionRetainedScrollPhysics(),
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10).r,
                    onTap: widget.allowToNavigateToPostAuthorPage
                        ? () async {
                            HapticFeedback.lightImpact();
                            await Modular.get<UserListController>()
                                .addGeneralAccountInfoIfNotExists(
                              generalAccountInfo: post.authorInfo,
                            );
                            Modular.to.pushNamed(
                              ".${Routes.home.userPage}?accountId=${post.authorInfo.accountId}",
                            );
                          }
                        : null,
                    child: SizedBox(
                      height: 37.h,
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
                              imageUrl: post.authorInfo.profileImageLink,
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
                          SizedBox(width: 10.h),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (post.authorInfo.name != "")
                                  Text(
                                    post.authorInfo.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                Text(
                                  "@${post.authorInfo.accountId}",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: post.authorInfo.name != ""
                                      ? const TextStyle(
                                          color: NEARColors.grey,
                                          fontSize: 13,
                                        )
                                      : const TextStyle(
                                          fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 5.h),
                  RawTextToContentFormatter(
                    rawText: post.postBody.text.trim(),
                    imageHeight: .5.sh,
                  ),
                  SizedBox(height: 10.h),
                  if (post.postBody.mediaLink != null) ...[
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          Modular.routerDelegate.navigatorKey.currentContext!,
                          MaterialPageRoute(
                            builder: (context) => ImageFullScreen(
                              imageUrl: post.postBody.mediaLink!,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: post.postBody.mediaLink!,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: .5.sh),
                          child: NearNetworkImage(
                            imageUrl: post.postBody.mediaLink!,
                            boxFit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TwoStatesIconButton(
                        iconPath: NearAssets.commentIcon,
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                child: CreateCommentDialog(
                                  postsViewMode: widget.postsViewMode,
                                  postsOfAccountId: widget.postsOfAccountId,
                                  descriptionTitle: Text.rich(
                                    style: const TextStyle(fontSize: 14),
                                    TextSpan(
                                      children: [
                                        const TextSpan(text: "Answer to "),
                                        TextSpan(
                                          text: "@${post.authorInfo.accountId}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  post: post,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      ScaleAnimatedIconButtonWithCounter(
                        iconPath: NearAssets.likeIcon,
                        iconActivatedPath: NearAssets.activatedLikeIcon,
                        count: post.likeList.length,
                        activated: post.likeList.any(
                          (element) =>
                              element.accountId ==
                              authController.state.accountId,
                        ),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final String accountId =
                              authController.state.accountId;
                          final String publicKey =
                              authController.state.publicKey;
                          final String privateKey =
                              authController.state.privateKey;
                          try {
                            await postsController.likePost(
                              post: post,
                              accountId: accountId,
                              publicKey: publicKey,
                              privateKey: privateKey,
                              postsViewMode: widget.postsViewMode,
                              postsOfAccountId: widget.postsOfAccountId,
                            );
                          } catch (err) {
                            final exc = AppExceptions(
                              messageForUser: "Failed to like post",
                              messageForDev: err.toString(),
                            );
                            throw exc;
                          }
                        },
                      ),
                      ScaleAnimatedIconButtonWithCounter(
                        iconPath: NearAssets.repostIcon,
                        count: post.repostList.length,
                        activated: post.repostList.any(
                          (element) =>
                              element.accountId ==
                              authController.state.accountId,
                        ),
                        activatedColor: Colors.green,
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final String accountId =
                              authController.state.accountId;
                          final String publicKey =
                              authController.state.publicKey;
                          final String privateKey =
                              authController.state.privateKey;
                          if (post.repostList.any(
                              (element) => element.accountId == accountId)) {
                            return;
                          }
                          await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Repost"),
                                content: const Text(
                                  "Are you sure you want to repost this post?",
                                ),
                                actionsAlignment: MainAxisAlignment.spaceEvenly,
                                actions: [
                                  CustomButton(
                                    primary: true,
                                    child: const Text(
                                      "Yes",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Modular.to.pop(true);
                                    },
                                  ),
                                  CustomButton(
                                    child: const Text(
                                      "No",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Modular.to.pop(false);
                                    },
                                  ),
                                ],
                              );
                            },
                          ).then(
                            (answer) async {
                              if (answer == null || !answer) {
                                return;
                              }
                              try {
                                await postsController.repostPost(
                                  post: post,
                                  accountId: accountId,
                                  publicKey: publicKey,
                                  privateKey: privateKey,
                                  postsViewMode: widget.postsViewMode,
                                  postsOfAccountId: widget.postsOfAccountId,
                                );
                              } catch (err) {
                                final exc = AppExceptions(
                                  messageForUser: "Failed to like post",
                                  messageForDev: err.toString(),
                                );
                                throw exc;
                              }
                            },
                          );
                        },
                      ),
                      MoreActionsForPostButton(
                        post: post,
                        postsViewMode: widget.postsViewMode,
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  if (post.commentList != null)
                    Builder(
                      builder: (context) {
                        final FiltersUtil filterUtil = FiltersUtil(
                          filters: filterController.state,
                        );
                        final comments = post.commentList!
                            .where((comment) => !filterUtil.commentIsHided(
                                comment.authorInfo.accountId,
                                comment.blockHeight))
                            .toList();
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: comments
                              .map(
                                (comment) => CommentCard(
                                  comment: comment,
                                  post: post,
                                  postsViewMode: widget.postsViewMode,
                                  postsOfAccountId: widget.postsOfAccountId,
                                ),
                              )
                              .toList(),
                        );
                      },
                    )
                  else ...[
                    const Center(
                      child: SpinnerLoadingIndicator(),
                    )
                  ],
                ],
              );
            }),
      ),
    );
  }
}
