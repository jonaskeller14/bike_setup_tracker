import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/setup.dart';
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

  const _PickSetupsSheet({
    required this.title,
    required this.options,
    required this.selectedIds,
    required this.onChanged,
    required this.warningFor,
    required this.emptyTitle,
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
    final dateFormat = context.read<AppSettings>().dateFormat;
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
                padding: const EdgeInsets.only(bottom: 16),
                child: widget.options.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SheetFilterEmptyHint(icon: Setup.iconData, title: widget.emptyTitle),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final setup in widget.options)
                            Material(
                              type: MaterialType.transparency,
                              child: CheckboxListTile(
                                value: _selected.contains(setup.id),
                                controlAffinity: ListTileControlAffinity.trailing,
                                secondary: const Icon(Setup.iconData),
                                title: Text(setup.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(DateFormat(dateFormat).format(setup.datetimeLocal)),
                                onChanged: (checked) => _toggle(setup.id, checked ?? false),
                              ),
                            ),
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
