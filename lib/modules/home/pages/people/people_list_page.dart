// ignore_for_file: unused_import

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class PeopleListPage extends StatefulWidget {
  const PeopleListPage({super.key});

  @override
  State<PeopleListPage> createState() => _PeopleListPageState();
}

class _PeopleListPageState extends State<PeopleListPage> {
  final TextEditingController searchController = TextEditingController();

  @override
  initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final UserListController userListController =
          Modular.get<UserListController>();
      if (userListController.state.loadingState == UserListState.initial) {
        userListController.loadUsers();
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserListController userListController =
        Modular.get<UserListController>();
    return Scaffold(
      body: StreamBuilder<UsersList>(
          stream: userListController.stream,
          builder: (context, snapshot) {
            if (userListController.state.loadingState != UserListState.loaded) {
              return const Center(child: SpinnerLoadingIndicator());
            }
            final users = searchController.text != ""
                ? userListController.state.users
                    .where(
                      (user) =>
                          user.generalAccountInfo.name.contains(
                            RegExp(searchController.text, caseSensitive: false),
                          ) ||
                          user.generalAccountInfo.accountId.contains(
                            RegExp(searchController.text, caseSensitive: false),
                          ),
                    )
                    .toList()
                : userListController.state.users;
            return ListView.builder(
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20).r,
                    child: SizedBox(
                      height: 60.w,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: const InputDecoration.collapsed(
                                hintText: "Search",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final user = users[index - 1];
                return ListTile(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Modular.to.pushNamed(
                      ".${Routes.home.userPage}?accountId=${user.generalAccountInfo.accountId}",
                    );
                  },
                  leading: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: NearNetworkImage(
                      imageUrl: user.generalAccountInfo.profileImageLink,
                      placeholder: Image.asset(
                        NearAssets.standartAvatar,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: user.generalAccountInfo.name != ""
                      ? Text(user.generalAccountInfo.name)
                      : null,
                  subtitle: Text("@${user.generalAccountInfo.accountId}"),
                );
              },
              itemCount: users.length + 1,
            );
          }),
    );
  }
}
