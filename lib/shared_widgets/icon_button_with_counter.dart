import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IconButtonWithCounter extends StatelessWidget {
  const IconButtonWithCounter({
    super.key,
    this.icon,
    this.iconPath,
    required this.onPressed,
    this.count = 0,
    this.activated = false,
    this.size = 20,
    this.activatedColor = Colors.red,
  }) : assert(icon != null || iconPath != null);

  final IconData? icon;
  final String? iconPath;
  final Function() onPressed;
  final int count;
  final bool activated;
  final Color activatedColor;
  final int size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: icon != null
              ? Icon(
                  icon,
                  size: size.w,
                  color: Colors.grey,
                )
              : SvgPicture.asset(
                  iconPath!,
                  color: Colors.grey,
                  width: size.w,
                  height: size.w,
                ),
          style: const ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        if (count > 0)
          Text(
            "$count",
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
      ],
    );
  }
}
