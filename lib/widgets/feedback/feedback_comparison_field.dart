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
import '../sheets/compare_setups.dart';
import 'feedback_aspect_row.dart';

/// One comparison as an outlined card: the reference setup (default: the
/// previous one), the values changed since it, the 5-step overall answer and
/// [children] (the follow-ups against the same reference) below.
class FeedbackComparisonField extends StatefulWidget {
  final Setup rated;
  final String referenceId;

  /// Earlier setups of the bike, newest first.
  final List<Setup> candidates;

  /// References of the other cards, offered but disabled.
  final Set<String> usedReferenceIds;
  final int? outcome;
  final ValueChanged<int?> onOutcomeChanged;
  final ValueChanged<String> onReferenceChanged;
  final VoidCallback? onRemove;
  final bool initiallyShowChanges;
  final List<Widget> children;

  const FeedbackComparisonField({
    super.key,
    required this.rated,
    required this.referenceId,
    required this.candidates,
    this.usedReferenceIds = const {},
    required this.outcome,
    required this.onOutcomeChanged,
    required this.onReferenceChanged,
    this.onRemove,
    this.initiallyShowChanges = true,
    this.children = const [],
  });

  @override
  State<FeedbackComparisonField> createState() => _FeedbackComparisonFieldState();
}

class _FeedbackComparisonFieldState extends State<FeedbackComparisonField> {
  late bool _showChanges = widget.initiallyShowChanges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final reference = context.read<AppRepository>().setups[widget.referenceId];

    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 12),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 16, right: widget.onRemove == null ? 16 : 4),
                child: Row(
                  children: [
                    Expanded(child: _referenceField(context, reference)),
                    if (widget.onRemove case final onRemove?)
                      IconButton(icon: const Icon(Icons.close), tooltip: 'Remove comparison', onPressed: onRemove),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _showChanges = !_showChanges),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 4),
                  child: Row(
                    children: [
                      Expanded(
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
                      if (reference != null)
                        IconButton(
                          icon: const Icon(Icons.compare, size: 20),
                          tooltip: 'View comparison',
                          visualDensity: VisualDensity.compact,
                          color: theme.colorScheme.onSurfaceVariant,
                          onPressed: () => showCompareSetupsSheet(context, setupA: reference, setupB: widget.rated),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _showChanges ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showChanges) _changes(context, reference),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('How did it ride?', style: theme.textTheme.titleSmall),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FeedbackOutcomeSelector(
                  labels: FeedbackVocabulary.overallOutcomeLabels,
                  outcome: widget.outcome,
                  onChanged: widget.onOutcomeChanged,
                ),
              ),
              ...widget.children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _referenceField(BuildContext context, Setup? reference) {
    final error = Theme.of(context).colorScheme.error;
    final referenceId = widget.referenceId;
    final candidates = widget.candidates;
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
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        labelText: 'Reference setup',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final (id, setup) in options)
          if (widget.usedReferenceIds.contains(id))
            DropdownMenuItem<String>(
              value: id,
              enabled: false,
              child: Opacity(opacity: 0.38, child: label(setup)),
            )
          else
            DropdownMenuItem<String>(value: id, child: label(setup)),
      ],
      onChanged: (id) {
        if (id != null) widget.onReferenceChanged(id);
      },
    );
  }

  Widget _changes(BuildContext context, Setup? reference) {
    final rated = widget.rated;
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
