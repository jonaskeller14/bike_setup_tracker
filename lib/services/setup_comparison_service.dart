import 'package:flutter/foundation.dart';

import '../models/adjustment/adjustment.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/context/context_weather.dart';
import '../models/person.dart';
import '../models/setup.dart';
import '../models/setup_comparison.dart';
import 'dangling_adjustment_service.dart';

sealed class SetupComparisonTargetResolution {
  const SetupComparisonTargetResolution();
}

class SetupComparisonTargets extends SetupComparisonTargetResolution {
  final Setup setupA;
  final Setup setupB;

  const SetupComparisonTargets({required this.setupA, required this.setupB});
}

class SetupComparisonTargetsUnavailable extends SetupComparisonTargetResolution {
  const SetupComparisonTargetsUnavailable();
}

class SetupComparisonTargetsEqualInput extends SetupComparisonTargetResolution {
  const SetupComparisonTargetsEqualInput();
}

class SetupComparisonService {
  static SetupComparisonTargetResolution resolveTargets({
    Setup? setupA,
    required Setup setupB,
    required Iterable<Setup> setups,
  }) {
    if (setupA != null) {
      return setupA.id == setupB.id
          ? const SetupComparisonTargetsEqualInput()
          : SetupComparisonTargets(setupA: setupA, setupB: setupB);
    }

    for (final candidate in setups) {
      if (candidate.id != setupB.id && candidate.bike == setupB.bike && candidate.isCurrent) {
        return SetupComparisonTargets(setupA: candidate, setupB: setupB);
      }
    }
    return const SetupComparisonTargetsUnavailable();
  }

  static SetupComparison build({
    required Setup setupA,
    required Setup setupB,
    Iterable<Bike> bikes = const [],
    required Iterable<Component> components,
    required Iterable<Person> persons,
    bool includePerson = false,
    bool includeTags = false,
    bool includeImages = false,
    bool includeContext = false,
  }) {
    final allComponents = List<Component>.of(components);
    final allPersons = List<Person>.of(persons);
    final breakdownA = DanglingAdjustmentService.analyzeSetup(
      setup: setupA,
      components: allComponents,
      persons: allPersons,
    );
    final breakdownB = DanglingAdjustmentService.analyzeSetup(
      setup: setupB,
      components: allComponents,
      persons: allPersons,
    );

    final componentOwnersA = _componentOwners(breakdownA, setupA);
    final componentOwnersB = _componentOwners(breakdownB, setupB);
    final personOwnersA = _personOwners(breakdownA, setupA);
    final personOwnersB = _personOwners(breakdownB, setupB);

    return SetupComparison(
      setupAId: setupA.id,
      setupBId: setupB.id,
      groups: [
        if (includeContext)
          _buildContextGroup(
            setupA: setupA,
            setupB: setupB,
            bikes: bikes,
            persons: allPersons,
            includePerson: includePerson,
            includeTags: includeTags,
            includeImages: includeImages,
          ),
        ..._buildOwnerGroups(
          kind: SetupComparisonGroupKind.component,
          ownersA: componentOwnersA,
          ownersB: componentOwnersB,
        ),
        ..._buildOwnerGroups(
          kind: SetupComparisonGroupKind.person,
          ownersA: personOwnersA,
          ownersB: personOwnersB,
        ),
        _buildDeletedGroup(
          breakdownA: breakdownA,
          breakdownB: breakdownB,
        ),
      ].whereType<SetupComparisonGroup>(),
    );
  }

  static SetupComparisonGroup _buildContextGroup({
    required Setup setupA,
    required Setup setupB,
    required Iterable<Bike> bikes,
    required Iterable<Person> persons,
    required bool includePerson,
    required bool includeTags,
    required bool includeImages,
  }) {
    final bikesById = {for (final bike in bikes) bike.id: bike};
    final peopleById = {for (final person in persons) person.id: person};
    final bikeA = _reference(setupA.bike, bikesById, missingLabel: 'BIKE NOT FOUND', label: (bike) => bike.name);
    final bikeB = _reference(setupB.bike, bikesById, missingLabel: 'BIKE NOT FOUND', label: (bike) => bike.name);
    final rows = <SetupComparisonRow>[
      _contextRow(
        id: 'bike',
        label: 'Bike',
        kind: SetupComparisonRowKind.bike,
        valueA: bikeA,
        valueB: bikeB,
        differs: bikeA.id != bikeB.id || bikeA.isMissing != bikeB.isMissing,
      ),
      if (includePerson && (setupA.person != null || setupB.person != null))
        _personContextRow(setupA.person, setupB.person, peopleById),
      _contextRow(
        id: 'notes',
        label: 'Notes',
        kind: SetupComparisonRowKind.notes,
        valueA: setupA.notes,
        valueB: setupB.notes,
        differs: setupA.notes != setupB.notes,
      ),
      if (includeTags)
        _contextRow(
          id: 'tags',
          label: 'Tags',
          kind: SetupComparisonRowKind.tags,
          valueA: setupA.tags.toList()..sort(),
          valueB: setupB.tags.toList()..sort(),
          differs: !setEquals(setupA.tags, setupB.tags),
        ),
      if (includeImages)
        _contextRow(
          id: 'images',
          label: 'Images',
          kind: SetupComparisonRowKind.images,
          valueA: List<String>.of(setupA.images),
          valueB: List<String>.of(setupB.images),
          differs: !listEquals(setupA.images, setupB.images),
        ),
      _contextDisclosure(
        id: 'location',
        label: 'Location',
        kind: SetupComparisonRowKind.location,
        headerA: _address(setupA),
        headerB: _address(setupB),
        children: [
          _contextRow(
            id: 'address',
            label: 'Address',
            kind: SetupComparisonRowKind.context,
            valueA: _address(setupA),
            valueB: _address(setupB),
            differs: _address(setupA) != _address(setupB),
          ),
          _contextRow(
            id: 'coordinates',
            label: 'Latitude/Longitude',
            kind: SetupComparisonRowKind.context,
            valueA: (setupA.position?.latitude, setupA.position?.longitude),
            valueB: (setupB.position?.latitude, setupB.position?.longitude),
            differs:
                setupA.position?.latitude != setupB.position?.latitude ||
                setupA.position?.longitude != setupB.position?.longitude,
          ),
          _contextRow(
            id: 'altitude',
            label: 'Altitude',
            kind: SetupComparisonRowKind.context,
            valueA: setupA.position?.altitude,
            valueB: setupB.position?.altitude,
            differs: setupA.position?.altitude != setupB.position?.altitude,
          ),
        ],
      ),
      _contextDisclosure(
        id: 'conditions',
        label: 'Conditions',
        kind: SetupComparisonRowKind.conditions,
        headerA: setupA.weather?.getWeatherCodeLabel(),
        headerB: setupB.weather?.getWeatherCodeLabel(),
        children: [
          _weatherRow('weather-code', 'Weather', setupA, setupB, (weather) => weather?.getWeatherCodeLabel()),
          _weatherRow('condition', 'Condition', setupA, setupB, (weather) => weather?.condition?.value),
          _weatherRow('temperature', 'Temperature', setupA, setupB, (weather) => weather?.currentTemperature),
          _weatherRow(
            'precipitation',
            'Precipitation',
            setupA,
            setupB,
            (weather) => weather?.dayAccumulatedPrecipitation,
          ),
          _weatherRow('humidity', 'Humidity', setupA, setupB, (weather) => weather?.currentHumidity),
          _weatherRow('wind', 'Windspeed', setupA, setupB, (weather) => weather?.currentWindSpeed),
          _weatherRow(
            'soil-moisture',
            'Soil Moisture',
            setupA,
            setupB,
            (weather) => weather?.currentSoilMoisture0to7cm,
          ),
        ],
      ),
    ];
    return SetupComparisonGroup(
      kind: SetupComparisonGroupKind.context,
      ownerId: 'context',
      ownerStateA: SetupComparisonOwnerState.installedOrLinked,
      ownerStateB: SetupComparisonOwnerState.installedOrLinked,
      label: 'Context',
      rows: rows,
    );
  }

  static SetupComparisonRow _personContextRow(
    String? idA,
    String? idB,
    Map<String, Person> persons,
  ) {
    final valueA = idA == null
        ? null
        : _reference(idA, persons, missingLabel: 'Person not found', label: (person) => person.name);
    final valueB = idB == null
        ? null
        : _reference(idB, persons, missingLabel: 'Person not found', label: (person) => person.name);
    return _contextRow(
      id: 'person',
      label: 'Person',
      kind: SetupComparisonRowKind.person,
      valueA: valueA,
      valueB: valueB,
      differs: idA != idB || (valueA?.isMissing ?? false) != (valueB?.isMissing ?? false),
    );
  }

  static SetupComparisonReference _reference<T>(
    String id,
    Map<String, T> values, {
    required String missingLabel,
    required String Function(T value) label,
  }) {
    final value = values[id];
    return SetupComparisonReference(
      id: id,
      label: value == null ? missingLabel : label(value),
      isMissing: value == null,
    );
  }

  static SetupComparisonRow _contextRow({
    required String id,
    required String label,
    required SetupComparisonRowKind kind,
    required dynamic valueA,
    required dynamic valueB,
    required bool differs,
  }) => SetupComparisonRow(
    id: id,
    label: label,
    kind: kind,
    valueA: _contextValue(valueA),
    valueB: _contextValue(valueB),
    isDifferent: differs,
  );

  static SetupComparisonRow _contextDisclosure({
    required String id,
    required String label,
    required SetupComparisonRowKind kind,
    required List<SetupComparisonRow> children,
    required dynamic headerA,
    required dynamic headerB,
  }) => SetupComparisonRow(
    id: id,
    label: label,
    kind: kind,
    valueA: _contextValue(headerA),
    valueB: _contextValue(headerB),
    isDifferent: children.any((row) => row.isDifferent),
    children: children,
  );

  static SetupComparisonRow _weatherRow(
    String id,
    String label,
    Setup setupA,
    Setup setupB,
    dynamic Function(ContextWeather? weather) read,
  ) => _contextRow(
    id: id,
    label: label,
    kind: SetupComparisonRowKind.context,
    valueA: read(setupA.weather),
    valueB: read(setupB.weather),
    differs: read(setupA.weather) != read(setupB.weather),
  );

  static String? _address(Setup setup) {
    final place = setup.place;
    if (place == null) return null;
    return '${place.thoroughfare ?? ''} ${place.subThoroughfare ?? ''}, ${place.locality ?? ''}, ${place.isoCountryCode ?? ''}'
        .replaceAll(RegExp(r' ,'), '')
        .trim();
  }

  static SetupComparisonSideValue _contextValue(dynamic value) => SetupComparisonSideValue(
    value: value,
    provenance: value == null ? SetupComparisonValueProvenance.unavailable : SetupComparisonValueProvenance.explicit,
    definition: null,
  );

  static List<_OwnerData> _componentOwners(SetupAdjustmentBreakdown breakdown, Setup setup) {
    return [
      for (final component in breakdown.components)
        _OwnerData.component(
          component: component,
          state: SetupComparisonOwnerState.installedOrLinked,
          currentValues: setup.bikeAdjustmentValues,
          previousValues: setup.previousBikeAdjustmentValues,
        ),
      for (final group in breakdown.componentSplit.groups)
        _OwnerData.component(
          component: group.component,
          state: SetupComparisonOwnerState.dangling,
          adjustments: group.adjustments,
          currentValues: setup.bikeAdjustmentValues,
          previousValues: const {},
        ),
    ];
  }

  static List<_OwnerData> _personOwners(SetupAdjustmentBreakdown breakdown, Setup setup) {
    return [
      if (breakdown.person != null)
        _OwnerData.person(
          person: breakdown.person!,
          state: SetupComparisonOwnerState.installedOrLinked,
          currentValues: setup.personAdjustmentValues,
          previousValues: setup.previousPersonAdjustmentValues,
        ),
      for (final group in breakdown.personSplit.groups)
        _OwnerData.person(
          person: group.person,
          state: SetupComparisonOwnerState.dangling,
          adjustments: group.adjustments,
          currentValues: setup.personAdjustmentValues,
          previousValues: const {},
        ),
    ];
  }

  static List<SetupComparisonGroup> _buildOwnerGroups({
    required SetupComparisonGroupKind kind,
    required List<_OwnerData> ownersA,
    required List<_OwnerData> ownersB,
  }) {
    final byIdA = _byOwnerId(ownersA);
    final byIdB = _byOwnerId(ownersB);
    final orderedIds = _orderedUnion(byIdA.keys, byIdB.keys);

    return [
      for (final id in orderedIds) _buildOwnerGroup(kind: kind, ownerA: byIdA[id], ownerB: byIdB[id]),
    ];
  }

  static Map<String, _OwnerData> _byOwnerId(Iterable<_OwnerData> owners) {
    final result = <String, _OwnerData>{};
    for (final owner in owners) {
      result.putIfAbsent(owner.id, () => owner);
    }
    return result;
  }

  static SetupComparisonGroup _buildOwnerGroup({
    required SetupComparisonGroupKind kind,
    required _OwnerData? ownerA,
    required _OwnerData? ownerB,
  }) {
    final adjustmentA = _byAdjustmentId(ownerA?.adjustments ?? const []);
    final adjustmentB = _byAdjustmentId(ownerB?.adjustments ?? const []);
    final adjustmentIds = _orderedUnion(adjustmentA.keys, adjustmentB.keys);
    final stateA = ownerA?.state ?? SetupComparisonOwnerState.absent;
    final stateB = ownerB?.state ?? SetupComparisonOwnerState.absent;

    return SetupComparisonGroup(
      kind: kind,
      ownerId: ownerA?.id ?? ownerB!.id,
      ownerStateA: stateA,
      ownerStateB: stateB,
      label: ownerA?.label ?? ownerB!.label,
      labelA: ownerA?.label,
      labelB: ownerB?.label,
      componentA: ownerA?.component,
      componentB: ownerB?.component,
      personA: ownerA?.person,
      personB: ownerB?.person,
      rows: [
        for (final id in adjustmentIds)
          _buildAdjustmentRow(
            id: id,
            adjustmentA: adjustmentA[id],
            adjustmentB: adjustmentB[id],
            ownerA: ownerA,
            ownerB: ownerB,
            ownerStateA: stateA,
            ownerStateB: stateB,
          ),
      ],
    );
  }

  static Map<String, Adjustment> _byAdjustmentId(Iterable<Adjustment> adjustments) {
    final result = <String, Adjustment>{};
    for (final adjustment in adjustments) {
      result.putIfAbsent(adjustment.id, () => adjustment);
    }
    return result;
  }

  static SetupComparisonRow _buildAdjustmentRow({
    required String id,
    required Adjustment? adjustmentA,
    required Adjustment? adjustmentB,
    required _OwnerData? ownerA,
    required _OwnerData? ownerB,
    required SetupComparisonOwnerState ownerStateA,
    required SetupComparisonOwnerState ownerStateB,
  }) {
    final valueA = _resolveValue(ownerA, adjustmentA);
    final valueB = _resolveValue(ownerB, adjustmentB);
    return SetupComparisonRow(
      id: id,
      label: adjustmentA?.name ?? adjustmentB!.name,
      kind: SetupComparisonRowKind.adjustment,
      valueA: valueA,
      valueB: valueB,
      isDifferent: _valuesDiffer(
        valueA: valueA,
        valueB: valueB,
        ownerStateA: ownerStateA,
        ownerStateB: ownerStateB,
      ),
    );
  }

  static SetupComparisonSideValue _resolveValue(_OwnerData? owner, Adjustment? adjustment) {
    if (owner == null || adjustment == null) {
      return SetupComparisonSideValue(
        value: null,
        provenance: SetupComparisonValueProvenance.unavailable,
        definition: adjustment,
      );
    }
    if (owner.state == SetupComparisonOwnerState.dangling) {
      return SetupComparisonSideValue(
        value: owner.currentValues[adjustment.id],
        provenance: SetupComparisonValueProvenance.dangling,
        definition: adjustment,
      );
    }
    if (owner.currentValues.containsKey(adjustment.id)) {
      return SetupComparisonSideValue(
        value: owner.currentValues[adjustment.id],
        provenance: SetupComparisonValueProvenance.explicit,
        definition: adjustment,
      );
    }
    if (owner.previousValues.containsKey(adjustment.id)) {
      return SetupComparisonSideValue(
        value: owner.previousValues[adjustment.id],
        provenance: SetupComparisonValueProvenance.inherited,
        definition: adjustment,
      );
    }
    return SetupComparisonSideValue(
      value: null,
      provenance: SetupComparisonValueProvenance.unavailable,
      definition: adjustment,
    );
  }

  static bool _valuesDiffer({
    required SetupComparisonSideValue valueA,
    required SetupComparisonSideValue valueB,
    required SetupComparisonOwnerState ownerStateA,
    required SetupComparisonOwnerState ownerStateB,
  }) {
    if (ownerStateA != ownerStateB || valueA.definition == null || valueB.definition == null) {
      return true;
    }
    if (valueA.provenance == SetupComparisonValueProvenance.deleted ||
        valueB.provenance == SetupComparisonValueProvenance.deleted) {
      return true;
    }
    final unavailableA = valueA.provenance == SetupComparisonValueProvenance.unavailable;
    final unavailableB = valueB.provenance == SetupComparisonValueProvenance.unavailable;
    if (unavailableA != unavailableB) return true;
    if (unavailableA) return false;
    return !adjustmentValuesEqual(valueA.value, valueB.value);
  }

  static SetupComparisonGroup? _buildDeletedGroup({
    required SetupAdjustmentBreakdown breakdownA,
    required SetupAdjustmentBreakdown breakdownB,
  }) {
    final valuesA = _deletedValues(breakdownA);
    final valuesB = _deletedValues(breakdownB);
    if (valuesA.isEmpty && valuesB.isEmpty) return null;
    final ids = _orderedUnion(valuesA.keys, valuesB.keys);
    return SetupComparisonGroup(
      kind: SetupComparisonGroupKind.deletedValues,
      ownerId: 'deleted-values',
      ownerStateA: valuesA.isEmpty ? SetupComparisonOwnerState.absent : SetupComparisonOwnerState.dangling,
      ownerStateB: valuesB.isEmpty ? SetupComparisonOwnerState.absent : SetupComparisonOwnerState.dangling,
      label: 'Deleted adjustments',
      rows: [
        for (final id in ids)
          SetupComparisonRow(
            id: id,
            label: id,
            kind: SetupComparisonRowKind.deletedAdjustment,
            valueA: _deletedValue(valuesA, id),
            valueB: _deletedValue(valuesB, id),
            isDifferent: true,
          ),
      ],
    );
  }

  static Map<String, dynamic> _deletedValues(SetupAdjustmentBreakdown breakdown) {
    return {
      ...breakdown.componentSplit.deletedValues,
      ...breakdown.personSplit.deletedValues,
    };
  }

  static SetupComparisonSideValue _deletedValue(Map<String, dynamic> values, String id) {
    if (!values.containsKey(id)) {
      return const SetupComparisonSideValue(
        value: null,
        provenance: SetupComparisonValueProvenance.unavailable,
        definition: null,
      );
    }
    return SetupComparisonSideValue(
      value: values[id],
      provenance: SetupComparisonValueProvenance.deleted,
      definition: null,
    );
  }

  static List<String> _orderedUnion(Iterable<String> a, Iterable<String> b) {
    final result = <String>[];
    final seen = <String>{};
    for (final id in [...a, ...b]) {
      if (seen.add(id)) result.add(id);
    }
    return result;
  }
}

class _OwnerData {
  final String id;
  final String label;
  final SetupComparisonOwnerState state;
  final List<Adjustment> adjustments;
  final Map<String, dynamic> currentValues;
  final Map<String, dynamic> previousValues;
  final Component? component;
  final Person? person;

  _OwnerData.component({
    required Component component,
    required this.state,
    List<Adjustment>? adjustments,
    required this.currentValues,
    required this.previousValues,
  }) : id = component.id,
       label = component.name,
       adjustments = adjustments ?? component.adjustments,
       component = component,
       person = null;

  _OwnerData.person({
    required Person person,
    required this.state,
    List<Adjustment>? adjustments,
    required this.currentValues,
    required this.previousValues,
  }) : id = person.id,
       label = person.name,
       adjustments = adjustments ?? person.adjustments,
       component = null,
       person = person;
}
