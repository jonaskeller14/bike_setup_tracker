import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/feedback/custom_issue.dart';
import '../../repositories/app_repository.dart';
import '../../services/custom_issue_service.dart';
import '../../utils/custom_issue_actions.dart';
import 'add_tag_chip.dart';
import 'sheet_header.dart';

/// Picks the custom issues of a feedback from every issue used so far, and
/// adds new ones. [addIssue] opens straight into the new-issue field.
Future<void> showCustomIssuesSheet({
  required BuildContext context,
  required List<CustomIssue> selected,
  required bool addIssue,
  required ValueChanged<List<CustomIssue>> onChanged,
  required void Function(String from, CustomIssue to) onRenamed,
  required ValueChanged<String> onRemoved,
}) {
  return showModalBottomSheet(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) => CustomIssuesSheetContent(
      selected: selected,
      addIssue: addIssue,
      onChanged: onChanged,
      onRenamed: onRenamed,
      onRemoved: onRemoved,
    ),
  );
}

enum _IssueMenuAction { rename, remove }

class CustomIssuesSheetContent extends StatefulWidget {
  final List<CustomIssue> selected;
  final bool addIssue;
  final ValueChanged<List<CustomIssue>> onChanged;
  final void Function(String from, CustomIssue to) onRenamed;
  final ValueChanged<String> onRemoved;

  const CustomIssuesSheetContent({
    super.key,
    required this.selected,
    required this.addIssue,
    required this.onChanged,
    required this.onRenamed,
    required this.onRemoved,
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
    if (typed == null) return 'Enter a name';
    final issue = index.contains(typed.slug) ? CustomIssue(typed.slug, index.labelOf(typed.slug)) : typed;
    setState(() {
      _added[issue.slug] ??= issue;
      _selected[issue.slug] = issue;
    });
    _notify();
    return null;
  }

  Future<void> _showMenu(BuildContext chipContext, CustomIssue issue) async {
    final box = chipContext.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(chipContext).context.findRenderObject()! as RenderBox;
    final action = await showMenu<_IssueMenuAction>(
      context: chipContext,
      position: RelativeRect.fromRect(
        box.localToGlobal(Offset.zero, ancestor: overlay) & box.size,
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(
          value: _IssueMenuAction.rename,
          child: ListTile(leading: Icon(Icons.edit), title: Text('Rename'), contentPadding: EdgeInsets.zero),
        ),
        PopupMenuItem(
          value: _IssueMenuAction.remove,
          child: ListTile(leading: Icon(Icons.delete), title: Text('Remove'), contentPadding: EdgeInsets.zero),
        ),
      ],
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _IssueMenuAction.rename:
        final renamed = await CustomIssueActions.rename(context, issue: issue);
        if (renamed == null || !mounted) return;
        setState(() {
          if (_selected.remove(issue.slug) != null) _selected[renamed.slug] = renamed;
          if (_added.remove(issue.slug) != null) _added[renamed.slug] = renamed;
        });
        widget.onRenamed(issue.slug, renamed);
        _notify();
      case _IssueMenuAction.remove:
        if (!await CustomIssueActions.remove(context, issue: issue) || !mounted) return;
        setState(() {
          _selected.remove(issue.slug);
          _added.remove(issue.slug);
        });
        widget.onRemoved(issue.slug);
        _notify();
    }
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
          const SheetHeader(title: 'Issues'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Your own problems, beside the built-in ones. Long-press an issue to rename or remove it.'),
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
                      Builder(
                        builder: (chipContext) => GestureDetector(
                          onLongPress: () => unawaited(_showMenu(chipContext, issue)),
                          child: FilterChip(
                            label: Text(issue.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                            selected: _selected.containsKey(issue.slug),
                            showCheckmark: false,
                            avatar: const Icon(Icons.flag_outlined),
                            onSelected: (value) => _toggle(issue, value),
                          ),
                        ),
                      ),
                    AddTagChip(
                      autofocus: widget.addIssue || available.isEmpty,
                      prominent: available.isEmpty,
                      noun: 'issue',
                      icon: Icons.flag_outlined,
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
