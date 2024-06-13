import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/comment_card.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/create_comment_dialog_body.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/shared_widgets/scale_animated_iconbutton.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';
import 'package:near_social_mobile/shared_widgets/two_states_iconbutton.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class PostPage extends StatelessWidget {
  const PostPage(
      {super.key, required this.accountId, required this.blockHeight});

  final String accountId;
  final int blockHeight;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    final PostsController postsController = Modular.get<PostsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      postsController.loadCommentsOfPost(
        accountId: accountId,
        blockHeight: blockHeight,
      );
    });

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder(
            stream: postsController.stream,
            builder: (context, snapshot) {
              final post = postsController.state.posts.firstWhere(
                (element) =>
                    element.blockHeight == blockHeight &&
                    element.authorInfo.accountId == accountId,
              );
              return ListView(
                padding: REdgeInsets.all(15),
                children: [
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
                          imageUrl: post.authorInfo.profileImageLink,
                          errorPlaceholder: Image.asset(
                            NearAssets.standartAvatar,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          "${post.authorInfo.name} @${post.authorInfo.accountId}",
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  // SelectableText(
                  //   post.postBody.text.trim(),
                  // ),
                  RawTextToContentFormatter(
                    rawText: post.postBody.text.trim(),
                  ),

                  if (post.postBody.mediaLink != null) ...[
                    NearNetworkImage(imageUrl: post.postBody.mediaLink!),
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
                                  descriptionTitle: Text.rich(
                                    style: TextStyle(fontSize: 14.sp),
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
                            );
                          } catch (err) {
                            final exc = AppExceptions(
                              messageForUser: "Failed to like post",
                              messageForDev: err.toString(),
                              statusCode: AppErrorCodes.flutterchainError,
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
                                title: const Text(
                                  "Repost",
                                ),
                                content: const Text(
                                  "Are you sure you want to repost this post?",
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text("Yes"),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Modular.to.pop(true);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text("No"),
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
                                );
                              } catch (err) {
                                final exc = AppExceptions(
                                  messageForUser: "Failed to like post",
                                  messageForDev: err.toString(),
                                  statusCode: AppErrorCodes.flutterchainError,
                                );
                                throw exc;
                              }
                            },
                          );
                        },
                      ),
                      TwoStatesIconButton(
                        iconPath: NearAssets.shareIcon,
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final nearSocialApi = Modular.get<NearSocialApi>();
                          final urlOfPost = nearSocialApi.getUrlOfPost(
                            accountId: post.authorInfo.accountId,
                            blockHeight: post.blockHeight,
                          );
                          Clipboard.setData(ClipboardData(text: urlOfPost));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Url of post coppied to clipboard"),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  if (post.commentList != null) ...[
                    ...post.commentList!
                        .map(
                          (comment) => CommentCard(
                            comment: comment,
                            post: post,
                          ),
                        )
                        .toList()
                  ] else ...[
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

class RawTextToContentFormatter extends StatelessWidget {
  const RawTextToContentFormatter({
    super.key,
    required this.rawText,
  });

  final String rawText;

  List<Widget> _generateWidgetsFromRawText(String text) {
    final List<Widget> widgets = [];
    final RegExp imageRegex = RegExp(r'!\[(.*?)\]\((.*?)\)');
    final RegExp linkRegex = RegExp(r'\[(.*?)\]\((.*?)\)');
    final List<RegExpMatch> imageMatches = imageRegex.allMatches(text).toList();
    final List<RegExpMatch> linkMatches = linkRegex.allMatches(text).toList();

    int lastMatchEnd = 0;
    int imageIndex = 0;
    int linkIndex = 0;

    while (imageIndex < imageMatches.length || linkIndex < linkMatches.length) {
      RegExpMatch? nextMatch;
      bool isImageMatch = false;

      if (imageIndex < imageMatches.length &&
          (linkIndex >= linkMatches.length ||
              imageMatches[imageIndex].start < linkMatches[linkIndex].start)) {
        nextMatch = imageMatches[imageIndex];
        isImageMatch = true;
        imageIndex++;
      } else if (linkIndex < linkMatches.length) {
        nextMatch = linkMatches[linkIndex];
        linkIndex++;
      }

      if (nextMatch != null && nextMatch.start > lastMatchEnd) {
        widgets.add(
          SelectableText(
            text.substring(lastMatchEnd, nextMatch.start).trim(),
          ),
        );
      }

      if (nextMatch != null) {
        if (isImageMatch) {
          final imageUrl = nextMatch.group(2);
          if (imageUrl != null && _isImageUrl(imageUrl)) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8).r,
                child: NearNetworkImage(
                  imageUrl: imageUrl,
                  errorPlaceholder: const Icon(Icons.broken_image),
                ),
              ),
            );
          } else if (imageUrl != null) {
            widgets.add(
              InkWell(
                onTap: () => _launchURL(imageUrl),
                child: Text(
                  nextMatch.group(1) ?? imageUrl,
                  style: const TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            );
          }
        } else {
          final linkDescription = nextMatch.group(1);
          final linkUrl = nextMatch.group(2);
          if (linkUrl != null) {
            widgets.add(
              InkWell(
                onTap: () {
                  _launchURL(linkUrl);
                },
                child: Text(
                  linkDescription ?? linkUrl,
                  style: const TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            );
          }
        }
        lastMatchEnd = nextMatch.end;
      }
    }

    if (lastMatchEnd < text.length) {
      widgets.add(
        SelectableText(
          text.substring(lastMatchEnd).trim(),
        ),
      );
    }

    return widgets;
  }

  bool _isImageUrl(String url) {
    final List<String> imageExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp'
    ];
    final uri = Uri.parse(url);
    final extension = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last.split('.').last
        : '';
    return imageExtensions.contains(extension.toLowerCase());
  }

  void _launchURL(String urlText) async {
    final Uri url = Uri.parse(urlText);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> contentWidgets = _generateWidgetsFromRawText(rawText);
    return Wrap(
      spacing: 4,
      children: contentWidgets,
    );
  }
}
