import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomRefreshIndicator extends StatefulWidget {
  const CustomRefreshIndicator(
      {super.key, required this.onRefresh, required this.child});
  final Future<void> Function() onRefresh;
  final Widget child;
  @override
  State<CustomRefreshIndicator> createState() => _CustomRefreshIndicatorState();
}

class _CustomRefreshIndicatorState extends State<CustomRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0.0;
  late final double _triggerRefreshDistance = (1.sh / 8);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating) {
      return;
    }
    setState(() {
      if (_dragOffset > _triggerRefreshDistance) {
        _dragOffset = _triggerRefreshDistance;
      } else {
        _dragOffset += details.primaryDelta!;
      }
    });
  }

  Future<void> _onVerticalDragEnd(DragEndDetails details) async {
    if (_dragOffset >= (_triggerRefreshDistance - 20)) {
      setState(() {
        _dragOffset = _triggerRefreshDistance;
      });

      _controller.value =
          (_dragOffset / _triggerRefreshDistance).clamp(0, 1).toDouble();

      _controller.repeat();

      await widget.onRefresh();
    }

    if (!mounted) {
      return;
    }
    // Reset the drag offset and animation
    setState(() {
      _dragOffset = 0.0;
    });
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: Stack(
        children: [
          widget.child,
          if (_dragOffset > 0)
            Positioned(
              top: _dragOffset.clamp(0, _triggerRefreshDistance),
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 3,
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, ch) {
                        final percentOfDrag =
                            (_dragOffset / _triggerRefreshDistance)
                                .clamp(0, 1)
                                .toDouble();

                        return Transform.rotate(
                          angle: (_controller.isAnimating
                                  ? _controller.value
                                  : percentOfDrag) *
                              2 *
                              math.pi,
                          child: Opacity(
                            opacity: percentOfDrag,
                            child: Icon(
                              Icons.refresh,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        );
                      }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
