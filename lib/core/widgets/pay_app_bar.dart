import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Goes back one page. If there is nothing to go back to (for example the
/// page was opened with go() instead of push()), it goes to Home instead of doing nothing.
void goBackOrHome(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/home');
  }
}

/// App bar used by every inner screen, with a back button that always works.
class PayAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;

  const PayAppBar({
    super.key,
    this.title,
    this.actions,
    this.bottom,
    this.backgroundColor,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      bottom: bottom,
      backgroundColor: backgroundColor ?? Colors.transparent,
      leading: BackButton(onPressed: () => goBackOrHome(context)),
    );
  }
}
