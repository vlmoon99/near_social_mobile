import 'package:flutter/cupertino.dart';
import 'package:tap_debouncer/tap_debouncer.dart';

class DebounceButton extends StatelessWidget {
  const DebounceButton({
    Key? key,
    required this.child,
    required this.onPressed,
  }) : super(key: key);

  final Widget child;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TapDebouncer(
      cooldown: const Duration(milliseconds: 10000),
      onTap: () async => onPressed(),
      builder: (context, onTap) => CupertinoButton(
        minSize: 0,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
