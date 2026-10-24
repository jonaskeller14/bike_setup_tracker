import 'dart:async';

import 'package:flutter/material.dart';

import '../models/feedback/test_session.dart';

/// The test session flask. While the session runs it slowly fills and empties
/// from the bottom; with reduced motion, or once ended, it stays full.
class TestSessionIcon extends StatefulWidget {
  final bool running;
  final Color? color;

  const TestSessionIcon({super.key, required this.running, this.color});

  @override
  State<TestSessionIcon> createState() => _TestSessionIconState();
}

class _TestSessionIconState extends State<TestSessionIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
    value: 1,
  );
  late final Animation<double> _level = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  void _sync() {
    if (widget.running && !MediaQuery.disableAnimationsOf(context)) {
      if (!_controller.isAnimating) unawaited(_controller.repeat(reverse: true));
    } else {
      _controller
        ..stop()
        ..value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(TestSessionIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running != widget.running) _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.running) return Icon(TestSession.iconData, color: widget.color);
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Icon(Icons.science_outlined, color: widget.color),
        AnimatedBuilder(
          animation: _level,
          builder: (context, child) => ClipRect(
            child: Align(alignment: Alignment.bottomCenter, widthFactor: 1, heightFactor: _level.value, child: child),
          ),
          child: Icon(TestSession.iconData, color: widget.color),
        ),
      ],
    );
  }
}
