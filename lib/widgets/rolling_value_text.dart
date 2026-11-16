import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A value that counts to its new text like a live account balance: a number
/// with a [format] passes a few steps on the way (85, 86, … 90), each
/// changed digit rolling like an odometer wheel, upwards for a higher [value]
/// and downwards for a lower one. Without a [format] the changed characters
/// roll once; text without a [value] rolls as a whole. At rest it is a plain
/// one-line [Text].
class RollingValueText extends StatefulWidget {
  final String text;

  /// Decides which way the characters roll; null for text that is not a number.
  final double? value;

  /// Formats the steps between two values like [text].
  final String Function(double value)? format;
  final TextStyle? style;

  const RollingValueText(this.text, {super.key, this.value, this.format, this.style});

  @override
  State<RollingValueText> createState() => _RollingValueTextState();
}

class _RollingValueTextState extends State<RollingValueText> with SingleTickerProviderStateMixin {
  /// A larger change is split into this many steps.
  static const _maxSteps = 6;

  late final _controller = AnimationController(vsync: this);
  late final _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOutSine);

  /// The values counted through, from the old value to the new one.
  List<double> _stops = const [];
  List<String> _stopTexts = const [];
  bool _up = true;

  @override
  void didUpdateWidget(covariant RollingValueText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text == oldWidget.text || MediaQuery.disableAnimationsOf(context)) return;
    // An update mid-count carries on from what is shown.
    final (fromText, from) = _controller.isAnimating ? _shown() : (oldWidget.text, oldWidget.value);
    final (to, format) = (widget.value, widget.format);
    _up = from == null || to == null || to >= from;
    _stops = from != null && to != null && format != null ? _stepsBetween(from, to) : const [];
    _stopTexts = [
      fromText,
      for (final stop in _stops.skip(1).take(math.max(0, _stops.length - 2))) format!(stop),
      widget.text,
    ];
    final steps = _stopTexts.length - 1;
    _controller.duration = Duration(milliseconds: 600 + 120 * steps);
    _controller.forward(from: 0);
  }

  /// [from], up to [_maxSteps] − 1 evenly spaced whole numbers on the way, and
  /// [to]: a small change passes every whole number, a large one keeps the
  /// same pace.
  static List<double> _stepsBetween(double from, double to) {
    final steps = (to - from).abs().ceil().clamp(1, _maxSteps);
    final between = <double>{
      for (var k = 1; k < steps; k++) (from + (to - from) * k / steps).roundToDouble(),
    }..removeAll([from, to]);
    return [from, ...between, to];
  }

  /// The step a count is between, and how far it has rolled on to the next;
  /// eased per step, so each value settles before the next one comes.
  (int, double) _position() {
    final steps = _stopTexts.length - 1;
    final position = _progress.value * steps;
    final step = math.min(position.floor(), steps - 1);
    return (step, Curves.easeInOut.transform((position - step).clamp(0.0, 1.0)));
  }

  (String, double?) _shown() {
    final (step, rolled) = _position();
    final index = rolled < 0.5 ? step : step + 1;
    return (_stopTexts[index], index < _stops.length ? _stops[index] : null);
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    final text = Text(
      widget.text,
      style: style,
      textAlign: TextAlign.end,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return AnimatedBuilder(
      animation: _controller,
      child: text,
      builder: (context, text) {
        if (!_controller.isAnimating) return text!;
        final (step, rolled) = _position();
        final (fromText, toText) = (_stopTexts[step], _stopTexts[step + 1]);
        // Without a value there are no steps between, so this is the new text.
        if (widget.value == null) return _slot(fromText, text!, rolled, style);

        final to = toText.characters.toList();
        final from = fromText.characters.toList();
        final length = math.max(to.length, from.length);
        // Right-aligned, so the units and the ones digits stay in line.
        String at(List<String> chars, int i) {
          final index = i - (length - chars.length);
          return index < 0 ? '' : chars[index];
        }

        return Align(
          alignment: AlignmentDirectional.centerEnd,
          heightFactor: 1,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < length; i++)
                  if (at(from, i) == at(to, i))
                    Text(at(to, i), style: style)
                  else
                    _slot(at(from, i), Text(at(to, i), style: style), rolled, style),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The incoming text sizes the slot, so the layout already is the one the
  /// step settles on; the outgoing text is clipped to it.
  Widget _slot(String from, Widget to, double rolled, TextStyle style) {
    final direction = _up ? 1.0 : -1.0;
    return ClipRect(
      child: Stack(
        alignment: AlignmentDirectional.centerEnd,
        children: [
          Positioned.fill(
            child: FractionalTranslation(
              translation: Offset(0, -direction * rolled),
              child: Opacity(
                opacity: 1 - rolled,
                child: Text(from, style: style, textAlign: TextAlign.end, maxLines: 1, softWrap: false),
              ),
            ),
          ),
          FractionalTranslation(
            translation: Offset(0, direction * (1 - rolled)),
            child: Opacity(opacity: rolled, child: to),
          ),
        ],
      ),
    );
  }
}
