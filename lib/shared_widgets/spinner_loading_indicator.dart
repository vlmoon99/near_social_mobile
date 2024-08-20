import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SpinnerLoadingIndicator extends StatefulWidget {
  const SpinnerLoadingIndicator({
    super.key,
    this.size = 50,
    this.duration = const Duration(seconds: 1),
    this.color = Colors.black,
  });

  final double size;
  final Duration duration;
  final Color color;

  @override
  State<SpinnerLoadingIndicator> createState() =>
      _SpinnerLoadingIndicatorState();
}

class _SpinnerLoadingIndicatorState extends State<SpinnerLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: _controller,
        child: SvgPicture.asset(
          "assets/media/icons/loading_indicator.svg",
          height: widget.size,
          width: widget.size,
          color: widget.color,
        ),
      ),
    );
  }
}
