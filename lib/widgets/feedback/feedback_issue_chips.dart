import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/feedback/custom_issue.dart';
import '../../models/feedback/feedback_key.dart';
import '../../models/feedback/feedback_vocabulary.dart';
import '../../services/custom_issue_service.dart';

/// "Anything stand out?": the problem chips per end of the bike, the rider's
/// own issues, plus "Nothing stood out", which excludes every chip and vice
/// versa.
class FeedbackIssueChips extends StatelessWidget {
  final Set<IssueKey> issues;

  /// The issues flagged on this feedback.
  final List<CustomIssue> customIssues;

  /// Every issue used so far; the most used ones get a chip of their own.
  final CustomIssueIndex knownIssues;
  final bool nothingStoodOut;
  final void Function(Set<IssueKey> issues, List<CustomIssue> customIssues, bool nothingStoodOut) onChanged;

  /// Opens the issues sheet, straight into its new-issue field when `addIssue`.
  final void Function({required bool addIssue}) onOpenCustomIssues;

  const FeedbackIssueChips({
    super.key,
    required this.issues,
    required this.customIssues,
    required this.knownIssues,
    required this.nothingStoodOut,
    required this.onChanged,
    required this.onOpenCustomIssues,
  });

  /// More issues than this are reached through "All issues".
  static const int maxCustomChips = 8;

  void _toggleIssue(IssueKey key, bool selected) {
    unawaited(HapticFeedback.selectionClick());
    onChanged(selected ? {...issues, key} : ({...issues}..remove(key)), customIssues, false);
  }

  void _toggleCustomIssue(CustomIssue issue, bool selected) {
    unawaited(HapticFeedback.selectionClick());
    onChanged(
      issues,
      selected ? [...customIssues, issue] : customIssues.where((c) => c.slug != issue.slug).toList(),
      false,
    );
  }

  void _toggleNothingStoodOut(bool selected) {
    unawaited(HapticFeedback.selectionClick());
    onChanged(selected ? const {} : issues, selected ? const [] : customIssues, selected);
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
        const SizedBox(height: 12),
        _customSection(context),
      ],
    );
  }

  Widget _customSection(BuildContext context) {
    final selected = {for (final issue in customIssues) issue.slug: issue};
    final popular = knownIssues.usages.take(maxCustomChips).map((usage) => usage.issue).toList();
    // The chips stay put while toggled; issues new to this feedback join the end.
    final shown = [...popular, ...customIssues.where((issue) => popular.every((p) => p.slug != issue.slug))];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Other', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final issue in shown)
              FilterChip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: Text(issue.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                selected: selected.containsKey(issue.slug),
                onSelected: (value) => _toggleCustomIssue(selected[issue.slug] ?? issue, value),
              ),
            ActionChip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              avatar: const Icon(Icons.add),
              label: const Text('Add issue'),
              onPressed: () => onOpenCustomIssues(addIssue: true),
            ),
            if (knownIssues.usages.length > maxCustomChips)
              ActionChip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: const Text('All issues'),
                onPressed: () => onOpenCustomIssues(addIssue: false),
              ),
          ],
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
