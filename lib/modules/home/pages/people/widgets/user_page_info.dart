import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/home/pages/chat/chat_page.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/donation_dialog.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/more_actions_for_user_button.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/widgets/raw_text_to_content_formatter.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/filter_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/custom_refresh_indicator.dart';
import 'package:near_social_mobile/shared_widgets/expandable_wiget.dart';
import 'package:near_social_mobile/shared_widgets/image_full_screen_page.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class UserPageMainInfo extends StatelessWidget {
  const UserPageMainInfo(
      {super.key, required this.accountIdOfUser, required this.userIsBlocked,});

  final String accountIdOfUser;
  final bool userIsBlocked;

  List<Widget> linkTreeList({required Map<String, dynamic> linkTree}) {
    final List<Widget> linkTreeList = linkTree.entries.map((pair) {
      if (pair.key == "twitter") {
        return TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            final url = Uri.parse("https://twitter.com/${pair.value}");
            launchUrl(url);
          },
          icon: SvgPicture.asset(
            "assets/media/icons/twitter_icon.svg",
            height: 28,
          ),
          label: Text(pair.key),
        );
      } else if (pair.key == "github") {
        return TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            final url = Uri.parse("https://github.com/${pair.value}");
            launchUrl(url);
          },
          icon: SvgPicture.asset(
            "assets/media/icons/github_icon.svg",
            height: 28,
          ),
          label: Text(pair.key),
        );
      } else if (pair.key == "telegram") {
        return TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            final url = Uri.parse("https://t.me/${pair.value}");
            launchUrl(url);
          },
          icon: SvgPicture.asset(
            "assets/media/icons/telegram_icon.svg",
            height: 28,
          ),
          label: Text(pair.key),
        );
      } else if (pair.key == "website") {
        return TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            final url = Uri.parse("https://${pair.value}");
            launchUrl(url);
          },
          icon: SvgPicture.asset(
            "assets/media/icons/website_icon.svg",
            height: 28,
          ),
          label: Text(pair.key),
        );
      }
      return const SizedBox();
    }).toList();
    return linkTreeList;
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    final UserListController userListController =
        Modular.get<UserListController>();
    final FilterController filterController = Modular.get<FilterController>();
    return StreamBuilder(
        stream: userListController.stream.distinct(
          (previous, next) =>
              previous.getUserByAccountId(accountId: accountIdOfUser) ==
              next.getUserByAccountId(accountId: accountIdOfUser),
        ),
        builder: (context, snapshot) {
          final user = userListController.state
              .getUserByAccountId(accountId: accountIdOfUser);
          return Column(
            children: [
              CustomRefreshIndicator(
                onRefresh: () async {
                  await userListController.reloadUserInfo(
                      accountId: accountIdOfUser);
                  log("User info reloaded");
                  await Modular.get<PostsController>().updatePostsOfAccount(
                    postsOfAccountId: accountIdOfUser,
                    filters: filterController.state,
                  );
                  log("Posts of account reloaded");
                  if (user.nfts != null) {
                    await userListController.loadNftsOfAccount(
                      accountId: accountIdOfUser,
                    );
                    log("NFTs of account reloaded");
                  }
                  if (user.widgetList != null) {
                    await userListController.loadWidgetsOfAccount(
                      accountId: accountIdOfUser,
                    );
                    log("Widgets of account reloaded");
                  }
                },
                child: SizedBox(
                  height: .30.sh,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (user
                              .generalAccountInfo.backgroundImageLink.isEmpty) {
                            return;
                          }
                          Navigator.push(
                            Modular.routerDelegate.navigatorKey.currentContext!,
                            MaterialPageRoute(
                              builder: (context) => ImageFullScreen(
                                imageUrl:
                                    user.generalAccountInfo.backgroundImageLink,
                              ),
                            ),
                          );
                        },
                        child: SizedBox(
                          height: .25.sh,
                          width: double.infinity,
                          child: NearNetworkImage(
                            imageUrl:
                                user.generalAccountInfo.backgroundImageLink,
                            errorPlaceholder:
                                Container(color: AppColors.lightSurface),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 20.h,
                        width: .2.sh,
                        height: .2.sh,
                        child: GestureDetector(
                          onTap: () {
                            if (user
                                .generalAccountInfo.profileImageLink.isEmpty) {
                              return;
                            }
                            Navigator.push(
                              Modular
                                  .routerDelegate.navigatorKey.currentContext!,
                              MaterialPageRoute(
                                builder: (context) => ImageFullScreen(
                                  imageUrl:
                                      user.generalAccountInfo.profileImageLink,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: REdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: NearNetworkImage(
                                imageUrl:
                                    user.generalAccountInfo.profileImageLink,
                                errorPlaceholder: Image.asset(
                                  NearAssets.standartAvatar,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (accountIdOfUser != authController.state.accountId &&
                          !userIsBlocked)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10)
                                .r,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: NEARColors.black,
                                foregroundColor: NEARColors.white,
                                disabledForegroundColor: NEARColors.white,
                                disabledBackgroundColor: NEARColors.black,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8).r,
                                  side: const BorderSide(
                                    color: NEARColors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return DonationDialog(
                                      receiverId: accountIdOfUser,
                                    );
                                  },
                                );
                              },
                              child: const Text(
                                "Donate",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: REdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            user.generalAccountInfo.name != ""
                                ? user.generalAccountInfo.name
                                : "No Name",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (user.generalAccountInfo.accountId !=
                            authController.state.accountId)
                          MoreActionsForUserButton(
                            userAccountId: user.generalAccountInfo.accountId,
                          ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.person_fill,
                          size: 16.h,
                        ),
                        SizedBox(width: 5.h),
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Clipboard.setData(
                                ClipboardData(
                                  text: user.generalAccountInfo.accountId,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "AccountId ${user.generalAccountInfo.accountId} copied to clipboard"),
                                ),
                              );
                            },
                            child: Text(
                              "@${user.generalAccountInfo.accountId}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.h),
                        if (user.followings != null &&
                            user.followings!.any(
                              (element) =>
                                  element.accountId ==
                                  authController.state.accountId,
                            ))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ).r,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5).r,
                              color: NEARColors.slate,
                            ),
                            child: const Text(
                              "Follows you",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                color: NEARColors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    if (authController.state.accountId != accountIdOfUser &&
                        !userIsBlocked) ...[
                      Row(
                        children: [
                          if (user.followers != null)
                            RPadding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Builder(
                                builder: (_) {
                                  final inFollowerList = user.followers!.any(
                                    (follower) =>
                                        follower.accountId ==
                                        authController.state.accountId,
                                  );
                                  return CustomButton(
                                    primary: !inFollowerList,
                                    onPressed: () {
                                      if (inFollowerList) {
                                        requestToUnfollowAccount(context);
                                      } else {
                                        requestToFollowAccount(context);
                                      }
                                    },
                                    child: Text(
                                      inFollowerList ? "Following" : "Follow",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          CustomButton(
                            primary: true,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Poking user...")));
                              Modular.get<NearSocialApi>()
                                  .pokeAccount(
                                accountIdToPoke: accountIdOfUser,
                                accountId: authController.state.accountId,
                                publicKey: authController.state.publicKey,
                                privateKey: authController.state.privateKey,
                              )
                                  .then((_) {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Poked @$accountIdOfUser!"),
                                  ),
                                );
                              });
                            },
                            child: const Text(
                              "👈 Poke",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          RPadding(
                            padding: const EdgeInsets.only(left: 10),
                            child: CustomButton(
                              primary: true,
                              onPressed: () async {
                                try {
                                  final userDoc = await FirebaseFirestore
                                      .instance
                                      .collection('users')
                                      .doc(accountIdOfUser)
                                      .get();

                                  if (userDoc.exists) {
                                    final userData = {
                                      "id": userDoc.id,
                                      "imageUrl": userDoc.data()!['imageUrl'],
                                      "firstName": userDoc.data()!['firstName'],
                                      "lastName": userDoc.data()!['lastName'],
                                      "role": userDoc.data()!['role'],
                                      "metadata": userDoc.data()!['metadata'],
                                    };

                                    final otherUser =
                                        types.User.fromJson(userData);

                                    final room =
                                        await Modular.get<NearSocialApi>()
                                            .createRoom(
                                                Modular.get<AuthController>()
                                                    .state
                                                    .accountId,
                                                otherUser);

                                  final currentUserDocReq = await FirebaseFirestore
                                      .instance
                                      .collection('users')
                                      .doc(accountIdOfUser)
                                      .get();

                                    final currentUserDoc = {
                                      "id": currentUserDocReq.id,
                                      "imageUrl": currentUserDocReq.data()!['imageUrl'],
                                      "firstName": currentUserDocReq.data()!['firstName'],
                                      "lastName": currentUserDocReq.data()!['lastName'],
                                      "role": currentUserDocReq.data()!['role'],
                                      "metadata": currentUserDocReq.data()!['metadata'],
                                    };

                                    final currentUser =
                                        types.User.fromJson(currentUserDoc);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (ctx) => ChatPage(
                                          room: room,
                                          currentUser: currentUser,
                                        ),
                                      ),
                                    );

                                    print(
                                        'Chat room created successfully with user: $room');
                                  } else {
                                    print('No user found with the given ID');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "AccountId ${user.generalAccountInfo.accountId} not found isnide chat system , he must to use Near Social Mobile gateway for chating"),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('Error creating room: $e');
                                }
                              },
                              child: const Text(
                                "Chat",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.h),
                    ],
                    Row(
                      children: [
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: user.followings != null
                                    ? user.followings?.length.toString()
                                    : "?",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              const TextSpan(text: " Following"),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.h),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: user.followers != null
                                    ? user.followers?.length.toString()
                                    : "?",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              const TextSpan(text: " Followers"),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (user.generalAccountInfo.linktree.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...linkTreeList(
                              linkTree: user.generalAccountInfo.linktree),
                          SizedBox(height: 10.h),
                        ],
                      ),
                    if (user.generalAccountInfo.tags.isNotEmpty) ...[
                      SizedBox(height: 5.h),
                      Wrap(
                        spacing: 5.h,
                        runSpacing: 5.h,
                        children: [
                          ...user.generalAccountInfo.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: AppColors.lightSurface.withOpacity(.5),
                              ),
                              child: Text(
                                "#$tag",
                                style: const TextStyle(
                                  color: AppColors.onlightSurface,
                                ),
                              ),
                            );
                          })
                        ],
                      )
                    ],
                    if (user.userTags != null && user.userTags!.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 5.h,
                        runSpacing: 5.h,
                        children: [
                          ...user.userTags!.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              child: Text(
                                "#$tag",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            );
                          })
                        ],
                      ),
                    ],
                    if (user.generalAccountInfo.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10).r,
                        child: CollapseWidget(
                          children: RawTextToContentFormatter(
                            rawText: user.generalAccountInfo.description,
                            imageHeight: 0.2.sh,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        });
  }

  Future<dynamic> requestToUnfollowAccount(
    BuildContext context,
  ) {
    final UserListController userListController =
        Modular.get<UserListController>();
    final AuthController authController = Modular.get<AuthController>();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text("Are you sure you want to unfollow $accountIdOfUser?",
              style: const TextStyle(fontSize: 16)),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            CustomButton(
              primary: true,
              onPressed: () async {
                userListController.unfollowAccount(
                  accountIdToUnfollow: accountIdOfUser,
                  accountId: authController.state.accountId,
                  publicKey: authController.state.publicKey,
                  privateKey: authController.state.privateKey,
                );
                Modular.to.pop();
              },
              child: const Text(
                "Yes",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CustomButton(
              onPressed: () {
                Modular.to.pop();
              },
              child: const Text(
                "No",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<dynamic> requestToFollowAccount(
    BuildContext context,
  ) {
    final UserListController userListController =
        Modular.get<UserListController>();
    final AuthController authController = Modular.get<AuthController>();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text("Are you sure you want to follow $accountIdOfUser?",
              style: const TextStyle(fontSize: 16)),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            CustomButton(
              primary: true,
              onPressed: () async {
                userListController.followAccount(
                  accountIdToFollow: accountIdOfUser,
                  accountId: authController.state.accountId,
                  publicKey: authController.state.publicKey,
                  privateKey: authController.state.privateKey,
                );
                Modular.to.pop();
              },
              child: const Text(
                "Yes",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CustomButton(
              onPressed: () {
                Modular.to.pop();
              },
              child: const Text(
                "No",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
