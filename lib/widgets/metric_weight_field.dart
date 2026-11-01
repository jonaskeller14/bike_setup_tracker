import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../utils/localized_number.dart';
import '../utils/number_input_formatters.dart';

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
  static String formatWeight(double v, String locale) =>
      formatLocalizedDouble(v, fractionDigits: v == v.roundToDouble() ? 0 : 1, locale: locale);

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

  double get _value => parseLocalizedDouble(widget.controller?.text ?? '') ?? 0;

  void _setValue(double v) {
    final text = MetricWeightField.formatWeight(v, context.l10n.localeName);
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
              context.l10n.metricWeightNotScored,
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
          context.l10n.metricWeightTitle,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.outlined(
              onPressed: () => _bump(-widget.step),
              icon: const Icon(Icons.remove),
              tooltip: context.l10n.metricWeightDecrease,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: const [SignedDecimalInputFormatter()],
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
              tooltip: context.l10n.metricWeightIncrease,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: widget.controller!,
          builder: (context, _) {
            final v = parseLocalizedDouble(widget.controller!.text);
            final (IconData icon, String text) = switch (v) {
              null => (Icons.help_outline, context.l10n.metricWeightHintUnset),
              _ when v > 0 => (Icons.arrow_upward, context.l10n.metricWeightHintPositive),
              _ when v < 0 => (Icons.arrow_downward, context.l10n.metricWeightHintNegative),
              _ => (Icons.block, context.l10n.metricWeightHintZero),
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
