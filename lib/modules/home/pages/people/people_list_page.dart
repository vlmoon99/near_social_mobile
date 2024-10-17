import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/pages/people/widgets/user_tile.dart';
import 'package:near_social_mobile/modules/home/vms/users/models/user_list_state.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/shared_widgets/search_textfield.dart';
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
                ? userListController.state.cachedUsers.entries
                    .where(
                      (entry) {
                        return entry.key.contains(
                              RegExp(searchController.text,
                                  caseSensitive: false),
                            ) ||
                            entry.key.contains(
                              RegExp(searchController.text,
                                  caseSensitive: false),
                            );
                      },
                    )
                    .map((e) => e.value)
                    .toList()
                : userListController.state.cachedUsers.values.toList();
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15).r,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15).r,
                    child: SizedBox(
                      height: 40.h,
                      child: CustomSearchBar(
                        searchController: searchController,
                      ),
                    ),
                  );
                }
                return UserTile(user: users[index - 1]);
              },
              itemCount: users.length + 1,
            );
          }),
    );
  }
}
