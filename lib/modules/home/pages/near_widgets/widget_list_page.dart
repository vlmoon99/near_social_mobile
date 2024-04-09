import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/models/near_widget_info.dart';
import 'package:near_social_mobile/modules/home/pages/near_widgets/widgets/near_widget_tile.dart';
import 'package:near_social_mobile/modules/home/vms/near_widgets/near_widgets_controller.dart';

class NearWidgetListPage extends StatefulWidget {
  const NearWidgetListPage({super.key});

  @override
  State<NearWidgetListPage> createState() => _NearWidgetListPageState();
}

class _NearWidgetListPageState extends State<NearWidgetListPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final NearWidgetsController nearWidgetsController =
          Modular.get<NearWidgetsController>();
      if (nearWidgetsController.state.status == NearWidgetStatus.initial) {
        runZonedGuarded(() {
          nearWidgetsController.getNearWidgets();
        }, (error, stack) {
          final AppExceptions appException = AppExceptions(
            messageForUser: "Error occurred. Please try later.",
            messageForDev: error.toString(),
            statusCode: AppErrorCodes.nearSocialApiError,
          );
          Modular.get<Catcher>().exceptionsHandler.add(appException);
        });
      }
    });
  }

  final TextEditingController searchController = TextEditingController();

  @override
  initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nearWidgetsController = Modular.get<NearWidgetsController>();
    return Scaffold(
      body: StreamBuilder<NearWidgets>(
          stream: nearWidgetsController.stream,
          builder: (context, _) {
            if (nearWidgetsController.state.status != NearWidgetStatus.loaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<NearWidgetInfo> nearWidgets = searchController.text != ""
                ? nearWidgetsController.state.widgetList
                    .where(
                      (element) =>
                          element.name.contains(
                            RegExp(searchController.text, caseSensitive: false),
                          ) ||
                          element.urlName.contains(
                            RegExp(searchController.text, caseSensitive: false),
                          ),
                    )
                    .toList()
                : nearWidgetsController.state.widgetList;

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
                final nearWidget = nearWidgets[index - 1];
                return NearWidgetTile(nearWidget: nearWidget);
              },
              itemCount: nearWidgets.length + 1,
            );
          }),
    );
  }
}

