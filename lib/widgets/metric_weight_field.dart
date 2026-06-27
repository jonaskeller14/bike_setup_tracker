import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MetricWeightField extends StatefulWidget {
  final TextEditingController? controller;
  final bool scored;
  final double step;

  const MetricWeightField({
    super.key,
    this.controller,
    this.scored = true,
    this.step = 0.5,
  });

  /// Trims trailing ".0" so 1.0 → "1" / -1.0 → "-1" while keeping 1.5 etc.
  static String formatWeight(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  State<MetricWeightField> createState() => _MetricWeightFieldState();
}

class _MetricWeightFieldState extends State<MetricWeightField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _setValue(_value); // re-format / heal on blur
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(widget.controller?.text.trim() ?? '') ?? 0;

  void _setValue(double v) {
    final text = MetricWeightField.formatWeight(v);
    widget.controller?.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _bump(double delta) {
    unawaited(HapticFeedback.selectionClick());
    _focus.unfocus();
    _setValue(_value + delta);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!widget.scored) {
      return Row(
        children: [
          Icon(Icons.do_not_disturb_on_outlined, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Not included in the score",
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Scoring weight",
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.outlined(
              onPressed: () => _bump(-widget.step),
              icon: const Icon(Icons.remove),
              tooltip: 'Decrease weight',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$'))],
                onTap: () {
                  final c = widget.controller;
                  if (c != null) {
                    c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
                  }
                },
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: () => _bump(widget.step),
              icon: const Icon(Icons.add),
              tooltip: 'Increase weight',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: widget.controller!,
          builder: (context, _) {
            final v = double.tryParse(widget.controller!.text.trim());
            final (IconData icon, String text) = switch (v) {
              null => (Icons.help_outline, 'Set how this metric affects the score'),
              _ when v > 0 => (Icons.arrow_upward, 'Higher values improve the score'),
              _ when v < 0 => (Icons.arrow_downward, 'Lower values improve the score'),
              _ => (Icons.block, 'Not counted in the score'),
            };
            return Row(
              children: [
                Icon(icon, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
