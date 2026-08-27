import 'package:flutter/material.dart';

class AnimatedAppBarSwitcher extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget child;

  const AnimatedAppBarSwitcher({super.key, required this.child});

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ColoredBox(
        color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          reverseDuration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
              alignment: Alignment.center,
              child: child,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
