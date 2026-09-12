import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bare "+" affordance that expands into an inline field for a new tag,
/// mirroring the add-option chip of the categorical sheet.
class AddTagChip extends StatefulWidget {
  /// Starts expanded and focused — used when there is no tag to pick yet.
  final bool autofocus;

  /// Scales the whole field up — text, icons and padding — for the very first tag.
  final bool prominent;

  final ValueChanged<bool>? onEditingChanged;

  /// Returns an error message to show inline, or null once the tag was added.
  final String? Function(String value) onSubmit;

  const AddTagChip({
    super.key,
    this.autofocus = false,
    this.prominent = false,
    this.onEditingChanged,
    required this.onSubmit,
  });

  @override
  State<AddTagChip> createState() => _AddTagChipState();
}

class _AddTagChipState extends State<AddTagChip> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late bool _editing = widget.autofocus;
  String? _error;

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _setEditing(bool editing) {
    setState(() => _editing = editing);
    widget.onEditingChanged?.call(editing);
  }

  void _collapse() {
    _controller.clear();
    _error = null;
    _focusNode.unfocus();
    _setEditing(false);
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      _collapse();
      return;
    }
    final error = widget.onSubmit(value);
    if (error != null) {
      setState(() => _error = error);
      _focusNode.requestFocus();
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    _collapse();
  }

  /// Width the field needs to show [text] in full, decoration included.
  double _widthFor(String text, TextStyle? style, double chrome) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    // A trailing caret's worth of slack keeps the text off the suffix button.
    return painter.width + chrome + 4;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_editing) {
      return IconButton(
        icon: const Icon(Icons.add),
        tooltip: 'Add tag',
        color: theme.colorScheme.primary,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        onPressed: () => _setEditing(true),
      );
    }

    // The first tag has the sheet to itself, so the field is scaled up rather
    // than left chip-sized.
    final TextStyle? style = widget.prominent ? theme.textTheme.titleMedium : theme.textTheme.labelLarge;
    final double iconSize = widget.prominent ? 22 : 18;
    final double horizontalPadding = widget.prominent ? 14 : 12;
    final double verticalPadding = widget.prominent ? 14 : 8;

    // Prefix slot + content padding + the suffix button's own tap target.
    final double chrome = 32 + horizontalPadding * 2 + 40;
    final double minWidth = _widthFor('New tag', style, chrome);

    return LayoutBuilder(builder: (context, constraints) {
      // Grows with the text until it fills the row it sits in; past that the
      // field keeps its width and scrolls its content.
      final double maxWidth =
          constraints.maxWidth.isFinite && constraints.maxWidth > minWidth ? constraints.maxWidth : minWidth;
      final double width = _controller.text.isEmpty
          ? minWidth
          : _widthFor(_controller.text, style, chrome).clamp(minWidth, maxWidth);

      return SizedBox(
        width: width,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          style: style,
          onSubmitted: (_) => _submit(),
          // Rebuilds so the field can grow with what has been typed.
          onChanged: (_) => setState(() => _error = null),
          onTapOutside: (_) {
            if (_controller.text.trim().isEmpty && _editing) _collapse();
          },
          decoration: InputDecoration(
            isDense: true,
            hintText: 'New tag',
            errorText: _error,
            prefixIcon: Icon(Icons.tag, size: iconSize),
            prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 0),
            contentPadding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: IconButton(
              icon: Icon(Icons.check, size: iconSize),
              tooltip: 'Add',
              visualDensity: VisualDensity.compact,
              onPressed: _submit,
            ),
          ),
        ),
      );
    });
  }
}
