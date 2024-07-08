import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/theme.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    this.primary = false,
    super.key,
    required this.onPressed,
    // required this.label,
    required this.child,
    // this.labelColor,
  });

  final bool primary;
  final Function()? onPressed;
  // final String label;
  final Widget child;
  // final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed!();
      },
      style: FilledButton.styleFrom(
        backgroundColor: primary ? NEARColors.black : NEARColors.white,
        foregroundColor: primary ? NEARColors.white : NEARColors.black,
        disabledForegroundColor: primary ? NEARColors.white : NEARColors.black,
        disabledBackgroundColor: primary ? NEARColors.black : NEARColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8).r,
          side: const BorderSide(
            color: NEARColors.black,
            width: 2,
          ),
        ),
      ),
      child: child,
    );
  }
}
