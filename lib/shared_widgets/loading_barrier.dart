import 'package:flutter/material.dart';
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SpinnerLoadingIndicator(
                color: Colors.white,
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
