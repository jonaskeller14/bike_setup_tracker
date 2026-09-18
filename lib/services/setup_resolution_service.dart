import 'package:collection/collection.dart';

import '../models/bike.dart';
import '../models/component.dart';
import '../models/person.dart';
import '../models/rating/rating.dart';
import '../models/setup.dart';
import '../utils/file_import.dart';
import 'component_hierarchy_resolver.dart';

typedef AdjustmentProvenance = ({dynamic value, Setup setup});

class SetupResolutionService {
  /// Sorts setups chronologically and calculates inherited adjustment values.
  static ({Map<String, Setup> setups, Map<String, dynamic> globalState}) resolveSetups({
    required Map<String, Setup> setups,
    required Map<String, Bike> bikes,
    required Map<String, Person> persons,
    required Map<String, Component> components,
    required Map<String, Rating> ratings,
  }) {
    // 1. Sort setups chronologically
    final sortedSetupEntries = setups.entries.toList();
    sortedSetupEntries.sort((a, b) => a.value.datetime.compareTo(b.value.datetime));
    final sortedSetups = Map.fromEntries(sortedSetupEntries);
    final hierarchy = ComponentHierarchyResolver(components);
    
    // 2. Determine Current status
    FileImport.determineCurrentSetups(setups: sortedSetups.values.toList(), bikes: bikes);
    
    // 3. Global State Pass (Look-back resolution)
    final Map<String, dynamic> globalLastKnownState = {};
    
    // Performance optimization: Pre-group adjustments by their category to avoid repeated component iterations
    // However, since components move between bikes, we must check bikeAt(T) for each setup.

    for (final setup in sortedSetups.values) {
      final bike = bikes[setup.bike];
      final person = persons[setup.person];

      // 3.1. Determine relevant adjustment IDs for current setup's bike components
      final bikeAdjustmentIds = <String>{};
      if (bike != null) {
        // Optimization: only check components that were ever on this bike
        for (final component in components.values) {
          if (hierarchy.bikeAt(component.id, setup.datetime) == setup.bike) {
            for (final adjustment in component.adjustments) {
              bikeAdjustmentIds.add(adjustment.id);
            }
          }
        }
      }

      // 3.2. Determine relevant adjustment IDs for current setup's person
      final personAdjustmentIds = <String>{};
      if (person != null) {
        for (final adjustment in person.adjustments) {
          personAdjustmentIds.add(adjustment.id);
        }
      }

      // 3.3. Populate previous adjustment values from global state
      setup.previousBikeAdjustmentValues = {};
      for (final id in bikeAdjustmentIds) {
        if (globalLastKnownState.containsKey(id)) {
          setup.previousBikeAdjustmentValues[id] = globalLastKnownState[id];
        }
      }
      
      setup.previousPersonAdjustmentValues = {};
      for (final id in personAdjustmentIds) {
        if (globalLastKnownState.containsKey(id)) {
          setup.previousPersonAdjustmentValues[id] = globalLastKnownState[id];
        }
      }

      // 3.4. Update global state with bike and person values from this setup.
      // This populates previousPersonAdjustmentValues for history display in the list card.
      // SetupPage uses resolveHistoricalStateAt (bike-only) for pre-population, so person
      // fields stay blank when adding a new setup.
      globalLastKnownState.addAll(setup.bikeAdjustmentValues);
      globalLastKnownState.addAll(setup.personAdjustmentValues);
    }

    return (setups: sortedSetups, globalState: globalLastKnownState);
  }

  /// Calculates which tags to show in the global filter list based on all resolved setups.
  static Set<String> extractAllTags(Iterable<Setup> setups) {
    return setups.map((s) => s.tags).expand((tags) => tags).toSet();
  }

  /// Resolves the cumulative global state (bike and person adjustments) up to a given [datetime].
  /// This handles component transfers across different bikes by performing a full chronological pass.
  static Map<String, dynamic> resolveHistoricalStateAt({
    required DateTime datetime,
    required Iterable<Setup> setups,
    required Map<String, Person> persons,
    String? excludedSetupId,
  }) {
    final Map<String, dynamic> globalState = {};
    
    // 1. Sort setups chronologically up to the target datetime
    // Note: We use .toList() to ensure we don't accidentally mutate the underlying collection if it were mutable.
    final sortedSetups = setups
        .where((s) => s.id != excludedSetupId && s.datetime.isBefore(datetime))
        .sortedBy((s) => s.datetime);

    for (final setup in sortedSetups) {
      globalState.addAll(setup.bikeAdjustmentValues);
      globalState.addAll(setup.personAdjustmentValues);
    }

    return globalState;
  }

  /// Like [resolveHistoricalStateAt], but also reports *which* setup last
  /// changed each value.
  ///
  /// Setups carry pre-filled values forward unchanged, so a repeated value is
  /// not a modification: a value keeps pointing at the earlier setup that
  /// introduced it until a setup records a different one. Different adjustments
  /// therefore commonly resolve to different setups.
  static Map<String, AdjustmentProvenance> resolveHistoricalProvenanceAt({
    required DateTime datetime,
    required Iterable<Setup> setups,
    String? excludedSetupId,
  }) {
    const equality = DeepCollectionEquality();
    final Map<String, AdjustmentProvenance> provenance = {};

    final sortedSetups = setups
        .where((s) => s.id != excludedSetupId && s.datetime.isBefore(datetime))
        .sortedBy((s) => s.datetime);

    for (final setup in sortedSetups) {
      for (final entry in {...setup.bikeAdjustmentValues, ...setup.personAdjustmentValues}.entries) {
        final known = provenance[entry.key];
        if (known != null && equality.equals(known.value, entry.value)) continue;
        provenance[entry.key] = (value: entry.value, setup: setup);
      }
    }

    return provenance;
  }
}
