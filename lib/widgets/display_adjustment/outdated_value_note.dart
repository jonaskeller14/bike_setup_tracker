import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/adjustment/adjustment.dart';

/// A one-line error note shown under a stored value that no longer fits its
/// adjustment's current definition (see [Adjustment.isValidValue]).
class OutdatedValueNote extends StatelessWidget {
  final Adjustment adjustment;

  const OutdatedValueNote({super.key, required this.adjustment});

  static String messageFor(Adjustment adjustment, AppLocalizations l10n) => switch (adjustment) {
    CategoricalAdjustment() => l10n.outdatedValueOptions,
    StepAdjustment() => l10n.outdatedValueRangeOrStep,
    _ => l10n.outdatedValueRange,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(Icons.error_outline, size: 14, color: color),
        Flexible(
          child: Text(
            messageFor(adjustment, context.l10n),
            style: theme.textTheme.bodySmall?.copyWith(color: color),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
