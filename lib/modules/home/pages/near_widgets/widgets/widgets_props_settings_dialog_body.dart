import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';

class WidgetsPropsSettingsDialogBody extends StatefulWidget {
  const WidgetsPropsSettingsDialogBody({
    super.key,
    required this.navigateFunction,
    this.initWidgetProps,
  });

  final String? initWidgetProps;
  final Function(String widgetprops, PrivateKeyInfo privateKeyInfo)
      navigateFunction;

  @override
  State<WidgetsPropsSettingsDialogBody> createState() =>
      _WidgetsPropsSettingsDialogBodyState();
}

class _WidgetsPropsSettingsDialogBodyState
    extends State<WidgetsPropsSettingsDialogBody> {
  late final TextEditingController _textEditingController =
      TextEditingController()..text = widget.initWidgetProps ?? "{}";

  late PrivateKeyInfo selectedKey;

  @override
  void initState() {
    super.initState();
    final AuthController authController = Modular.get<AuthController>();
    selectedKey = authController.state.additionalStoredKeys.entries
        .firstWhere((element) =>
            element.value.privateKey == authController.state.secretKey)
        .value;
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
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
              decoration: const InputDecoration.collapsed(
                hintText: "props",
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: DropdownButton<PrivateKeyInfo>(
              value: selectedKey,
              onChanged: (newKey) {
                if (newKey == null) return;
                setState(() {
                  selectedKey = newKey;
                });
              },
              items: authController.state.additionalStoredKeys.entries
                  .map((keyInfo) {
                return DropdownMenuItem<PrivateKeyInfo>(
                  alignment: Alignment.center,
                  value: keyInfo.value,
                  child: Text(
                    keyInfo.key,
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 5.h),
          ElevatedButton(
            onPressed: () {
              widget.navigateFunction(
                """'${_textEditingController.text}'""",
                selectedKey,
              );
              Modular.to.pop();
            },
            child: const Text("Open widget"),
          ),
        ],
      ),
    );
  }
}
