import 'dart:async';

import 'package:bos_gateway_viewer/bos_gateway_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/home/pages/near_widgets/widget_app_page.dart';
import 'package:near_social_mobile/modules/home/vms/near_widgets/near_widgets_controller.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';

class NearWidgetListPage extends StatefulWidget {
  const NearWidgetListPage({super.key});

  @override
  State<NearWidgetListPage> createState() => _NearWidgetListPageState();
}

class _NearWidgetListPageState extends State<NearWidgetListPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final NearWidgetsController nearWidgetsController =
        Modular.get<NearWidgetsController>();
    if (nearWidgetsController.state.status == NearWidgetStatus.initial) {
      runZonedGuarded(() {
        nearWidgetsController.getNearWidgets();
      }, (error, stack) {
        final AppExceptions appException = AppExceptions(
          messageForUser: "Error occurred. Please try later.",
          messageForDev: error.toString(),
          statusCode: AppErrorCodes.cryptoError,
        );
        Modular.get<Catcher>().exceptionsHandler.add(appException);
      });
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 20).r,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      SizedBox(
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
                    ],
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

class NearWidgetTile extends StatelessWidget {
  const NearWidgetTile({super.key, required this.nearWidget});

  final NearWidgetInfo nearWidget;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox.square(
        dimension: 50.w,
        child: NearNetworkImage(
          imageUrl: nearWidget.imageUrl,
          placeholder: Image.asset(NearAssets.widgetPlaceholder),
        ),
      ),
      title: Text(nearWidget.name != "" ? nearWidget.name : nearWidget.urlName),
      subtitle:
          nearWidget.description != "" ? Text(nearWidget.description) : null,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              child: WidgetsPropsSettingsDialogBody(
                  navigateFunction: (String widgetprops) async {
                final AuthController authController =
                    Modular.get<AuthController>();
                final NearWidgetSetupCredentials nearWidgetSetupCredentials =
                    NearWidgetSetupCredentials(
                  nearAuthCreds: NearAuthCreds(
                    network: NearNetwork.mainnet,
                    // await getNearNetworkType() == NearNetworkType.mainnet
                    //     ? NearNetwork.mainnet
                    //     : NearNetwork.testnet,
                    accountId: authController.state.accountId,
                    privateKey: authController.state.secretKey,
                  ),
                  widgetSettings: WidgetSettings(
                    widgetSrc: nearWidget.widgetPath,
                    widgetProps: widgetprops,
                  ),
                );

                Modular.to.pushNamed(
                  ".${Routes.home.widgetPage}",
                  arguments: nearWidgetSetupCredentials,
                );
              }),
            );
          },
        );
      },
    );
  }
}

class WidgetsPropsSettingsDialogBody extends StatefulWidget {
  const WidgetsPropsSettingsDialogBody({
    super.key,
    required this.navigateFunction,
  });

  final Function navigateFunction;

  @override
  State<WidgetsPropsSettingsDialogBody> createState() =>
      _WidgetsPropsSettingsDialogBodyState();
}

class _WidgetsPropsSettingsDialogBodyState
    extends State<WidgetsPropsSettingsDialogBody> {
  final TextEditingController _textEditingController = TextEditingController()
    ..text = "{}";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10).r,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Widgets props settings", style: TextStyle(fontSize: 20.sp)),
          Container(
            padding: const EdgeInsets.all(10).r,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(10).r,
            ),
            child: TextField(
              controller: _textEditingController,
              // maxLines: 10,
              decoration: const InputDecoration.collapsed(
                hintText: "Widget props in format like {\"key\": \"value\"}",
              ),
            ),
          ),
          SizedBox(height: 5.h),
          ElevatedButton(
            onPressed: () {
              widget.navigateFunction(_textEditingController.text);
              Modular.to.pop();
            },
            child: const Text("Open widget"),
          ),
        ],
      ),
    );
  }
}
