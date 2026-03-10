import 'package:flutter/material.dart';

Widget stepWidget({required BuildContext context, required int step}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      "STEP $step",
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget delayedFade({required int delay, required Widget child}) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeOutBack,
    builder: (context, size, child) {
      return Transform.scale(
        scale: size,
        child: child,
      );
    },
    key: ValueKey([child, delay]),
    child: FutureBuilder(
      future: Future.delayed(Duration(milliseconds: delay)),
      builder: (context, snapshot) {
        return snapshot.connectionState == ConnectionState.done 
            ? child 
            : const Opacity(opacity: 0);
      },
    ),
  );
}
