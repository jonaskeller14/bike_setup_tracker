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

class DelayedFade extends StatefulWidget {
  final int delay;
  final String keyId;
  final Widget child;

  const DelayedFade({super.key, required this.delay, required this.keyId, required this.child});

  @override
  State<DelayedFade> createState() => _DelayedFadeState();
}

class _DelayedFadeState extends State<DelayedFade> {
  late final Future<void> _delayFuture;

  @override
  void initState() {
    super.initState();
    _delayFuture = Future.delayed(Duration(milliseconds: widget.delay));
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.keyId),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, size, child) {
        return Transform.scale(
          scale: size,
          child: child,
        );
      },
      child: FutureBuilder(
        future: _delayFuture,
        builder: (context, snapshot) {
          return snapshot.connectionState == ConnectionState.done 
              ? widget.child 
              : const Opacity(opacity: 0);
        },
      ),
    );
  }
}
