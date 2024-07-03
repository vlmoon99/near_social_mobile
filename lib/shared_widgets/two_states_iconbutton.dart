import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TwoStatesIconButton extends StatelessWidget {
  const TwoStatesIconButton({
    super.key,
    required this.iconPath,
    this.iconActivatedPath,
    required this.onPressed,
    this.activated = false,
    this.size = 16,
    this.activatedColor = Colors.red,
  });

  final String iconPath;
  final String? iconActivatedPath;
  final Function() onPressed;
  final bool activated;
  final Color activatedColor;
  final int size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: iconActivatedPath != null && activated
              ? SvgPicture.asset(
                  iconActivatedPath!,
                  width: size.h,
                  height: size.h,
                  color: activatedColor,
                )
              : SvgPicture.asset(
                  iconPath,
                  color: activated ? activatedColor : Colors.grey,
                  width: size.h,
                  height: size.h,
                ),
          style: const ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
