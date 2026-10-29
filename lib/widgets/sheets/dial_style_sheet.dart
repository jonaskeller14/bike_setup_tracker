import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/adjustment/adjustment.dart';
import 'sheet_header.dart';

const double _tileSize = 72;

/// Draws the dial the way the caller shows it, so the tiles preview it exactly.
typedef DialKnobBuilder = Widget Function(
  BuildContext context,
  StepAdjustmentDialColor color,
  StepAdjustmentDialSize size,
);

Future<void> dialStyleSheet({
  required BuildContext context,
  required StepAdjustmentDialColor color,
  required StepAdjustmentDialSize size,
  required DialKnobBuilder knobBuilder,
  required ValueChanged<StepAdjustmentDialColor> onColorChanged,
  required ValueChanged<StepAdjustmentDialSize> onSizeChanged,
}) {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _DialStyleSheet(
      color: color,
      size: size,
      knobBuilder: knobBuilder,
      onColorChanged: onColorChanged,
      onSizeChanged: onSizeChanged,
    ),
  );
}

class _DialStyleSheet extends StatefulWidget {
  final StepAdjustmentDialColor color;
  final StepAdjustmentDialSize size;
  final DialKnobBuilder knobBuilder;
  final ValueChanged<StepAdjustmentDialColor> onColorChanged;
  final ValueChanged<StepAdjustmentDialSize> onSizeChanged;

  const _DialStyleSheet({
    required this.color,
    required this.size,
    required this.knobBuilder,
    required this.onColorChanged,
    required this.onSizeChanged,
  });

  @override
  State<_DialStyleSheet> createState() => _DialStyleSheetState();
}

class _DialStyleSheetState extends State<_DialStyleSheet> {
  late StepAdjustmentDialColor _color = widget.color;
  late StepAdjustmentDialSize _size = widget.size;

  void _selectColor(StepAdjustmentDialColor color) {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _color = color);
    widget.onColorChanged(color);
  }

  void _selectSize(StepAdjustmentDialSize size) {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _size = size);
    widget.onSizeChanged(size);
  }

  Widget _section(String label, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: tiles),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: 'Dial style'),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 20,
                children: [
                  _section('Color', [
                    for (final c in StepAdjustmentDialColor.values)
                      _DialOptionTile(
                        label: c.name,
                        selected: c == _color,
                        onTap: () => _selectColor(c),
                        child: widget.knobBuilder(context, c, _size),
                      ),
                  ]),
                  _section('Size', [
                    for (final s in StepAdjustmentDialSize.values)
                      _DialOptionTile(
                        label: s.name,
                        selected: s == _size,
                        onTap: () => _selectSize(s),
                        child: widget.knobBuilder(context, _color, s),
                      ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialOptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _DialOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 2 : 1),
    );

    return Semantics(
      label: label,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: Colors.transparent,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: SizedBox.square(
            dimension: _tileSize,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
