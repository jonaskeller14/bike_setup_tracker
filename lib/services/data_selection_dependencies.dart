import 'package:flutter/foundation.dart';

import '../models/component/installation.dart';
import '../models/selected_data.dart';
import '../models/syncable.dart';

enum DataKind { person, bike, component, setup, taskRule, taskEntry, feedback, testSession }

@immutable
class DataRef {
  final DataKind kind;
  final String id;

  const DataRef(this.kind, this.id);

  @override
  bool operator ==(Object other) => identical(this, other) || other is DataRef && kind == other.kind && id == other.id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'DataRef(${kind.name}, $id)';
}

Map<String, Syncable> _itemsOf(SelectedData data, DataKind kind) => switch (kind) {
  DataKind.person => data.persons,
  DataKind.bike => data.bikes,
  DataKind.component => data.components,
  DataKind.setup => data.setups,
  DataKind.taskRule => data.taskRules,
  DataKind.taskEntry => data.taskEntries,
  DataKind.feedback => data.feedbacks,
  DataKind.testSession => data.testSessions,
};

/// The ticked item ids of a data selection sheet, one set per [DataKind].
class DataSelection {
  final Map<DataKind, Set<String>> _ids = {for (final kind in DataKind.values) kind: <String>{}};

  DataSelection();

  /// Every item of [data] selected.
  DataSelection.all(SelectedData data) {
    for (final kind in DataKind.values) {
      _ids[kind]!.addAll(_itemsOf(data, kind).keys);
    }
  }

  bool contains(DataRef ref) => _ids[ref.kind]!.contains(ref.id);

  bool add(DataRef ref) => _ids[ref.kind]!.add(ref.id);

  /// Returns the refs that were not selected before.
  Set<DataRef> addAll(Iterable<DataRef> refs) => {
    for (final ref in refs)
      if (add(ref)) ref,
  };

  bool remove(DataRef ref) => _ids[ref.kind]!.remove(ref.id);

  int count(DataKind kind) => _ids[kind]!.length;

  /// The selected items of [allData], in [allData]'s order.
  SelectedData toSelectedData(SelectedData allData) {
    Map<String, T> pick<T>(Map<String, T> items, DataKind kind) => {
      for (final entry in items.entries)
        if (_ids[kind]!.contains(entry.key)) entry.key: entry.value,
    };
    return SelectedData(
      persons: pick(allData.persons, DataKind.person),
      bikes: pick(allData.bikes, DataKind.bike),
      components: pick(allData.components, DataKind.component),
      setups: pick(allData.setups, DataKind.setup),
      taskRules: pick(allData.taskRules, DataKind.taskRule),
      taskEntries: pick(allData.taskEntries, DataKind.taskEntry),
      feedbacks: pick(allData.feedbacks, DataKind.feedback),
      testSessions: pick(allData.testSessions, DataKind.testSession),
    );
  }
}

/// A selected item whose [missing] references aren't selected.
@immutable
class DataSelectionIssue {
  final DataRef item;
  final Set<DataRef> missing;

  const DataSelectionIssue(this.item, this.missing);

  Set<DataKind> get missingKinds => {for (final ref in missing) ref.kind};
}

class DataSelectionIssues {
  final List<DataSelectionIssue> items;

  const DataSelectionIssues(this.items);

  bool get isEmpty => items.isEmpty;

  /// The kinds of the selected items that have an issue.
  Set<DataKind> get affectedKinds => {for (final issue in items) issue.item.kind};

  Set<DataRef> get missing => {for (final issue in items) ...issue.missing};

  Set<DataKind> get missingKinds => {for (final ref in missing) ref.kind};
}

/// The references between the items of one dataset, used to tick what a
/// ticked item depends on and to warn about unticked dependencies.
///
/// Only references whose target is in [allData] count: a reference to an item
/// the dataset doesn't contain can't be fixed by ticking.
class DataSelectionDependencies {
  final SelectedData allData;
  final Map<String, DataRef> _adjustmentOwners;

  DataSelectionDependencies(this.allData)
    : _adjustmentOwners = {
        for (final component in allData.components.values)
          for (final adjustment in component.adjustments) adjustment.id: DataRef(DataKind.component, component.id),
        for (final person in allData.persons.values)
          for (final adjustment in person.adjustments) adjustment.id: DataRef(DataKind.person, person.id),
      };

  Set<DataRef> referencesOf(DataRef ref) {
    final candidates = _candidateReferences(ref);
    return {
      for (final target in candidates)
        if (target != ref && _itemsOf(allData, target.kind).containsKey(target.id)) target,
    };
  }

  Iterable<DataRef> _candidateReferences(DataRef ref) sync* {
    switch (ref.kind) {
      case DataKind.person:
        return;
      case DataKind.bike:
        final person = allData.bikes[ref.id]?.person;
        if (person != null) yield DataRef(DataKind.person, person);
      case DataKind.component:
        for (final installation in allData.components[ref.id]?.installations ?? const <Installation>[]) {
          switch (installation) {
            case BikeInstallation(:final bikeId):
              yield DataRef(DataKind.bike, bikeId);
            case ComponentInstallation(:final parentComponentId):
              yield DataRef(DataKind.component, parentComponentId);
            case Uninstallation() || Archival():
              break;
          }
        }
      case DataKind.setup:
        final setup = allData.setups[ref.id];
        if (setup == null) return;
        yield DataRef(DataKind.bike, setup.bike);
        if (setup.person != null) yield DataRef(DataKind.person, setup.person!);
        if (setup.testSessionId != null) yield DataRef(DataKind.testSession, setup.testSessionId!);
        yield* _ownersOf(setup.bikeAdjustmentValues.keys);
        yield* _ownersOf(setup.personAdjustmentValues.keys);
      case DataKind.testSession:
        final session = allData.testSessions[ref.id];
        if (session == null) return;
        yield DataRef(DataKind.bike, session.bike);
        yield* _ownersOf(session.adjustmentIds);
        yield* _ownersOf(session.locks.keys);
      case DataKind.feedback:
        final feedback = allData.feedbacks[ref.id];
        if (feedback == null) return;
        yield DataRef(DataKind.bike, feedback.bike);
        yield DataRef(DataKind.setup, feedback.setupId);
        for (final comparison in feedback.comparisons) {
          yield DataRef(DataKind.setup, comparison.referenceSetupId);
        }
      case DataKind.taskRule:
        final rule = allData.taskRules[ref.id];
        if (rule == null) return;
        yield* _associationRefs(rule.association.bikeId, rule.association.componentId);
      case DataKind.taskEntry:
        final entry = allData.taskEntries[ref.id];
        if (entry == null) return;
        yield DataRef(DataKind.taskRule, entry.taskRule);
        yield* _associationRefs(entry.association.bikeId, entry.association.componentId);
    }
  }

  Iterable<DataRef> _ownersOf(Iterable<String> adjustmentIds) sync* {
    for (final id in adjustmentIds) {
      final owner = _adjustmentOwners[id];
      if (owner != null) yield owner;
    }
  }

  Iterable<DataRef> _associationRefs(String? bikeId, String? componentId) sync* {
    if (bikeId != null) yield DataRef(DataKind.bike, bikeId);
    if (componentId != null) yield DataRef(DataKind.component, componentId);
  }

  /// [refs] plus everything they reference, transitively.
  Set<DataRef> closureOf(Iterable<DataRef> refs) {
    final visited = <DataRef>{};
    final frontier = [...refs];
    while (frontier.isNotEmpty) {
      final ref = frontier.removeLast();
      if (visited.add(ref)) frontier.addAll(referencesOf(ref));
    }
    return visited;
  }

  /// The selected items with a reference that isn't selected, in [allData]'s
  /// order. Every missing target is in [allData], so ticking it fixes the issue.
  DataSelectionIssues issues(DataSelection selection) {
    final issues = <DataSelectionIssue>[];
    for (final kind in DataKind.values) {
      for (final id in _itemsOf(allData, kind).keys) {
        final item = DataRef(kind, id);
        if (!selection.contains(item)) continue;
        final missing = {
          for (final target in referencesOf(item))
            if (!selection.contains(target)) target,
        };
        if (missing.isNotEmpty) issues.add(DataSelectionIssue(item, missing));
      }
    }
    return DataSelectionIssues(issues);
  }
}
