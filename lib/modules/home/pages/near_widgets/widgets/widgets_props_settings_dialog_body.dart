import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
              widget.navigateFunction("""'${_textEditingController.text}'""");
              Modular.to.pop();
            },
            child: const Text("Open widget"),
          ),
        ],
      ),
    );
  }
}
