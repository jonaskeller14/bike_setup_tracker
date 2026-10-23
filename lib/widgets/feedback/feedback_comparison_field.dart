import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/feedback/feedback_vocabulary.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/dangling_adjustment_service.dart';
import '../lists/adjustment_compact_display/adjustment_cell_layout.dart';
import '../lists/adjustment_compact_display/adjustment_compact_display_list.dart';
import 'feedback_aspect_row.dart';

/// The reference setup (default: the previous one), the values changed since
/// it, and the 5-step overall answer.
class FeedbackComparisonField extends StatelessWidget {
  final Setup rated;
  final String referenceId;

  /// Earlier setups of the bike, newest first.
  final List<Setup> candidates;
  final int? outcome;
  final ValueChanged<int?> onOutcomeChanged;
  final ValueChanged<String> onReferenceChanged;

  const FeedbackComparisonField({
    super.key,
    required this.rated,
    required this.referenceId,
    required this.candidates,
    required this.outcome,
    required this.onOutcomeChanged,
    required this.onReferenceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final reference = context.read<AppRepository>().setups[referenceId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _referenceField(context, reference),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 8,
            children: [
              Text('What changed', style: theme.textTheme.titleSmall),
              // A paragraph of its own, so the arrow centres on the small text,
              // not on the taller title line.
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: 'reference ',
                    children: [
                      // The icon the change cells below use; a "→" glyph sits low next to the text.
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          cellChangeArrowIcon,
                          size: cellChangeArrowSizeFor(subtitleStyle?.fontSize ?? 12),
                          color: subtitleStyle?.color,
                        ),
                      ),
                      const TextSpan(text: ' rated setup'),
                    ],
                  ),
                  style: subtitleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        _changes(context, reference),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('How did it ride?', style: theme.textTheme.titleSmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FeedbackOutcomeSelector(
            labels: FeedbackVocabulary.overallOutcomeLabels,
            outcome: outcome,
            onChanged: onOutcomeChanged,
          ),
        ),
      ],
    );
  }

  Widget _referenceField(BuildContext context, Setup? reference) {
    final error = Theme.of(context).colorScheme.error;
    final options = <(String, Setup?)>[
      for (final candidate in candidates) (candidate.id, candidate),
      // A stored reference that's no longer offered: deleted, or later than the rated setup.
      if (!candidates.any((setup) => setup.id == referenceId)) (referenceId, reference),
    ];
    Widget label(Setup? setup) => setup == null
        ? Text(
            "SETUP NOT FOUND",
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: error, fontWeight: FontWeight.bold),
          )
        : _SetupLabel(setup: setup);

    return DropdownButtonFormField<String>(
      // The reference can move without the rider (date or bike change).
      key: ValueKey(referenceId),
      initialValue: referenceId,
      isExpanded: true,
      isDense: false,
      itemHeight: null,
      decoration: const InputDecoration(
        labelText: 'Reference setup',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final (id, setup) in options) DropdownMenuItem<String>(value: id, child: label(setup)),
      ],
      onChanged: (id) {
        if (id != null) onReferenceChanged(id);
      },
    );
  }

  Widget _changes(BuildContext context, Setup? reference) {
    final appRepository = context.read<AppRepository>();
    final appSettings = context.read<AppSettings>();
    final theme = Theme.of(context);

    Map<String, AdjustmentValue> valuesOf(Setup setup) => {
      ...appRepository.setupHistory.previousValuesOf(setup.id),
      ...setup.bikeAdjustmentValues,
      ...setup.personAdjustmentValues,
    };
    final breakdown = DanglingAdjustmentService.analyzeSetup(
      setup: rated,
      components: appRepository.components.values,
      persons: appRepository.persons.values,
    );
    final persons = [?breakdown.person];
    final values = valuesOf(rated);
    final referenceValues = reference == null ? const <String, AdjustmentValue>{} : valuesOf(reference);

    final hasChanges = AdjustmentCompactDisplayList.summarize(
      components: breakdown.components,
      persons: persons,
      adjustmentValues: values,
      previousAdjustmentValues: referenceValues,
      displayPersonAdjustmentValues: appSettings.enablePerson,
    ).collapsedHasContent;
    if (reference == null || !hasChanges) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          reference == null ? 'Values of the reference are unavailable' : 'No values changed',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return AdjustmentCompactDisplayList(
      components: breakdown.components,
      persons: persons,
      adjustmentValues: values,
      previousAdjustmentValues: referenceValues,
      showRowIcons: true,
      displayOnlyChanges: true,
      displayPersonAdjustmentValues: appSettings.enablePerson,
      ancestorsOf: (componentId) => appRepository.componentHierarchy.ancestorsBelowBikeAt(componentId, rated.datetime),
    );
  }
}

class _SetupLabel extends StatelessWidget {
  final Setup setup;

  const _SetupLabel({required this.setup});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          setup.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          '${DateFormat(appSettings.dateFormat).format(setup.datetimeLocal)} • '
          '${DateFormat(appSettings.timeFormat).format(setup.datetimeLocal)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
