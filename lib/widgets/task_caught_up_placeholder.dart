import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'empty_state_placeholder.dart';
import 'fireworks_painter.dart';

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

class _TaskCaughtUpPlaceholderState extends State<TaskCaughtUpPlaceholder> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _fireworks;
  late final List<FireworkBurst> _bursts;
  late final Animation<double> _contentOpacity;
  late final Animation<double> _contentScale;
  late final Animation<double> _iconScale;
  bool _started = false;
  bool _celebrate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fireworks = AnimationController(vsync: this, duration: FireworksPainter.duration);
    _bursts = FireworkBurst.decliningSalvo(Random());
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
    _celebrate = true;
    unawaited(_controller.forward());
    unawaited(_fireworks.forward());
  }

  @override
  void dispose() {
    _fireworks.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.35);
    final l10n = context.l10n;
    final scope = widget.bikeName == null ? l10n.taskCaughtUpScope : l10n.taskCaughtUpScopeBike(widget.bikeName!);
    final semanticsLabel =
        '${l10n.taskCaughtUpTitle}. $scope'
        '${widget.nextTaskName == null ? '' : ' ${l10n.taskCaughtUpNext(widget.nextTaskName!)}'}';

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticsLabel,
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          if (_celebrate)
            Positioned.fill(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: FireworksPainter(
                        animation: _fireworks,
                        bursts: _bursts,
                        colors: [colorScheme.primary, colorScheme.tertiary, colorScheme.secondary],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          FadeTransition(
            opacity: _contentOpacity,
            child: ScaleTransition(
              scale: _contentScale,
              child: EmptyStatePlaceholder(
                icon: Icons.task_alt,
                iconWidget: ScaleTransition(
                  scale: _iconScale,
                  child: Icon(Icons.task_alt, size: 40, color: iconColor),
                ),
                title: l10n.taskCaughtUpTitle,
                subtitle: scope,
                actionLabel: l10n.taskCaughtUpAction,
                onAction: widget.onAddTask,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
