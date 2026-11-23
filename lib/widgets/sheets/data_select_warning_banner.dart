import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// Pinned above the item list while [count] selected items reference items
/// that aren't selected. Plain text in the error colour with the actions
/// right below it, so it doesn't read as one more item card.
class DataSelectWarningBanner extends StatelessWidget {
  final int count;
  final VoidCallback onSelectMissing;
  final VoidCallback onShow;

  const DataSelectWarningBanner({
    super.key,
    required this.count,
    required this.onSelectMissing,
    required this.onShow,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    final buttonStyle = TextButton.styleFrom(
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      minimumSize: const Size(0, 40),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Icon(Icons.warning_amber_rounded, color: color),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.dataSelectIssueBanner(count),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
                ),
                Transform.translate(
                  // Lines the button labels up with the text above.
                  offset: const Offset(-8, 0),
                  child: Wrap(
                    children: [
                      TextButton(style: buttonStyle, onPressed: onShow, child: Text(context.l10n.dataSelectShowIssues)),
                      TextButton(
                        style: buttonStyle,
                        onPressed: onSelectMissing,
                        child: Text(context.l10n.dataSelectSelectMissing),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
