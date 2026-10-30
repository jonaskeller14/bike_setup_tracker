import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

enum AdjustmentPageMode {
  add,
  edit,
  duplicate,
  template,
}

enum AdjustmentTerm {
  adjustment,
  attribute,
}

String? validateAdjustmentName(BuildContext context, String? value) {
  if (value == null || value.trim().isEmpty) return context.l10n.adjustmentNameRequired;
  return null;
}

const int kAdjustmentNameWarningLength = 10;

Widget? adjustmentNameLengthWarning(BuildContext context, String name) {
  if (name.trim().length <= kAdjustmentNameWarningLength) return null;
  final helperColor = Theme.of(context).colorScheme.onSurfaceVariant;
  return Row(
    children: [
      Icon(Icons.warning, size: 14, color: helperColor),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          context.l10n.adjustmentNameTooLong,
          style: TextStyle(color: helperColor, fontSize: 12),
        ),
      ),
    ],
  );
}

class CollapsibleAdjustmentPreview extends StatefulWidget {
  final Widget child;

  const CollapsibleAdjustmentPreview({super.key, required this.child});

  @override
  State<CollapsibleAdjustmentPreview> createState() => _CollapsibleAdjustmentPreviewState();
}

class _CollapsibleAdjustmentPreviewState extends State<CollapsibleAdjustmentPreview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final chevron = Icon(
      _expanded ? Icons.keyboard_double_arrow_down : Icons.keyboard_double_arrow_up,
      size: 18,
      color: theme.colorScheme.onInverseSurface,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: theme.colorScheme.inverseSurface,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            // The theme ripple is barely visible on the inverse surface.
            splashColor: theme.colorScheme.onInverseSurface.withValues(alpha: 0.12),
            highlightColor: theme.colorScheme.onInverseSurface.withValues(alpha: 0.08),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, _expanded ? 8 : 8 + bottomInset),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  chevron,
                  Text(
                    _expanded ? context.l10n.adjustmentPreviewExpanded : context.l10n.adjustmentPreviewTitle,
                    style: TextStyle(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  chevron,
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Container(
                  width: double.infinity,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
                    child: widget.child,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
