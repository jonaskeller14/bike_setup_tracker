import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/feedback/feedback_vocabulary.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/dangling_adjustment_service.dart';
import '../../theme.dart';
import '../items/card_header_tile.dart';
import '../lists/adjustment_compact_display/adjustment_cell_layout.dart';
import '../lists/adjustment_compact_display/adjustment_compact_display_list.dart';
import '../sheets/compare_setups.dart';
import '../sheets/pick_setup.dart';
import 'feedback_aspect_row.dart';

/// One comparison as an outlined card: the reference setup (default: the
/// previous one), the values changed since it, the 5-step overall answer and
/// [children] (the follow-ups against the same reference) below.
class FeedbackComparisonField extends StatefulWidget {
  final Setup rated;
  final String referenceId;
  final bool referenceChanged;

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
    this.referenceChanged = false,
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
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _referenceHeader(context, reference),
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

  Widget _referenceHeader(BuildContext context, Setup? reference) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appSettings = context.read<AppSettings>();
    final errorColor = reference == null ? scheme.error : null;

    return CardHeaderTile(
      color: widget.referenceChanged
          ? theme.extension<ValueHighlightColors>()!.changedFill
          : scheme.outlineVariant,
      // Above the header's colour, so the tap ripple shows.
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: () => _pickReference(context, reference),
          contentPadding: EdgeInsets.only(left: 16, right: widget.onRemove == null ? 16 : 4),
          leading: Icon(Setup.iconData, color: errorColor),
          title: Text(
            reference?.displayName ?? 'SETUP NOT FOUND',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold, color: errorColor),
          ),
          subtitle: reference == null
              ? null
              : Text(
                  '${DateFormat(appSettings.dateFormat).format(reference.datetimeLocal)} • '
                  '${DateFormat(appSettings.timeFormat).format(reference.datetimeLocal)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Change reference setup',
                child: Icon(Icons.arrow_drop_down, color: scheme.onSurfaceVariant),
              ),
              if (widget.onRemove case final onRemove?)
                IconButton(icon: const Icon(Icons.close), tooltip: 'Remove comparison', onPressed: onRemove),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickReference(BuildContext context, Setup? reference) async {
    final candidates = widget.candidates;
    final picked = await showPickSetupSheet(
      context,
      title: 'Reference setup',
      selectedId: reference?.id,
      options: [
        widget.rated,
        ...candidates,
        // A stored reference that's no longer offered: later than the rated setup.
        if (reference != null && !candidates.any((setup) => setup.id == reference.id)) reference,
      ],
      // The rated setup is shown for orientation; it can't be its own reference.
      disabledIds: {...widget.usedReferenceIds, widget.rated.id},
      sideLabels: {widget.rated.id: 'Rated'},
    );
    if (picked != null && picked.id != widget.referenceId) widget.onReferenceChanged(picked.id);
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
