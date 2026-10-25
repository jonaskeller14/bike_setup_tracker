import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/setup.dart';
import 'setup_day_list.dart';
import 'sheet.dart';
import 'sheet_header.dart';

/// Lets the user pick among [options]. Returns the selection once the sheet is
/// closed, however it was closed. [warningFor] returns a message to show for the
/// current selection count.
Future<List<String>> showPickSetupsSheet(
  BuildContext context, {
  required String title,
  required List<Setup> options,
  required List<String> selectedIds,
  String? Function(int selectedCount)? warningFor,
  String emptyTitle = 'No setups yet',
  bool showBikeNames = false,
}) async {
  var selected = List.of(selectedIds);
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _PickSetupsSheet(
      title: title,
      options: options,
      selectedIds: selectedIds,
      onChanged: (ids) => selected = ids,
      warningFor: warningFor,
      emptyTitle: emptyTitle,
      showBikeNames: showBikeNames,
    ),
  );
  return selected;
}

class _PickSetupsSheet extends StatefulWidget {
  final String title;
  final List<Setup> options;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final String? Function(int selectedCount)? warningFor;
  final String emptyTitle;
  final bool showBikeNames;

  const _PickSetupsSheet({
    required this.title,
    required this.options,
    required this.selectedIds,
    required this.onChanged,
    required this.warningFor,
    required this.emptyTitle,
    required this.showBikeNames,
  });

  @override
  State<_PickSetupsSheet> createState() => _PickSetupsSheetState();
}

class _PickSetupsSheetState extends State<_PickSetupsSheet> {
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
              child: widget.options.isEmpty
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SheetFilterEmptyHint(icon: Setup.iconData, title: widget.emptyTitle),
                      ),
                    )
                  : SetupDayList(
                      padding: const EdgeInsets.only(bottom: 16),
                      setups: widget.options,
                      tileBuilder: (setup) {
                        final checked = _selected.contains(setup.id);
                        return SetupPickTile(
                          key: Key('pick-setup-option-${setup.id}'),
                          setup: setup,
                          showBikeName: widget.showBikeNames,
                          selected: checked,
                          trailing: Checkbox(
                            value: checked,
                            onChanged: (value) => _toggle(setup.id, value ?? false),
                          ),
                          onTap: () => _toggle(setup.id, !checked),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
