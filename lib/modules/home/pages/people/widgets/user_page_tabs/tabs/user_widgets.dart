import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/apis/models/near_widget_info.dart';
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
  List<NearWidgetInfo>? widgets;

  @override
  void initState() {
    super.initState();
    Modular.get<UserListController>().stream.listen((userList) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) {
          final user = userList.users.firstWhere((user) =>
              user.generalAccountInfo.accountId == widget.accountIdOfUser);
          if (user.widgetList == null && widgets != null) {
            Modular.get<UserListController>()
                .loadWidgetsOfAccount(accountIdOfUser: widget.accountIdOfUser);
          }
          setState(() {
            widgets = user.widgetList;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widgets == null) {
      return const Center(child: SpinnerLoadingIndicator());
    } else if (widgets!.isEmpty) {
      return const Center(child: Text('No Widgets yet'));
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20).r,
        itemBuilder: (context, index) {
          return NearWidgetTile(nearWidget: widgets![index]);
        },
        itemCount: widgets!.length,
      );
    }
  }
}
