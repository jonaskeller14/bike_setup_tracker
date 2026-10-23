import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/feedback/feedback_key.dart';
import '../../models/feedback/feedback_vocabulary.dart';

/// "Anything stand out?": the problem chips per end of the bike, plus
/// "Nothing stood out", which excludes the chips and vice versa.
class FeedbackIssueChips extends StatelessWidget {
  final Set<IssueKey> issues;
  final bool nothingStoodOut;
  final void Function(Set<IssueKey> issues, bool nothingStoodOut) onChanged;

  const FeedbackIssueChips({
    super.key,
    required this.issues,
    required this.nothingStoodOut,
    required this.onChanged,
  });

  void _toggleIssue(IssueKey key, bool selected) {
    unawaited(HapticFeedback.selectionClick());
    onChanged(selected ? {...issues, key} : ({...issues}..remove(key)), false);
  }

  void _toggleNothingStoodOut(bool selected) {
    unawaited(HapticFeedback.selectionClick());
    onChanged(selected ? const {} : issues, selected);
  }

  /// Front and rear sit side by side from this width on.
  static const double sideBySideWidth = 560;

  @override
  Widget build(BuildContext context) {
    final ends = [for (final end in FeedbackEnd.values) _endSection(context, end)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Answers for the whole bike, so it comes before the per-end chips.
        FilterChip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          avatar: nothingStoodOut ? null : const Icon(Icons.check_circle_outline),
          label: const Text(FeedbackVocabulary.nothingStoodOut),
          selected: nothingStoodOut,
          onSelected: _toggleNothingStoodOut,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= sideBySideWidth
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [for (final end in ends) Expanded(child: end)],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: ends,
                ),
        ),
      ],
    );
  }

  Widget _endSection(BuildContext context, FeedbackEnd end) {
    final theme = Theme.of(context);
    final selected = [
      for (final attribute in FeedbackAttribute.values)
        if (issues.contains(IssueKey(end, attribute))) attribute,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(end.label, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final attribute in FeedbackAttribute.values)
              FilterChip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: Text(attribute.problemLabel),
                tooltip: attribute.hint,
                selected: selected.contains(attribute),
                onSelected: (value) => _toggleIssue(IssueKey(end, attribute), value),
              ),
          ],
        ),
        // The hint confirms what a flag means once it's picked.
        for (final attribute in selected)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${attribute.problemLabel}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: attribute.hint),
                ],
              ),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
