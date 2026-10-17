import 'package:flutter/material.dart';

import 'add_tag_chip.dart';
import 'partial_chip_fill.dart';
import 'sheet_header.dart';

class BulkTagChanges {
  final Set<String> added;
  final Set<String> removed;

  const BulkTagChanges({required this.added, required this.removed});

  bool get isEmpty => added.isEmpty && removed.isEmpty;

  Set<String> apply(Set<String> tags) => {...tags, ...added}..removeAll(removed);
}

enum _TagState { none, some, all }

Future<BulkTagChanges?> showSetTagsBulkSheet({
  required BuildContext context,
  required List<Set<String>> itemTags,
  required Set<String> availableTags,
  required String title,
  required String subtitle,
  required String applyLabel,
}) {
  return showModalBottomSheet<BulkTagChanges>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return SetTagsBulkSheetContent(
        itemTags: itemTags,
        availableTags: availableTags,
        title: title,
        subtitle: subtitle,
        applyLabel: applyLabel,
      );
    },
  );
}

class SetTagsBulkSheetContent extends StatefulWidget {
  final List<Set<String>> itemTags;
  final Set<String> availableTags;
  final String title;
  final String subtitle;
  final String applyLabel;

  const SetTagsBulkSheetContent({
    super.key,
    required this.itemTags,
    required this.availableTags,
    required this.title,
    required this.subtitle,
    required this.applyLabel,
  });

  @override
  State<StatefulWidget> createState() => _SetTagsBulkSheetContentState();
}

class _SetTagsBulkSheetContentState extends State<SetTagsBulkSheetContent> {
  final Map<String, int> _counts = {};
  final Map<String, _TagState> _initialStates = {};
  final Map<String, _TagState> _states = {};
  late final List<String> _availableTags;
  late bool _addingTag;

  @override
  void initState() {
    super.initState();
    for (final tags in widget.itemTags) {
      for (final tag in tags) {
        _counts.update(tag, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    _availableTags = {..._counts.keys, ...widget.availableTags}.toList();
    for (final tag in _availableTags) {
      _initialStates[tag] = _stateForCount(_counts[tag] ?? 0);
    }
    // With nothing to pick from, the sheet opens straight into the new-tag field.
    _addingTag = _availableTags.isEmpty;
  }

  _TagState _stateForCount(int count) {
    if (count == 0) return _TagState.none;
    if (count == widget.itemTags.length) return _TagState.all;
    return _TagState.some;
  }

  _TagState _stateOf(String tag) => _states[tag] ?? _initialStates[tag] ?? _TagState.none;

  bool get _hasPartialTags => _initialStates.values.contains(_TagState.some);

  BulkTagChanges get _changes => BulkTagChanges(
    added: _availableTags
        .where((tag) => _stateOf(tag) == _TagState.all && _initialStates[tag] != _TagState.all)
        .toSet(),
    removed: _availableTags
        .where((tag) => _stateOf(tag) == _TagState.none && _initialStates[tag] != _TagState.none)
        .toSet(),
  );

  void _cycleTag(String tag) {
    final initial = _initialStates[tag] ?? _TagState.none;
    final next = switch (_stateOf(tag)) {
      _TagState.some => _TagState.all,
      _TagState.all => _TagState.none,
      _TagState.none => initial == _TagState.some ? _TagState.some : _TagState.all,
    };
    setState(() => _states[tag] = next);
  }

  String? _addTag(String newTag) {
    if (_availableTags.contains(newTag)) return "Tag already exists";

    setState(() {
      _availableTags.add(newTag);
      _initialStates[newTag] = _TagState.none;
      _states[newTag] = _TagState.all;
    });
    return null;
  }

  Widget _tagChip(String tag, double maxLabelWidth) {
    final state = _stateOf(tag);

    final chip = FilterChip(
      avatar: const Icon(Icons.tag),
      label: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxLabelWidth),
        child: Text(tag, overflow: TextOverflow.ellipsis),
      ),
      selected: state == _TagState.all,
      showCheckmark: false,
      shape: bulkChipShape,
      // Lets the diagonal fill behind the chip show through.
      backgroundColor: state == _TagState.some ? Colors.transparent : null,
      // Without the tap-target padding the chip box matches its painted bounds,
      // so the fill behind it lines up with the chip outline.
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      tooltip: switch (state) {
        _TagState.all => 'On all — tap to remove from all',
        _TagState.some => 'On ${_counts[tag]} of ${widget.itemTags.length} — tap to add to all',
        _TagState.none => 'On none — tap to add to all',
      },
      onSelected: (_) => _cycleTag(tag),
      onDeleted: state == _TagState.none ? null : () => setState(() => _states[tag] = _TagState.none),
    );

    if (state != _TagState.some) return chip;

    // A tag only some items carry gets half the selected fill, split diagonally.
    return PartialChipFill(key: ValueKey('tag-partial-$tag'), child: chip);
  }

  @override
  Widget build(BuildContext context) {
    final changes = _changes;
    final maxLabelWidth = (MediaQuery.sizeOf(context).width - 160).clamp(64.0, double.infinity);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: widget.title),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(widget.subtitle),
            dense: true,
          ),
          if (_hasPartialTags)
            const ListTile(
              leading: PartialChipSwatch(),
              title: Text(
                'Half-filled tags apply to only part of your selection — they stay that way '
                'unless you tap them.',
              ),
              dense: true,
            ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  if (_availableTags.isEmpty && !_addingTag)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          "No tags yet",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 6,
                    // Replaces the run spacing the chips' tap-target padding would add.
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ..._availableTags.map((tag) => _tagChip(tag, maxLabelWidth)),
                      AddTagChip(
                        autofocus: _availableTags.isEmpty,
                        prominent: _availableTags.isEmpty,
                        onEditingChanged: (editing) => setState(() => _addingTag = editing),
                        onSubmit: _addTag,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.check),
              onPressed: changes.isEmpty ? null : () => Navigator.pop(context, changes),
              label: Text(widget.applyLabel, overflow: TextOverflow.ellipsis),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
