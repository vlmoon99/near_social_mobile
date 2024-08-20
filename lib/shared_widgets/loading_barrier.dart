import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class LoadingBarrier extends StatelessWidget {
  const LoadingBarrier({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const ModalBarrier(
            color: Colors.black87,
            dismissible: false,
          ),
          FittedBox(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 40).r,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10).r,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SpinnerLoadingIndicator(),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(message!),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
