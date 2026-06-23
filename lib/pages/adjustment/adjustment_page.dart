import 'package:flutter/material.dart';

enum AdjustmentPageMode {
  add,
  edit,
  duplicate,
  template,
}

String? validateAdjustmentName(String? value) {
  if (value == null || value.trim().isEmpty) return 'Name is required';
  return null;
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
      color: theme.colorScheme.onInverseSurface	,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            width: double.infinity,
            color: theme.colorScheme.inverseSurface	,
            padding: EdgeInsets.fromLTRB(16, 8, 16, _expanded ? 8 : 8 + bottomInset),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                chevron,
                Text(
                  _expanded ? "Preview only — changes won’t be saved!" : 'Preview',
                  style: TextStyle(
                    color: theme.colorScheme.onInverseSurface	,
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
