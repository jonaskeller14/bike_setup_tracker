import '../models/adjustment/adjustment.dart';
import '../models/bike.dart';
import '../models/person.dart';
import '../models/setup.dart';
import 'package:collection/collection.dart';
import '../utils/file_import.dart';

class SetupResolutionService {
  /// Sorts setups chronologically and calculates inherited adjustment values.
  static Map<String, Setup> resolveSetups({
    required Map<String, Setup> setups,
    required Map<String, Bike> bikes,
    required Map<String, Person> persons,
  }) {
    // 1. Sort setups chronologically
    final sortedSetupEntries = setups.entries.toList();
    sortedSetupEntries.sort((a, b) => a.value.datetime.compareTo(b.value.datetime));
    final sortedSetups = Map.fromEntries(sortedSetupEntries);
    
    // 2. Determine Current/Previous status
    FileImport.determineCurrentSetups(setups: sortedSetups.values.toList(), bikes: bikes);
    FileImport.determinePreviousSetups(setups: sortedSetups.values);
    
    // 3. Propagate values forward through time
    for (final setup in sortedSetups.values) {
      _updateSetupsAfter(
        setup: setup,
        setupsList: sortedSetups.values.toList(),
        persons: persons,
      );
    }

    return sortedSetups;
  }

  /// Calculates which tags to show in the global filter list based on all resolved setups.
  static Set<String> extractAllTags(Iterable<Setup> setups) {
    return setups.map((s) => s.tags).expand((tags) => tags).toSet();
  }

  static void _updateSetupsAfter({
    required Setup setup,
    required List<Setup> setupsList,
    required Map<String, Person> persons,
  }) {
    final index = setupsList.indexOf(setup);
    if (index == -1 || index == setupsList.length - 1) return;
    
    final afterSetups = setupsList.sublist(index + 1);
    
    // Propagate Bike Adjustments
    final afterBikeSetups = afterSetups.where((s) => s.bike == setup.bike);
    for (final adjustmentValue in setup.bikeAdjustmentValues.entries) {
      final adjustment = adjustmentValue.key;
      final value = adjustmentValue.value;
      for (final afterBikeSetup in afterBikeSetups) {
        if (afterBikeSetup.bikeAdjustmentValues.containsKey(adjustment)) continue;
        afterBikeSetup.bikeAdjustmentValues[adjustment] = value;
      }
    }

    // Propagate Person Adjustments
    final person = persons[setup.person];
    if (person != null) {
      final afterPersonSetups = afterSetups.where((s) => s.person != null && s.person == setup.person);
      for (final adjustmentValue in setup.personAdjustmentValues.entries) {
        final adjustmentId = adjustmentValue.key;
        final Adjustment? adjustment = person.adjustments.firstWhereOrNull((a) => a.id == adjustmentId);
        
        // Do not propagate transient adjustments like nutrition/equipment
        if (adjustment?.category == AdjustmentCategory.nutrition || 
            adjustment?.category == AdjustmentCategory.equipment) {
          continue;
        }
            
        final value = adjustmentValue.value;
        for (final afterPersonSetup in afterPersonSetups) {
          if (afterPersonSetup.personAdjustmentValues.containsKey(adjustmentId)) continue;
          afterPersonSetup.personAdjustmentValues[adjustmentId] = value;
        }
      }
    }
  }
}
