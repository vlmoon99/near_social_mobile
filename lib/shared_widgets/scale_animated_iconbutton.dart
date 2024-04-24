import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ScaleAnimatedIconButton extends StatefulWidget {
  const ScaleAnimatedIconButton({
    super.key,
    required this.iconPath,
    this.iconActivatedPath,
    required this.onPressed,
    this.activated = false,
    this.size = 20,
    this.activatedColor = Colors.red,
  });

  final String iconPath;
  final String? iconActivatedPath;
  final Future<dynamic> Function() onPressed;
  final bool activated;
  final Color activatedColor;
  final int size;

  @override
  State<ScaleAnimatedIconButton> createState() =>
      _ScaleAnimatedIconButtonState();
}

class _ScaleAnimatedIconButtonState extends State<ScaleAnimatedIconButton>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 0.7), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 1), weight: 1),
    ]).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.stop();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
          return IconButton(
            onPressed: () async {
              _animationController.repeat();
              try {
                await widget.onPressed();
              } catch (err) {
                rethrow;
              } finally {
                _animationController.reset();
              }
            },
            icon: _animationController.isAnimating
                ? Transform.scale(
                    scale: _animation.value,
                    child: SvgPicture.asset(
                      widget.iconPath,
                      color: widget.activatedColor,
                      width: widget.size.w,
                      height: widget.size.w,
                    ),
                  )
                : (widget.iconActivatedPath != null && widget.activated
                    ? SvgPicture.asset(
                        widget.iconActivatedPath!,
                        width: widget.size.w,
                        height: widget.size.w,
                        color: widget.activatedColor,
                      )
                    : SvgPicture.asset(
                        widget.iconPath,
                        color: widget.activated
                            ? widget.activatedColor
                            : Colors.grey,
                        width: widget.size.w,
                        height: widget.size.w,
                      )),
            // icon: Transform.scale(
            //   scale: _animation.value,
            //   child: SvgPicture.asset(
            //     widget.iconPath,
            //     color: widget.activated ? widget.activatedColor : Colors.grey,
            //     width: widget.size.w,
            //     height: widget.size.w,
            //   ),
            // ),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        });
  }

  @override
  bool get wantKeepAlive => true;
}

class ScaleAnimatedIconButtonWithCounter extends StatelessWidget {
  const ScaleAnimatedIconButtonWithCounter({
    super.key,
    required this.iconPath,
    this.iconActivatedPath,
    required this.onPressed,
    this.activated = false,
    this.size = 20,
    this.activatedColor = Colors.red,
    required this.count,
  });
  final String iconPath;
  final String? iconActivatedPath;
  final Future<dynamic> Function() onPressed;
  final bool activated;
  final Color activatedColor;
  final int size;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ScaleAnimatedIconButton(
        iconPath: iconPath,
        iconActivatedPath: iconActivatedPath,
        onPressed: onPressed,
        activated: activated,
        activatedColor: activatedColor,
        size: size,
      ),
      Text(
        "$count",
        style: TextStyle(
          color: Colors.grey.shade600,
        ),
      ),
    ]);
  }
}
