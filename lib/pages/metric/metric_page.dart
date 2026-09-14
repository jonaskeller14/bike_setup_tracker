import 'package:flutter/material.dart';

enum MetricPageMode {
  add,
  edit,
  duplicate,
  template,
}

String? validateMetricName(String? value) {
  if (value == null || value.trim().isEmpty) return 'Name is required';
  return null;
}

const int kMetricNameWarningLength = 10;

Widget? metricNameLengthWarning(BuildContext context, String name) {
  if (name.trim().length <= kMetricNameWarningLength) return null;
  final helperColor = Theme.of(context).colorScheme.onSurfaceVariant;
  return Row(
    children: [
      Icon(Icons.warning, size: 14, color: helperColor),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          'Short names display better in other views.',
          style: TextStyle(color: helperColor, fontSize: 12),
        ),
      ),
    ],
  );
}

class CollapsibleMetricPreview extends StatefulWidget {
  final Widget child;

  const CollapsibleMetricPreview({super.key, required this.child});

  @override
  State<CollapsibleMetricPreview> createState() => _CollapsibleMetricPreviewState();
}

class _CollapsibleMetricPreviewState extends State<CollapsibleMetricPreview> {
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
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            width: double.infinity,
            color: theme.colorScheme.inverseSurface,
            padding: EdgeInsets.fromLTRB(16, 8, 16, _expanded ? 8 : 8 + bottomInset),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                chevron,
                Text(
                  _expanded ? "Preview only — changes won’t be saved!" : 'Preview',
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
