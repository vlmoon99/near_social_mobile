import 'package:flutter/material.dart';
import 'package:near_social_mobile/config/theme.dart';

class CustomSearchBar extends StatefulWidget {
  const CustomSearchBar({
    super.key,
    required this.searchController,
    this.hint = "Search",
  });

  final TextEditingController searchController;
  final String hint;

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar>
    with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();

  Future<bool> get keyboardHidden async {
    // If the embedded value at the bottom of the window is not greater than 0, the keyboard is not displayed.
    check() => (WidgetsBinding.instance.window.viewInsets.bottom) <= 0;
    // If the keyboard is displayed, return the result directly.
    if (!check()) return false;
    // If the keyboard is hidden, in order to cope with the misjudgment caused by the keyboard display/hidden animation process, wait for 0.1 seconds and then check again and return the result.
    return await Future.delayed(
        const Duration(milliseconds: 100), () => check());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    keyboardHidden.then((value) => value ? _focusNode.unfocus() : null);
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: widget.searchController,
      focusNode: _focusNode,
      hintText: "Search",
      hintStyle: const WidgetStatePropertyAll(
        TextStyle(
          color: NEARColors.grey,
        ),
      ),
      elevation: const WidgetStatePropertyAll(4),
    );
  }
}
