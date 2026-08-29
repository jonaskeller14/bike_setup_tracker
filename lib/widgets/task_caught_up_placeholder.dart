import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'empty_state_placeholder.dart';

class TaskCaughtUpPlaceholder extends StatefulWidget {
  final String? bikeName;
  final String? nextTaskName;
  final VoidCallback onAddTask;
  final bool animate;

  const TaskCaughtUpPlaceholder({
    super.key,
    this.bikeName,
    this.nextTaskName,
    required this.onAddTask,
    this.animate = false,
  });

  @override
  State<TaskCaughtUpPlaceholder> createState() => _TaskCaughtUpPlaceholderState();
}

class _TaskCaughtUpPlaceholderState extends State<TaskCaughtUpPlaceholder> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _contentOpacity;
  late final Animation<double> _contentScale;
  late final Animation<double> _iconScale;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.82, curve: Curves.easeOut),
    );
    _contentScale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _iconScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.55, end: 1.18), weight: 65),
          TweenSequenceItem(tween: Tween(begin: 1.18, end: 1), weight: 35),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.28, 1, curve: Curves.easeOut),
          ),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final mediaQuery = MediaQuery.of(context);
    if (!widget.animate || mediaQuery.disableAnimations || mediaQuery.accessibleNavigation) {
      _controller.value = 1;
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.35);
    final scope = widget.bikeName == null
        ? 'There are no tasks due right now.'
        : '${widget.bikeName} has no tasks due right now.';
    final semanticsLabel =
        'All caught up. $scope'
        '${widget.nextTaskName == null ? '' : ' Next up: ${widget.nextTaskName}.'}';

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticsLabel,
      child: FadeTransition(
        opacity: _contentOpacity,
        child: ScaleTransition(
          scale: _contentScale,
          child: EmptyStatePlaceholder(
            icon: Icons.task_alt,
            iconWidget: ScaleTransition(
              scale: _iconScale,
              child: Icon(Icons.task_alt, size: 40, color: iconColor),
            ),
            title: 'All caught up',
            subtitle: scope,
            actionLabel: 'Add task',
            onAction: widget.onAddTask,
          ),
        ),
      ),
    );
  }
}
