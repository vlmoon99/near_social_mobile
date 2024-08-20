// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/models/post.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

class CreatePostDialog extends StatefulWidget {
  const CreatePostDialog({
    super.key,
  });

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _textEditingController = TextEditingController();
  String? filepathOfMedia;

  Future<bool?> askIfToLeave() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Are you sure you want to exit?",
            textAlign: TextAlign.left, style: TextStyle(fontSize: 22)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        content: const Text("Your post will not be saved.",
            style: TextStyle(fontSize: 16)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          CustomButton(
            primary: true,
            onPressed: () {
              Modular.to.pop(true);
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
              Modular.to.pop(false);
            },
            child: const Text(
              "No",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        if (filepathOfMedia == null && _textEditingController.text.isEmpty) {
          Modular.to.pop();
        } else {
          askIfToLeave().then(
            (value) {
              if (value == true) {
                Modular.to.pop();
              }
            },
          );
        }
      },
      child: SizedBox(
        height: MediaQuery.of(context).size.height -
            (MediaQuery.of(context).padding.top + kToolbarHeight),
        child: RPadding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Create post",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10).r,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10).r,
                  ),
                  child: TextField(
                    controller: _textEditingController,
                    maxLines: null,
                    decoration: const InputDecoration.collapsed(
                      hintText: "Write your post here...",
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomButton(
                    primary: true,
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? file =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (file == null) {
                        return;
                      }
                      setState(() {
                        filepathOfMedia = file.path;
                      });
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.add),
                        SizedBox(width: 5.h),
                        const Text(
                          "Add media",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (filepathOfMedia != null)
                    SizedBox(
                      width: 60.h,
                      height: 60.h,
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 50.h,
                            width: 50.h,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(10).r,
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Image.file(
                              File(filepathOfMedia!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: SizedBox(
                              width: 30.h,
                              height: 30.h,
                              child: FittedBox(
                                child: IconButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      filepathOfMedia = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                  color: Colors.red,
                                  style: const ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                      Colors.white,
                                    ),
                                    shadowColor:
                                        WidgetStatePropertyAll(Colors.black),
                                    elevation: WidgetStatePropertyAll(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomButton(
                    primary: true,
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final nearSocialApi = Modular.get<NearSocialApi>();
                      final AuthController authController =
                          Modular.get<AuthController>();

                      final String accountId = authController.state.accountId;
                      final String publicKey = authController.state.publicKey;
                      final String privateKey = authController.state.privateKey;

                      String? cidOfMedia;
                      if (filepathOfMedia != null) {
                        cidOfMedia =
                            await nearSocialApi.uploadFileToNearFileHosting(
                          filepath: filepathOfMedia!,
                        );
                      }

                      final PostBody postBody = PostBody(
                        text: _textEditingController.text,
                        mediaLink: cidOfMedia,
                      );

                      if (postBody.text == "" && postBody.mediaLink == null) {
                        throw AppExceptions(
                          messageForUser: "Empty text and mediaLink",
                          messageForDev: "Empty text and mediaLink",
                        );
                      }
                      nearSocialApi
                          .createPost(
                        accountId: accountId,
                        publicKey: publicKey,
                        privateKey: privateKey,
                        postBody: PostBody(
                          text: _textEditingController.text,
                          mediaLink: cidOfMedia,
                        ),
                      )
                          .then((_) {
                        Future.delayed(const Duration(seconds: 10), () {
                          Modular.get<PostsController>()
                              .loadPosts(postsViewMode: PostsViewMode.main);
                        });
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Your post will be added soon."),
                        ),
                      );
                      Modular.to.pop();
                    },
                    child: const Text(
                      "Send",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  CustomButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (filepathOfMedia == null &&
                          _textEditingController.text.isEmpty) {
                        Modular.to.pop();
                      } else {
                        askIfToLeave().then(
                          (value) {
                            if (value == true) {
                              Modular.to.pop();
                            }
                          },
                        );
                      }
                    },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
