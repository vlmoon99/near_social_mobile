import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/pages/near_widgets/widgets/near_widget_tile.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class WidgetsView extends StatefulWidget {
  const WidgetsView({super.key, required this.accountIdOfUser});
  final String accountIdOfUser;
  @override
  State<WidgetsView> createState() => _WidgetsViewState();
}

class _WidgetsViewState extends State<WidgetsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        final userListController = Modular.get<UserListController>();
        final user = userListController.state
            .getUserByAccountId(accountId: widget.accountIdOfUser);
        if (user.widgetList == null) {
          Modular.get<UserListController>()
              .loadWidgetsOfAccount(accountId: widget.accountIdOfUser);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserListController userListController =
        Modular.get<UserListController>();
    return StreamBuilder(
      stream: userListController.stream,
      builder: (context, snapshot) {
        final widgets =
            userListController.state.users[widget.accountIdOfUser]!.widgetList;
        if (widgets == null) {
          return const Center(child: SpinnerLoadingIndicator());
        } else if (widgets.isEmpty) {
          return const Center(child: Text('No Widgets yet'));
        } else {
          return ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 20).r,
            itemBuilder: (context, index) {
              return NearWidgetTile(nearWidget: widgets[index]);
            },
            itemCount: widgets.length,
          );
        }
      },
    );
  }
}
