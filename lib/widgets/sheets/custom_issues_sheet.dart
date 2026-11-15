import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/feedback/custom_issue.dart';
import '../../repositories/app_repository.dart';
import '../../services/custom_issue_service.dart';
import '../../theme.dart';
import '../feedback/issue_filter_chip.dart';
import 'add_tag_chip.dart';
import 'sheet_header.dart';

/// Picks the custom issues of a feedback from every issue used so far, and
/// adds new ones. [addIssue] opens straight into the new-issue field.
Future<void> showCustomIssuesSheet({
  required BuildContext context,
  required List<CustomIssue> selected,
  required bool addIssue,
  required ValueChanged<List<CustomIssue>> onChanged,
}) {
  return showModalBottomSheet(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) => CustomIssuesSheetContent(
      selected: selected,
      addIssue: addIssue,
      onChanged: onChanged,
    ),
  );
}

class CustomIssuesSheetContent extends StatefulWidget {
  final List<CustomIssue> selected;
  final bool addIssue;
  final ValueChanged<List<CustomIssue>> onChanged;

  const CustomIssuesSheetContent({
    super.key,
    required this.selected,
    required this.addIssue,
    required this.onChanged,
  });

  @override
  State<CustomIssuesSheetContent> createState() => _CustomIssuesSheetContentState();
}

class _CustomIssuesSheetContentState extends State<CustomIssuesSheetContent> {
  late final Map<String, CustomIssue> _selected = {for (final issue in widget.selected) issue.slug: issue};
  // Issues added in this sheet, which no saved feedback uses yet.
  final Map<String, CustomIssue> _added = {};

  /// Every issue used so far, most used first, then the ones only this form has.
  List<CustomIssue> _available(CustomIssueIndex index) {
    final known = index.usages.map((usage) => usage.issue).toList();
    final extra = [..._selected.values, ..._added.values].where((issue) => !index.contains(issue.slug));
    final bySlug = {for (final issue in extra) issue.slug: issue};
    return [...known, ...bySlug.values];
  }

  void _notify() => widget.onChanged(_selected.values.toList());

  void _toggle(CustomIssue issue, bool selected) {
    setState(() {
      if (selected) {
        _selected[issue.slug] = issue;
      } else {
        _selected.remove(issue.slug);
      }
    });
    _notify();
  }

  /// A typed label that matches an existing issue picks it and keeps its spelling.
  String? _addIssue(String value, CustomIssueIndex index) {
    final typed = CustomIssue.fromLabel(value);
    if (typed == null) return context.l10n.customIssueEnterName;
    final issue = index.contains(typed.slug) ? CustomIssue(typed.slug, index.labelOf(typed.slug)) : typed;
    setState(() {
      _added[issue.slug] ??= issue;
      _selected[issue.slug] = issue;
    });
    _notify();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final index = context.select<AppRepository, CustomIssueIndex>((repository) => repository.customIssues);
    final available = _available(index);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: context.l10n.customIssuesTitle),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(context.l10n.customIssuesInfo),
            dense: true,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final issue in available)
                      IssueFilterChip(
                        label: issue.label,
                        selected: _selected.containsKey(issue.slug),
                        onSelected: (value) => _toggle(issue, value),
                        onDeleted: _selected.containsKey(issue.slug) ? () => _toggle(issue, false) : null,
                      ),
                    AddTagChip(
                      autofocus: widget.addIssue || available.isEmpty,
                      prominent: available.isEmpty,
                      tooltip: context.l10n.feedbackAddIssue,
                      hint: context.l10n.addIssueHint,
                      icon: null,
                      color: Theme.of(context).extension<FeedbackOutcomeColors>()!.worse,
                      onSubmit: (value) => _addIssue(value, index),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
