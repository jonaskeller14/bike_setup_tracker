import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/component/component_ancestor.dart';
import '../../repositories/app_repository.dart';
import '../component_ancestors_column.dart';
import '../text/sheet_section_title.dart';
import 'sheet.dart';
import 'sheet_header.dart';

/// The adjustments of one owner (e.g. a component), listed under one section
/// header. [ancestors] is what it is installed on, listed below the title so
/// two owners with the same name (a tire on the front and one on the rear
/// wheel) stay apart.
class PickAdjustmentsGroup {
  final String title;
  final IconData icon;
  final List<ComponentAncestor> ancestors;
  final List<Adjustment> adjustments;

  const PickAdjustmentsGroup({
    required this.title,
    required this.icon,
    this.ancestors = const [],
    required this.adjustments,
  });
}

/// Lets the user pick adjustments across [groups], in the order they tap them.
/// [onChanged] gets the whole selection after every tap so the caller can follow
/// along; closing the sheet keeps it. [warningFor] returns a message to show for
/// the current selection count.
Future<void> showPickAdjustmentsSheet(
  BuildContext context, {
  required String title,
  required List<PickAdjustmentsGroup> groups,
  required List<String> selectedIds,
  required ValueChanged<List<String>> onChanged,
  String? Function(int selectedCount)? warningFor,
  String emptyTitle = 'No adjustments yet',
  String? emptyHint,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _PickAdjustmentsSheet(
      title: title,
      groups: groups,
      selectedIds: selectedIds,
      onChanged: onChanged,
      warningFor: warningFor,
      emptyTitle: emptyTitle,
      emptyHint: emptyHint,
    ),
  );
}

class _PickAdjustmentsSheet extends StatefulWidget {
  final String title;
  final List<PickAdjustmentsGroup> groups;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final String? Function(int selectedCount)? warningFor;
  final String emptyTitle;
  final String? emptyHint;

  const _PickAdjustmentsSheet({
    required this.title,
    required this.groups,
    required this.selectedIds,
    required this.onChanged,
    required this.warningFor,
    required this.emptyTitle,
    required this.emptyHint,
  });

  @override
  State<_PickAdjustmentsSheet> createState() => _PickAdjustmentsSheetState();
}

class _PickAdjustmentsSheetState extends State<_PickAdjustmentsSheet> {
  late final List<String> _selected = List.of(widget.selectedIds);

  void _toggle(String id, bool selected) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      if (selected) {
        _selected.add(id);
      } else {
        _selected.remove(id);
      }
    });
    widget.onChanged(List.of(_selected));
  }

  @override
  Widget build(BuildContext context) {
    final bikes = context.read<AppRepository>().bikes;
    final warning = widget.warningFor?.call(_selected.length);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(
              title: _selected.isEmpty ? widget.title : '${widget.title} (${_selected.length})',
              titleMaxLines: 2,
            ),
            if (warning != null) SheetWarning(message: warning),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: widget.groups.isEmpty
                    ? SheetFilterEmptyHint(icon: Icons.tune, title: widget.emptyTitle, hint: widget.emptyHint)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final group in widget.groups) ...[
                            SheetSectionTitle(title: group.title, iconData: group.icon),
                            if (group.ancestors.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: ComponentAncestorsColumn(ancestors: group.ancestors, bikes: bikes),
                              ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final adjustment in group.adjustments)
                                  FilterChip(
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    label: Text(adjustment.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    selected: _selected.contains(adjustment.id),
                                    onSelected: (value) => _toggle(adjustment.id, value),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
