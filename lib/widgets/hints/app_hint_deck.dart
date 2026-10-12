import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme.dart';

class AppHintAction {
  const AppHintAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.completesHint = true,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() onPressed;

  /// Whether the card flies away before [onPressed] runs. Set to false for
  /// actions that keep the hint on screen (e.g. one step of a checklist).
  final bool completesHint;
}

class AppHintDeck extends StatefulWidget {
  const AppHintDeck({
    super.key,
    required this.icon,
    required this.label,
    required this.pages,
    this.title,
    this.onDismiss,
    this.action,
    this.onLearnMore,
    this.dismissLabel = 'No thanks',
  }) : assert(pages.length > 0);

  final IconData icon;
  final String label;
  final String? title;
  final List<Widget> pages;
  final VoidCallback? onDismiss;
  final AppHintAction? action;
  /// Opens an explainer, e.g. the sheet of the Features page. Resolving to
  /// true runs [action] as if it had been tapped.
  final Future<bool?> Function()? onLearnMore;
  final String dismissLabel;

  @override
  State<AppHintDeck> createState() => _AppHintDeckState();
}

class _AppHintDeckState extends State<AppHintDeck> with SingleTickerProviderStateMixin {
  static const _flyDuration = Duration(milliseconds: 200);
  static const _exitDuration = Duration(milliseconds: 320);
  static const _fadeDuration = Duration(milliseconds: 180);
  static const _flingVelocity = 600.0;
  static const _maxCardsBehind = 2;

  late final AnimationController _dx = AnimationController.unbounded(vsync: this)..addListener(_rebuild);
  double _width = 1;
  bool _animating = false;
  bool _fading = false;
  int _index = 0;

  int get _count => widget.pages.length;
  bool get _paged => _count > 1;
  bool get _isLast => _index == _count - 1;
  double get _travel => _width + 24;
  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  void _rebuild() => setState(() {});

  @override
  void didUpdateWidget(AppHintDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= _count) _index = _count - 1;
  }

  @override
  void dispose() {
    _dx.dispose();
    super.dispose();
  }

  Future<void> _fly({required bool forward}) async {
    if (_animating || (forward ? _isLast : _index == 0)) return;
    unawaited(HapticFeedback.selectionClick());
    _animating = true;
    if (!_reduceMotion) {
      await _dx.animateTo(
        forward ? -_travel : _travel,
        duration: _flyDuration,
        curve: forward ? Curves.easeIn : Curves.easeOut,
      );
      if (!mounted) return;
    }
    setState(() => _index += forward ? 1 : -1);
    _dx.value = 0;
    _animating = false;
  }

  void _jumpTo(int index) {
    if (index == _index + 1) return unawaited(_fly(forward: true));
    if (index == _index - 1) return unawaited(_fly(forward: false));
    if (_animating || index == _index) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _index = index);
  }

  /// Same exit as a swiped card, with a small wind-up so the tap feels acknowledged.
  /// The card stays off-screen afterwards: the hint service only removes the
  /// slot once the new status is persisted, which can take a few frames.
  Future<void> _flyAway(Future<void> Function() then) async {
    if (_animating) return;
    unawaited(HapticFeedback.lightImpact());
    _animating = true;
    if (!_reduceMotion) {
      await _dx.animateTo(-_travel, duration: _exitDuration, curve: Curves.easeInBack);
      if (!mounted) return;
    }
    try {
      await then();
    } catch (_) {
      if (mounted) {
        _dx.value = 0;
        _animating = false;
      }
      rethrow;
    }
  }

  void _fadeOut() {
    if (_animating) return;
    if (_reduceMotion) return widget.onDismiss?.call();
    _animating = true;
    setState(() => _fading = true);
  }

  void _onAction(AppHintAction action) {
    if (!action.completesHint) {
      unawaited(action.onPressed());
      return;
    }
    unawaited(_flyAway(action.onPressed));
  }

  Future<void> _learnMore() async {
    final activate = await widget.onLearnMore!();
    final action = widget.action;
    if (activate != true || action == null || !mounted) return;
    _onAction(action);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_animating) return;
    final delta = details.primaryDelta ?? 0;
    final target = _dx.value + delta;
    final blocked = (target < 0 && _isLast) || (target > 0 && _index == 0);
    _dx.value = blocked ? _dx.value + delta * 0.25 : target;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_animating) return;
    final velocity = details.primaryVelocity ?? 0;
    final dx = _dx.value;
    if (!_isLast && (dx < -_width * 0.3 || velocity < -_flingVelocity)) {
      return unawaited(_fly(forward: true));
    }
    if (_index > 0 && (dx > _width * 0.3 || velocity > _flingVelocity)) {
      return unawaited(_fly(forward: false));
    }
    unawaited(_dx.animateTo(0, duration: _flyDuration, curve: Curves.easeOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _fading ? 0 : 1,
      duration: _fadeDuration,
      onEnd: _fading ? widget.onDismiss : null,
      child: AnimatedScale(
        scale: _fading ? 0.96 : 1,
        duration: _fadeDuration,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _width = constraints.maxWidth;
            return _paged ? _buildDeck() : _withDragOffset(_buildCard(0, interactive: true));
          },
        ),
      ),
    );
  }

  Widget _buildDeck() {
    final dx = _dx.value;
    final progress = dx < 0 ? (-dx / _travel).clamp(0.0, 1.0) : 0.0;
    final cardsBehind = math.min(_count - 1 - _index, _maxCardsBehind);

    Widget behind(int depth) {
      final d = depth - progress;
      return Transform.translate(
        offset: Offset(0, 12 * d),
        child: Transform.scale(
          scale: 1 - 0.05 * d,
          child: _buildCard(_index + depth, interactive: false),
        ),
      );
    }

    return AnimatedPadding(
      duration: _flyDuration,
      padding: EdgeInsets.only(bottom: cardsBehind * 8.0),
      child: GestureDetector(
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        // IntrinsicHeight + StackFit.expand gives every card the height of the tallest one.
        child: IntrinsicHeight(
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              for (var depth = cardsBehind; depth >= 1; depth--) behind(depth),
              _withDragOffset(_buildCard(_index, interactive: true)),
              if (dx > 0 && _index > 0)
                Transform.translate(
                  offset: Offset(dx - _travel, 0),
                  child: _buildCard(_index - 1, interactive: false),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _withDragOffset(Widget card) {
    final dx = math.min(_dx.value, 0.0);
    return Transform.translate(
      offset: Offset(dx, 0),
      child: Transform.rotate(angle: dx / _width * 0.08, child: card),
    );
  }

  Widget _buildCard(int index, {required bool interactive}) {
    final hint = HintColors.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = widget.title;
    final label = _paged ? '${widget.label.toUpperCase()} ${index + 1} / $_count' : widget.label.toUpperCase();

    final card = Container(
      decoration: BoxDecoration(
        color: hint.container,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 6),
            child: _buildContent(index, hint, textTheme, title, label),
          ),
          // Positioned so its touch target doesn't push the header down; the icon
          // sits as far from the top edge as from the right one.
          if (widget.onLearnMore != null)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => unawaited(_learnMore()),
                tooltip: 'Learn more',
                icon: const Icon(Icons.info_outline_rounded),
                iconSize: 18,
                color: hint.accent,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ),
        ],
      ),
    );
    return interactive ? card : IgnorePointer(child: ExcludeSemantics(child: card));
  }

  Widget _buildContent(int index, HintColors hint, TextTheme textTheme, String? title, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 6,
          children: [
            Icon(widget.icon, size: 16, color: hint.accent),
            Flexible(
              child: Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: hint.accent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            // Keeps the label clear of the corner info button.
            if (widget.onLearnMore != null) const SizedBox(width: 24),
          ],
        ),
        if (title != null) ...[
          const SizedBox(height: 2),
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: hint.onContainer),
          ),
        ],
        const SizedBox(height: 6),
        DefaultTextStyle.merge(
          style: textTheme.bodyMedium?.copyWith(color: hint.onContainer),
          child: widget.pages[index],
        ),
        if (_paged) const Spacer(),
        const SizedBox(height: 4),
        _buildFooter(index, hint),
      ],
    );
  }

  Widget _buildFooter(int index, HintColors hint) {
    final isLast = index == _count - 1;
    return Row(
      children: [
        if (_paged) _buildDots(index, hint),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _buildButtons(isLast, hint),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildButtons(bool isLast, HintColors hint) {
    final action = widget.action;
    final canDismiss = widget.onDismiss != null;
    final filledStyle = FilledButton.styleFrom(
      backgroundColor: hint.accent,
      foregroundColor: hint.onAccent,
      visualDensity: VisualDensity.compact,
    );
    final textStyle = TextButton.styleFrom(
      foregroundColor: hint.onContainer,
      visualDensity: VisualDensity.compact,
    );

    return [
      if (!isLast) ...[
        if (canDismiss) TextButton(onPressed: _fadeOut, style: textStyle, child: const Text('Skip')),
        FilledButton(
          onPressed: () => unawaited(_fly(forward: true)),
          style: filledStyle,
          child: const Text('Next'),
        ),
      ] else if (action != null) ...[
        if (canDismiss) TextButton(onPressed: _fadeOut, style: textStyle, child: Text(widget.dismissLabel)),
        Flexible(
          child: FilledButton.icon(
            onPressed: () => _onAction(action),
            style: filledStyle,
            icon: Icon(action.icon, size: 18),
            label: Text(action.label, overflow: TextOverflow.ellipsis),
          ),
        ),
      ] else if (canDismiss)
        FilledButton(
          onPressed: () => unawaited(_flyAway(() async => widget.onDismiss?.call())),
          style: filledStyle,
          child: const Text('Got it'),
        ),
    ];
  }

  Widget _buildDots(int index, HintColors hint) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var d = 0; d < _count; d++)
          Semantics(
            button: true,
            selected: d == index,
            label: '${widget.label} ${d + 1} of $_count',
            child: GestureDetector(
              onTap: () => _jumpTo(d),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                child: AnimatedContainer(
                  duration: _flyDuration,
                  width: d == index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: hint.accent.withValues(alpha: d == index ? 1 : 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
