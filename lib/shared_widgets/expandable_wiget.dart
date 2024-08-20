import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CollapseWidget extends StatefulWidget {
  const CollapseWidget({super.key, required this.children});

  final Widget children;

  @override
  State<CollapseWidget> createState() => _CollapseWidgetState();
}

class _CollapseWidgetState extends State<CollapseWidget>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final GlobalKey _keyFoldChild;
  bool collapsed = false;
  late AnimationController _controller;
  Animation<double>? _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Durations.short4);
    _keyFoldChild = GlobalKey();
    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
  }

  void _afterLayout(_) {
    final renderBoxSize = _keyFoldChild.currentContext!.size!;
    final animDuratation = Duration(
        milliseconds: (1000 / renderBoxSize.height).clamp(200, 2000).toInt());
    final initialHeight = .2.sh;
    if (renderBoxSize.height > initialHeight + 10) {
      setState(() {
        _controller = AnimationController(
          vsync: this,
          duration: animDuratation,
        );
        _sizeAnimation = Tween<double>(
          begin: initialHeight,
          end: renderBoxSize.height,
        ).animate(_controller);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            if (_sizeAnimation == null) {
              return child!;
            } else {
              return ClipRect(
                child: SizedOverflowBox(
                  alignment: Alignment.topCenter,
                  size: Size(double.infinity, _sizeAnimation!.value),
                  child: child,
                ),
              );
            }
          },
          child: SizedBox(
            key: _keyFoldChild,
            child: widget.children,
          ),
        ),
        if (_sizeAnimation != null)
          SeeMoreLessButton(
            type: collapsed ? 2 : 1,
            onSeeMoreLessTap: () {
              setState(() {
                collapsed = !collapsed;
              });
              if (collapsed) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            },
          ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class SeeMoreLessButton extends StatelessWidget {
  final int type; /* type 1 - See More | 2 - See Less */
  final Function onSeeMoreLessTap;

  const SeeMoreLessButton({
    super.key,
    required this.type,
    required this.onSeeMoreLessTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          onSeeMoreLessTap();
        },
        child: Text.rich(
          softWrap: true,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.blue,
          ),
          textAlign: TextAlign.start,
          TextSpan(
            children: [
              TextSpan(
                text: type == 1 ? 'See More' : 'See Less',
              ),
              const WidgetSpan(
                child: SizedBox(
                  width: 3.0,
                ),
              ),
              WidgetSpan(
                child: Icon(
                  (type == 1)
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  color: Colors.blue,
                  size: 17.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
