import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/person.dart';
import 'partial_chip_fill.dart';
import 'sheet_header.dart';

enum _PersonState { none, some, all }

/// Lets the user pick one rider for all selected bikes, where [bikePersons]
/// holds each bike's current rider. Apply returns the pick, with a `null`
/// person meaning "No rider"; dismissing returns `null`.
Future<({String? person})?> showSetBikePersonSheet({
  required BuildContext context,
  required List<String?> bikePersons,
  required Map<String, Person> persons,
}) {
  return showModalBottomSheet<({String? person})>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) => SetBikePersonSheetContent(bikePersons: bikePersons, persons: persons),
  );
}

class SetBikePersonSheetContent extends StatefulWidget {
  final List<String?> bikePersons;
  final Map<String, Person> persons;

  const SetBikePersonSheetContent({super.key, required this.bikePersons, required this.persons});

  @override
  State<SetBikePersonSheetContent> createState() => _SetBikePersonSheetContentState();
}

class _SetBikePersonSheetContentState extends State<SetBikePersonSheetContent> {
  final Map<String?, int> _counts = {};
  bool _picked = false;
  String? _person;

  @override
  void initState() {
    super.initState();
    for (final person in widget.bikePersons) {
      _counts.update(person, (count) => count + 1, ifAbsent: () => 1);
    }
  }

  List<String?> get _options => [null, ...widget.persons.keys];

  _PersonState _initialStateOf(String? person) {
    final count = _counts[person] ?? 0;
    if (count == 0) return _PersonState.none;
    if (count == widget.bikePersons.length) return _PersonState.all;
    return _PersonState.some;
  }

  _PersonState _stateOf(String? person) {
    if (!_picked) return _initialStateOf(person);
    return person == _person ? _PersonState.all : _PersonState.none;
  }

  bool get _hasPartialPersons => _options.any((person) => _initialStateOf(person) == _PersonState.some);

  bool get _hasChanges => _picked && _initialStateOf(_person) != _PersonState.all;

  void _pick(String? person) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      // Tapping a fully filled chip goes back to how the selection started.
      if (_stateOf(person) == _PersonState.all) {
        _picked = false;
      } else {
        _picked = true;
        _person = person;
      }
    });
  }

  void _apply() {
    unawaited(HapticFeedback.lightImpact());
    Navigator.pop(context, (person: _person));
  }

  Widget _personChip(String? person, double maxLabelWidth) {
    final state = _stateOf(person);

    final chip = FilterChip(
      avatar: Icon(person == null ? Icons.person_off : Icons.person),
      label: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxLabelWidth),
        child: Text(
          person == null ? 'No rider' : widget.persons[person]!.name,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      selected: state == _PersonState.all,
      showCheckmark: false,
      shape: bulkChipShape,
      backgroundColor: state == _PersonState.some ? Colors.transparent : null,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      tooltip: switch (state) {
        _PersonState.all => _picked ? 'Set for all — tap to undo' : 'On all',
        _PersonState.some => 'On ${_counts[person]} of ${widget.bikePersons.length} — tap to set for all',
        _PersonState.none => 'Tap to set for all',
      },
      onSelected: (_) => _pick(person),
    );

    if (state != _PersonState.some) return chip;
    return PartialChipFill(key: ValueKey('person-partial-${person ?? 'none'}'), child: chip);
  }

  @override
  Widget build(BuildContext context) {
    final bikeCount = widget.bikePersons.length;
    final maxLabelWidth = (MediaQuery.sizeOf(context).width - 160).clamp(64.0, double.infinity);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: 'Set Rider', leadingIcon: Icon(Person.iconData)),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(
              widget.persons.isEmpty
                  ? "You can assign a rider as soon as you've created one."
                  : 'Each bike has one rider. Pick the rider for all selected bikes.',
            ),
            dense: true,
          ),
          if (_hasPartialPersons)
            const ListTile(
              leading: PartialChipSwatch(),
              title: Text('Half-filled chips apply to only part of your selection.'),
              dense: true,
            ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [for (final person in _options) _personChip(person, maxLabelWidth)],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.check),
              onPressed: _hasChanges ? _apply : null,
              label: Text(
                Intl.plural(bikeCount, one: 'Apply to 1 Bike', other: 'Apply to $bikeCount Bikes'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
